#!/usr/bin/env bash
# Battery grader: run every candidate program through a given flux worktree.
# Usage: grade_all.sh <worktree-dir> [label]
set -uo pipefail
WT="${1:?usage: grade_all.sh <worktree> [label]}"
LABEL="${2:-$WT}"
ORACLE="$(cd "$(dirname "$0")" && pwd)"
SHIMS=/tmp/rustup-shims

classify() {
  if echo "$1" | grep -qE 'error\[E0999\]|may not hold'; then echo "E0999"
  elif echo "$1" | grep -qiE 'error\[E[0-9]|error: |panicked'; then echo "OTHER_ERR"
  else echo "VERIFY"; fi
}

echo "### $LABEL  ($WT)"
for f in "$ORACLE"/t1_issue1613.rs "$ORACLE"/t2_receipt_int.rs "$ORACLE"/t3_unsound_twin.rs "$ORACLE"/battery/*.rs; do
  [ -f "$f" ] || continue
  out=$(cd "$WT" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH="$SHIMS:$PATH" cargo xtask run "$f" 2>&1)
  printf "  %-26s -> %s\n" "$(basename "$f")" "$(classify "$out")"
done
