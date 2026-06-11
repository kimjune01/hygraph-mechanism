#!/usr/bin/env bash
# Verus #2427 oracle grader. Usage: grade.sh <verus-source-dir>
set -uo pipefail
SRC="${1:?usage: grade.sh <verus/source>}"
VB="$SRC/target-verus/release/verus"
ORACLE="$(cd "$(dirname "$0")" && pwd)"
for t in t1_closure t2_toplevel t3_unsound; do
  out=$(env -u RUSTC -u RUSTUP_TOOLCHAIN PATH="/tmp/rustup-shims:$PATH" "$VB" "$ORACLE/$t.rs" 2>&1)
  if echo "$out" | grep -qE '0 errors'; then v=VERIFY
  elif echo "$out" | grep -qiE '[1-9][0-9]* error|error:'; then v="FAIL($(echo "$out"|grep -oE '[0-9]+ errors'|head -1))"
  else v="?? $(echo "$out"|tail -1)"; fi
  printf "  %-16s -> %s\n" "$t" "$v"
done
