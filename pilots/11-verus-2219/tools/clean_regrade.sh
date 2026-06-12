#!/usr/bin/env bash
# Clean, verifiable re-grade harness for verus #2219.
# For each artifact (a patch-on-base file, or "BASE", or "COMMIT:<sha>"):
#   reset->base, clean vendored dirs, apply, FORCE-FRESH build (touch sources -> vargo build),
#   verify binary rebuilt (mtime > build-start), grade battery + case-check, emit one JSON line with provenance.
# Usage: clean_regrade.sh OUT.jsonl ARTIFACT [ARTIFACT ...]
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
CC=/tmp/case-check
BASE=23dc6e754fef0d238db808dad02cbe8e3d72f2b3
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"; unset RUSTC RUSTUP_TOOLCHAIN
OUT="${1:?usage: OUT.jsonl ARTIFACT... | OUT.jsonl @listfile}"; shift
# robust list: if first arg is @file, read artifacts (one per line/whitespace) from it
if [ -n "${1:-}" ] && [ "${1#@}" != "$1" ]; then set -- $(cat "${1#@}"); fi
BIN="$WT/source/target-verus/release/verus"
DRIVER="$WT/source/target-verus/release/rust_verify"   # the REAL driver (verus is a stable launcher)
cd "$WT"
toolchain=$(awk -F'"' '/channel/{print $2}' "$WT/rust-toolchain.toml")

grade_one(){ local out
  out=$(cd "$WT/source" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH "$BIN" --crate-type=lib "$1" 2>&1)
  if echo "$out"|grep -qE 'verified, 0 errors'; then echo VERIFY
  elif echo "$out"|grep -qiE 'errors|error\[|moved value|error:'; then echo REJECT; else echo OTHER; fi; }

for ART in "$@"; do
  echo "[$(date +%H:%M:%S)] === artifact: $ART ===" >&2
  git checkout -- . >/dev/null 2>&1; git clean -fdq source/rust_verify source/rustc_mir_build source/rustc_mir_build_additional_files >/dev/null 2>&1
  git checkout --detach "$BASE" >/dev/null 2>&1
  psha="-"; plines=0; aid="$ART"; applied=ok
  if [ "$ART" = BASE ]; then aid=BASE
  elif [[ "$ART" == COMMIT:* ]]; then git checkout --detach "${ART#COMMIT:}" >/dev/null 2>&1 || applied=checkout-fail; aid="${ART}"
  else
    P="$PILOT/$ART"; [ -f "$P" ] || P="$ART"
    psha=$(shasum -a 256 "$P" 2>/dev/null | cut -c1-16); plines=$(wc -l <"$P" 2>/dev/null|tr -d ' ')
    if [ "$plines" -eq 0 ]; then applied=empty-patch; else
      git apply --check "$P" 2>/dev/null && git apply "$P" 2>/dev/null && applied=ok || applied=APPLY-FAIL; fi
  fi
  start=$(date +%s)
  find source/rustc_mir_build/src source/rust_verify/src -name '*.rs' -exec touch {} + 2>/dev/null
  ( cd "$WT/source" && vargo build --release ) >/tmp/cr-build.log 2>&1; bexit=$?
  bmtime=$(stat -f %m "$DRIVER" 2>/dev/null || echo 0); rebuilt=$([ "$bmtime" -ge "$start" ] && echo true || echo false)
  binfp=$(shasum -a 256 "$DRIVER" 2>/dev/null | cut -c1-16)   # content fingerprint = true identity
  if [ $bexit -ne 0 ]; then
    printf '{"artifact":"%s","patch_sha":"%s","patch_lines":%s,"toolchain":"%s","applied":"%s","build_exit":%s,"rebuilt":%s,"bin_fp":"%s","battery":null,"casecheck":null}\n' \
      "$aid" "$psha" "$plines" "$toolchain" "$applied" "$bexit" "$rebuilt" "$binfp" >> "$OUT"; continue; fi
  t1=$(grade_one "$PILOT/oracle/t1_issue2219.rs"); t2=$(grade_one "$PILOT/oracle/t2_empty_enum.rs"); t3=$(grade_one "$PILOT/oracle/t3_legit_divergence.rs")
  ha=$(grade_one "$PILOT/heldout2/h2_assoc_proj.rs"); hn=$(grade_one "$PILOT/heldout2/h2_generic_nested.rs"); ho=$(grade_one "$PILOT/heldout/ho5_real_divergence_sound.rs")
  cc=$(cd "$CC" && python3 case-check.py --candidate-verus "$BIN" --jobs 8 2>/dev/null | grep -oE 'pass=(true|false)|changed=[0-9]+|mishandles=[0-9]+|valid-preserve-rejected=[0-9]+|valid-bug-still-accepted=[0-9]+|crash=[0-9]+|changed-outside-bugset=[0-9]+' | tr '\n' ' ')
  ccpass=$(echo "$cc"|grep -oE 'pass=(true|false)'|cut -d= -f2); ccchg=$(echo "$cc"|grep -oE 'changed=[0-9]+'|cut -d= -f2)
  ccmis=$(echo "$cc"|grep -oE 'mishandles=[0-9]+'|cut -d= -f2); ccpr=$(echo "$cc"|grep -oE 'valid-preserve-rejected=[0-9]+'|cut -d= -f2)
  ccva=$(echo "$cc"|grep -oE 'valid-bug-still-accepted=[0-9]+'|cut -d= -f2); ccoob=$(echo "$cc"|grep -oE 'changed-outside-bugset=[0-9]+'|cut -d= -f2)
  cccrash=$(echo "$cc"|grep -oE 'crash=[0-9]+'|cut -d= -f2)
  printf '{"artifact":"%s","patch_sha":"%s","patch_lines":%s,"toolchain":"%s","applied":"%s","build_exit":0,"rebuilt":%s,"bin_mtime":%s,"bin_fp":"%s","battery":{"t1":"%s","t2":"%s","t3":"%s","h2_assoc":"%s","h2_nested":"%s","ho5":"%s"},"casecheck":{"pass":"%s","changed":%s,"mishandles":%s,"valid_bug_still_accepted":%s,"valid_preserve_rejected":%s,"changed_outside_bugset":%s,"crash":%s}}\n' \
    "$aid" "$psha" "$plines" "$toolchain" "$applied" "$rebuilt" "$bmtime" "$binfp" "$t1" "$t2" "$t3" "$ha" "$hn" "$ho" "${ccpass:-NA}" "${ccchg:-0}" "${ccmis:-0}" "${ccva:-0}" "${ccpr:-0}" "${ccoob:-0}" "${cccrash:-0}" >> "$OUT"
  echo "[$(date +%H:%M:%S)] $aid: T=$t1/$t2/$t3 h2=$ha/$hn ho5=$ho cc:pass=$ccpass chg=$ccchg" >&2
done
# leave worktree clean at base
git checkout -- . >/dev/null 2>&1; git checkout --detach "$BASE" >/dev/null 2>&1
echo "[$(date +%H:%M:%S)] ALL DONE -> $OUT" >&2
