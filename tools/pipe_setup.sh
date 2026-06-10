#!/bin/bash
# pipe_setup.sh -- set up the one-ablation pipeline scaffolding for an instance on a box.
# Builds two trees from the recipe and a run-handle check.sh (pilot-01 pattern):
#   ~/pipe/<n>_work   : base (merge^1), gold TEST files reverted -> the agent's tree (it never sees the test body)
#   ~/pipe/<n>_grade  : base + gold TEST files, committed & tagged `gradebase` -> the hidden oracle
#   ~/pipe/<n>_check.sh : diff agent SOURCE (test files excluded) -> apply onto gradebase -> run test_cmd -> PASS/FAIL
# Same machine as box_goldgrade.sh; reuses the recipe's build_cmd/test_cmd/test_files.
#
#   tools/pipe_setup.sh <box> <repo-substr>
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
RECIPES="$HERE/data/recipes.jsonl"
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"
BOX="${1:?usage: pipe_setup.sh <box> <repo-substr>}"; FILTER="${2:?repo substring}"
. "/tmp/$BOX.env"; PEM="/tmp/${KEY}.pem"

# pull the matching PASS recipe's fields as one TSV line
IFS=$'\t' read -r REPO PR MERGE BUILD TEST NAME EXCL TFILES < <(python3 - "$RECIPES" "$FILTER" <<'PY'
import sys, json
recs=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
r=[x for x in recs if sys.argv[2] in x["repo"] and x.get("gold_grade")=="PASS"][0]
name=r["repo"].replace("/","_")
excl=" ".join(f"':(exclude){t}'" for t in r["test_files"])
tfiles=" ".join(r["test_files"])
print("\t".join([r["repo"], str(r["pr"]), r["merge_sha"], r["build_cmd"], r["test_cmd"], name, excl, tfiles]))
PY
)
URL="https://github.com/${REPO}.git"
echo "=== setup $REPO#$PR on $BOX (work+grade+check) ==="

# generate check.sh locally, then scp
cat > /tmp/${NAME}_check.sh <<EOF
#!/bin/bash
# run-handle for ${REPO}#${PR}: score agent SOURCE against hidden gold test; PASS/FAIL only.
cd \$HOME/pipe/${NAME}_work && git diff HEAD -- . ${EXCL} > /tmp/${NAME}_src.patch 2>/dev/null
cd \$HOME/pipe/${NAME}_grade && git reset -q --hard gradebase
if [ -s /tmp/${NAME}_src.patch ]; then
  git apply /tmp/${NAME}_src.patch 2>/dev/null || { echo "CHECK: FAIL (patch did not apply)"; exit 1; }
fi
if ${TEST} >/tmp/${NAME}_check.log 2>&1; then
  echo "CHECK: PASS (\$(grep -oE '[0-9]+ (passed|ok)' /tmp/${NAME}_check.log | head -1))"
else
  echo "CHECK: FAIL (\$(grep -oE '[0-9]+ (failed|error|FAIL)' /tmp/${NAME}_check.log | head -1))"
fi
EOF
scp -o StrictHostKeyChecking=no -i "$PEM" /tmp/${NAME}_check.sh ec2-user@"$PUBIP":/tmp/${NAME}_check.sh >/dev/null

$SSH -i "$PEM" ec2-user@"$PUBIP" "
  set -e
  export PATH=\$HOME/.local/bin:\$PATH UV_VENV_CLEAR=1
  mkdir -p ~/pipe
  for tree in work grade; do
    d=~/pipe/${NAME}_\$tree
    [ -d \$d/.git ] || git clone -q '$URL' \$d
    cd \$d
    git reset -q --hard '${MERGE}^1' && git clean -qfdx -e .venv
  done
  # grade tree: apply gold TEST files, commit, tag gradebase
  cd ~/pipe/${NAME}_grade
  git checkout '${MERGE}' -- ${TFILES}
  git add -A && git -c user.email=a@b -c user.name=p commit -q -m testpatch && git tag -f gradebase
  # build both trees
  cd ~/pipe/${NAME}_work  && ( ${BUILD} ) >/tmp/${NAME}_work_build.log 2>&1  && echo WORK_BUILT  || { echo WORK_BUILD_FAIL; tail -3 /tmp/${NAME}_work_build.log; }
  cd ~/pipe/${NAME}_grade && ( ${BUILD} ) >/tmp/${NAME}_grade_build.log 2>&1 && echo GRADE_BUILT || { echo GRADE_BUILD_FAIL; tail -3 /tmp/${NAME}_grade_build.log; }
  chmod +x /tmp/${NAME}_check.sh
  # sanity: at base (no agent edits) the handle must FAIL (oracle discriminates)
  echo -n 'BASELINE '; bash /tmp/${NAME}_check.sh
"
echo "=== ready: work=~/pipe/${NAME}_work  grade=~/pipe/${NAME}_grade  handle=/tmp/${NAME}_check.sh ==="
