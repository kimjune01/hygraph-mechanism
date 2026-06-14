#!/usr/bin/env bash
# Authoritative single-build eval of Composer's patch: replicates gate.sh pass criteria
# (calibrated case-check + p1/p2 preserve over-rejection) AND probes sealed held-outs
# (seal_proofdiv/seal_exec) + battery (t1/t2/t3, h2, ho5). One forced-fresh build.
# Uses python3.13 (gate-pinned) and /usr/bin/stat (BSD) to dodge this box's GNU-coreutils shadowing.
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
CC=$PILOT/tools
BASE=23dc6e754fef0d238db808dad02cbe8e3d72f2b3
PATCH=${1:?usage: eval_full.sh PATCH.patch}
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"; unset RUSTC RUSTUP_TOOLCHAIN
BIN="$WT/source/target-verus/release/verus"
cd "$WT"
git checkout -- . >/dev/null 2>&1
git clean -fdq source/rust_verify source/rustc_mir_build source/rustc_mir_build_additional_files >/dev/null 2>&1
git checkout --detach "$BASE" >/dev/null 2>&1
git apply --check "$PATCH" 2>/tmp/ev-apply.err && git apply "$PATCH" || { echo "APPLY-FAIL"; cat /tmp/ev-apply.err; exit 2; }
start=$(/usr/bin/stat -f %m "$WT/source/target-verus/release/rust_verify" 2>/dev/null || echo 0)
find source/rustc_mir_build/src source/rust_verify/src -name '*.rs' -exec touch {} + 2>/dev/null
( cd "$WT/source" && vargo build --release ) >/tmp/ev-build.log 2>&1 || { echo "BUILD-FAIL"; tail -5 /tmp/ev-build.log; exit 3; }
bmtime=$(/usr/bin/stat -f %m "$WT/source/target-verus/release/rust_verify" 2>/dev/null || echo 0)
echo "rebuilt=$([ "$bmtime" -ge "$start" ] && echo true || echo false) bin_fp=$(shasum -a 256 "$WT/source/target-verus/release/rust_verify" | cut -c1-16)"
grade_one(){ local out; out=$(cd "$WT/source" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH "$BIN" --crate-type=lib "$1" 2>&1)
  if echo "$out"|grep -qE 'verified, 0 errors'; then echo VERIFY; elif echo "$out"|grep -qiE 'error'; then echo REJECT; else echo OTHER; fi; }
echo "=== CALIBRATED CASE-CHECK (gate's bug+preserve arms) ==="
( cd "$CC" && python3.13 case-check.py --candidate-verus "$BIN" --calibration calibration.json --jobs 8 2>/dev/null \
  | grep -oE 'pass=(true|false)|mishandles=[0-9]+|valid-bug-still-accepted=[0-9]+|valid-preserve-rejected=[0-9]+|crash=[0-9]+' )
echo "=== BATTERY ==="
echo "t1(bug,want REJECT)=$(grade_one "$PILOT/oracle/t1_issue2219.rs")"
echo "t2(bug,want REJECT)=$(grade_one "$PILOT/oracle/t2_empty_enum.rs")"
echo "t3(sound-div,want VERIFY)=$(grade_one "$PILOT/oracle/t3_legit_divergence.rs")"
echo "h2_assoc(heldout bug,want REJECT)=$(grade_one "$PILOT/heldout2/h2_assoc_proj.rs")"
echo "h2_nested(heldout bug,want REJECT)=$(grade_one "$PILOT/heldout2/h2_generic_nested.rs")"
echo "ho5(sound-div,want VERIFY)=$(grade_one "$PILOT/heldout/ho5_real_divergence_sound.rs")"
echo "=== PRESERVE (gate p1/p2, want VERIFY = the implementation wall codex failed) ==="
echo "p1(want VERIFY)=$(grade_one "$PILOT/gate2/preserve/p1.rs")"
echo "p2(want VERIFY)=$(grade_one "$PILOT/gate2/preserve/p2.rs")"
echo "=== SEALED HELD-OUTS (model never saw; Fable VERIFIED both = generalized) ==="
echo "seal_proofdiv(want VERIFY)=$(grade_one "$PILOT/gate2/sealed/seal_proofdiv.rs")"
echo "seal_exec(want VERIFY)=$(grade_one "$PILOT/gate2/sealed/seal_exec.rs")"
git checkout -- . >/dev/null 2>&1; git checkout --detach "$BASE" >/dev/null 2>&1
echo "DONE"
