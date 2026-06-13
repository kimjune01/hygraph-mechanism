#!/usr/bin/env bash
# Corrected gate: forced-fresh rebuild, then PASS iff case-check passes AND no valid program is over-rejected.
# (case-check = the enumerated bug/preserve grammar; gate2/preserve = additional human-approved valid programs.)
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PRESERVE=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219/gate2/preserve
CC="$(cd "$(dirname "$0")/../tools" && pwd)"   # pilot tools dir (case-check.py + calibration.json), relative to this script
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"; unset RUSTC RUSTUP_TOOLCHAIN
# forced-fresh rebuild (vendored crate doesn't rebuild on plain incremental)
find "$WT"/source/rustc_mir_build/src "$WT"/source/rust_verify/src -name '*.rs' -exec touch {} + 2>/dev/null
( cd "$WT/source" && vargo build --release ) >/tmp/gate2-build.log 2>&1 || { echo "GATE pass=false reason=BUILD_FAILED"; tail -3 /tmp/gate2-build.log; exit 0; }
BIN="$WT/source/target-verus/release/verus"
cc=$(cd "$CC" && python3.13 case-check.py --candidate-verus "$BIN" --calibration "$CC/calibration.json" --jobs 8 2>/dev/null | grep -oE 'pass=(true|false)|mishandles=[0-9]+|valid-bug-still-accepted=[0-9]+|valid-preserve-rejected=[0-9]+|crash=[0-9]+')
ccpass=$(echo "$cc" | grep -oE 'pass=(true|false)' | cut -d= -f2)
overrej=""
for f in "$PRESERVE"/*.rs; do
  out=$(cd "$WT/source" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH "$BIN" --crate-type=lib "$f" 2>&1)
  echo "$out" | grep -qE 'verified, 0 errors' || overrej="$overrej $(basename "$f" .rs)"
done
if [ "$ccpass" = true ] && [ -z "$overrej" ]; then
  echo "GATE pass=true"
else
  echo "GATE pass=false"
  echo "  case-check: $cc"
  [ -n "$overrej" ] && echo "  valid-programs-over-rejected:$overrej  (these are SOUND and must keep verifying)"
fi

exit 0
