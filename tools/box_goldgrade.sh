#!/bin/bash
# box_goldgrade.sh -- run the $0 gold-grade wall (tools/gold_grade.sh) on an EC2 box.
# The repos do not fit locally (default-box). Provision one box per toolchain family,
# push gold_grade.sh + recipes, and red/green every recipe with gold_grade=="pending".
# A recipe that does not red-at-base/green-on-gold is KNOWN_BAD and never enters the ablation.
#
#   tools/box_goldgrade.sh provision <box>          # provision (reuse Pro provision_box.sh) + install git/uv/py + push tools
#   tools/box_goldgrade.sh grade <box> [repo-substr] # run gold_grade per pending recipe (filter by repo substring)
#   tools/box_goldgrade.sh teardown <box>
#
# Box env written by provision_box.sh at /tmp/<box>.env (KEY/PUBIP/IID/SG/REGION).
# Ledger: data/goldgrade.jsonl (one row per instance: repo,pr,verdict,log_tail).
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PROVISION="$HOME/Documents/swebench-pro/driver/provision_box.sh"
RECIPES="$HERE/data/recipes.jsonl"
LEDGER="$HERE/data/goldgrade.jsonl"
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"

box_env() { : "${1:?box name}"; . "/tmp/$1.env"; PEM="/tmp/${KEY}.pem"; }

case "${1:-}" in
  provision)
    BOX="${2:?usage: box_goldgrade.sh provision <box>}"
    EBS_GB="${EBS_GB:-100}" bash "$PROVISION" "$BOX"
    box_env "$BOX"
    echo "=== installing git/uv/python3.11 on $BOX ==="
    $SSH -i "$PEM" ec2-user@"$PUBIP" "
      set -e
      sudo dnf install -y -q git python3.11 python3.11-pip tar gzip >/dev/null 2>&1 || sudo yum install -y -q git python3 >/dev/null 2>&1
      command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
      mkdir -p ~/gg/tools
      echo INSTALLED \$(git --version) \$(python3.11 --version 2>/dev/null || python3 --version)
    "
    scp -o StrictHostKeyChecking=no -i "$PEM" "$HERE/tools/gold_grade.sh" ec2-user@"$PUBIP":~/gg/tools/gold_grade.sh >/dev/null
    scp -o StrictHostKeyChecking=no -i "$PEM" "$RECIPES" ec2-user@"$PUBIP":~/gg/recipes.jsonl >/dev/null
    $SSH -i "$PEM" ec2-user@"$PUBIP" "chmod +x ~/gg/tools/gold_grade.sh"
    echo "READY $BOX -- next: tools/box_goldgrade.sh grade $BOX"
    ;;
  grade)
    BOX="${2:?usage: box_goldgrade.sh grade <box> [repo-substr]}"; FILTER="${3:-}"
    box_env "$BOX"
    # refresh recipes + tool on box (both evolve as we iterate)
    scp -o StrictHostKeyChecking=no -i "$PEM" "$RECIPES" ec2-user@"$PUBIP":~/gg/recipes.jsonl >/dev/null
    scp -o StrictHostKeyChecking=no -i "$PEM" "$HERE/tools/gold_grade.sh" ec2-user@"$PUBIP":~/gg/tools/gold_grade.sh >/dev/null
    # emit pending recipes as TSV: repo<TAB>pr<TAB>merge<TAB>build<TAB>test
    python3 - "$RECIPES" "$FILTER" <<'PY' > /tmp/gg_pending.tsv
import sys, json
recs=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
filt=sys.argv[2]
for r in recs:
    if r.get("gold_grade")=="PASS": continue
    if filt and filt not in r["repo"]: continue
    print("\t".join([r["repo"], str(r["pr"]), r["merge_sha"], r["build_cmd"], r["test_cmd"]]))
PY
    [ -s /tmp/gg_pending.tsv ] || { echo "no pending recipes (filter='$FILTER')"; exit 0; }
    echo "=== grading $(wc -l < /tmp/gg_pending.tsv) instance(s) on $BOX ==="
    while IFS=$'\t' read -r repo pr merge build test; do
      url="https://github.com/${repo}.git"
      work="gg/work/$(echo "$repo" | tr '/' '_')"   # home-relative; ssh lands in ~
      echo "--- $repo#$pr ---"
      out=$($SSH -n -i "$PEM" ec2-user@"$PUBIP" "
        export PATH=\$HOME/.local/bin:\$PATH UV_VENV_CLEAR=1
        bash ~/gg/tools/gold_grade.sh '$url' '$merge' '$build' '$test' '$work' 2>&1 | tail -8
      ")
      echo "$out"
      verdict=$(echo "$out" | grep -oE 'GRADE: (PASS|FAIL|SKIP)' | head -1 | awk '{print $2}')
      python3 - "$LEDGER" "$repo" "$pr" "${verdict:-ERROR}" <<PY
import sys, json, os
ledger, repo, pr, verdict = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
rows=[]
if os.path.exists(ledger):
    rows=[json.loads(l) for l in open(ledger) if l.strip()]
rows=[r for r in rows if not (r["repo"]==repo and r["pr"]==pr)]
rows.append({"repo":repo,"pr":pr,"verdict":verdict})
open(ledger,"w").write("".join(json.dumps(r)+"\n" for r in rows))
PY
    done < /tmp/gg_pending.tsv
    echo "=== ledger: $LEDGER ==="; cat "$LEDGER"
    ;;
  teardown)
    BOX="${2:?usage: box_goldgrade.sh teardown <box>}"; box_env "$BOX"
    aws ec2 terminate-instances --instance-ids "$IID" --region "$REGION" >/dev/null 2>&1
    aws ec2 delete-security-group --group-id "$SG" --region "$REGION" 2>/dev/null
    aws ec2 delete-key-pair --key-name "$KEY" --region "$REGION" 2>/dev/null
    echo "terminated $BOX ($IID)"
    ;;
  *) echo "usage: box_goldgrade.sh {provision <box>|grade <box> [repo-substr]|teardown <box>}"; exit 1 ;;
esac
