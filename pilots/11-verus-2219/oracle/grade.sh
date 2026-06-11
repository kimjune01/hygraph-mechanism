#!/usr/bin/env bash
# Three-way oracle grader for verus #2219 (soundness: ghost-! CFG-pruning bypasses linearity check).
# Usage: grade.sh <verus-source-dir>   (dir containing target-verus/release/verus)
# REJECT = verus reports errors (>0). VERIFY = "N verified, 0 errors".
# Expected: base T1 VERIFY(bug)/T2 VERIFY(bug)/T3 VERIFY.  narrow#2230 T1 REJECT/T2 VERIFY/T3 VERIFY.
#           general#2501 T1 REJECT/T2 REJECT/T3 VERIFY.   DIVERGE(arm)=T1 REJECT/T2 REJECT/T3 VERIFY.
set -uo pipefail
SRC="${1:?usage: grade.sh <verus-source-dir>}"
ORACLE="$(cd "$(dirname "$0")" && pwd)"
BIN="$SRC/target-verus/release/verus"
grade_one() {
  local out
  out=$(cd "$SRC" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH \
        "$BIN" --crate-type=lib "$1" 2>&1)
  if echo "$out" | grep -qE 'verified, 0 errors'; then echo "VERIFY"
  elif echo "$out" | grep -qiE 'errors|error\[|moved value|error:'; then echo "REJECT"
  else echo "OTHER"; fi
}
for t in t1_issue2219 t2_empty_enum t3_legit_divergence; do
  printf "  %-20s -> %s\n" "$t" "$(grade_one "$ORACLE/$t.rs")"
done
