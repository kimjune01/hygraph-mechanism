#!/usr/bin/env bash
# Three-way oracle grader for the flux #1613 divergence replication.
# Usage: grade.sh <flux-worktree-dir>
# Runs each oracle program through that worktree's flux and classifies VERIFY/E0999.
# Expected (divergence): T1 VERIFY, T2 {minimal:E0999, graph:VERIFY}, T3 E0999.
set -uo pipefail
WT="${1:?usage: grade.sh <worktree>}"
ORACLE="$(cd "$(dirname "$0")" && pwd)"
SHIMS=/tmp/rustup-shims

grade_one() {
  local f="$1"
  local out
  out=$(cd "$WT" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH="$SHIMS:$PATH" \
        cargo xtask run "$f" 2>&1)
  if echo "$out" | grep -qE 'error\[E0999\]|may not hold|refinement type error'; then
    echo "E0999"
  elif echo "$out" | grep -qiE 'error\[E[0-9]|error: '; then
    echo "OTHER_ERR"
  else
    echo "VERIFY"
  fi
}

echo "grading worktree: $WT"
for t in t1_issue1613 t2_receipt_int t3_unsound_twin; do
  printf "  %-18s -> %s\n" "$t" "$(grade_one "$ORACLE/$t.rs")"
done
