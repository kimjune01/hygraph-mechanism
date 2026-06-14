#!/usr/bin/env bash
# Grade #2501 (human general fix, 455695049) at its OWN toolchain 1.95.0.
# Prior attempt failed: clean_regrade forced the 1.93.1 custom shims (/tmp/rustup-shims) onto
# #2501's 1.95.0 source -> 105 rustc-internal errors. Here we DROP the custom shims and let
# rustup's proxy pick 1.95.0 from #2501's rust-toolchain.toml. Restores base + 1.93.1 at the end.
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/gold2501
BASE=23dc6e754fef0d238db808dad02cbe8e3d72f2b3
GOLD=455695049
BIN="$WT/source/target-verus/release/verus"
cd "$WT"
# clean PATH: vargo + system, NO /tmp/rustup-shims (so rustup proxy honors rust-toolchain.toml)
CLEANPATH="$WT/tools/vargo/target/release:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
restore(){ git -C "$WT" checkout -- . >/dev/null 2>&1; git -C "$WT" checkout --detach "$BASE" >/dev/null 2>&1; echo "restored to base $BASE"; }
echo "START $(date -u +%FT%TZ)" > "$LOG/build_grade.log"
git checkout -- . >/dev/null 2>&1
git checkout --detach "$GOLD" >/dev/null 2>&1 || { echo "checkout-fail" >>"$LOG/build_grade.log"; exit 2; }
echo "toolchain: $(grep channel rust-toolchain.toml)" >> "$LOG/build_grade.log"
find source/rustc_mir_build/src source/rust_verify/src -name '*.rs' -exec touch {} + 2>/dev/null
( cd "$WT/source" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH="$CLEANPATH" vargo build --release ) >"$LOG/build.log" 2>&1
bexit=$?
echo "build_exit=$bexit" >> "$LOG/build_grade.log"
if [ $bexit -ne 0 ]; then echo "BUILD FAILED (tail):" >> "$LOG/build_grade.log"; tail -15 "$LOG/build.log" >> "$LOG/build_grade.log"; restore; echo "END $(date -u +%FT%TZ)" >> "$LOG/build_grade.log"; exit 3; fi
echo "bin_fp=$(shasum -a 256 "$BIN" 2>/dev/null | cut -c1-16)" >> "$LOG/build_grade.log"
grade_one(){ local out; out=$(cd "$WT/source" && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH="$CLEANPATH" "$BIN" --crate-type=lib "$1" 2>&1)
  if echo "$out"|grep -qE 'verified, 0 errors'; then echo VERIFY; elif echo "$out"|grep -qiE 'error'; then echo REJECT; else echo "OTHER<<$out>>"; fi; }
{
echo "=== #2501 battery (1.95.0, gold) ==="
echo "t1(bug,want REJECT)=$(grade_one "$PILOT/oracle/t1_issue2219.rs")"
echo "t2(bug,want REJECT)=$(grade_one "$PILOT/oracle/t2_empty_enum.rs")"
echo "t3(sound-div,want VERIFY)=$(grade_one "$PILOT/oracle/t3_legit_divergence.rs")"
echo "ho5(sound-div,want VERIFY) === THE QUESTION ===> $(grade_one "$PILOT/heldout/ho5_real_divergence_sound.rs")"
echo "h2_assoc(bug,want REJECT)=$(grade_one "$PILOT/heldout2/h2_assoc_proj.rs")"
echo "h2_nested(bug,want REJECT)=$(grade_one "$PILOT/heldout2/h2_generic_nested.rs")"
echo "p1(want VERIFY)=$(grade_one "$PILOT/gate2/preserve/p1.rs")"
echo "seal_proofdiv(want VERIFY)=$(grade_one "$PILOT/gate2/sealed/seal_proofdiv.rs")"
} >> "$LOG/build_grade.log" 2>&1
restore
echo "END $(date -u +%FT%TZ)" >> "$LOG/build_grade.log"
echo "DONE" >> "$LOG/build_grade.log"
