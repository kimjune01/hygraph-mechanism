#!/usr/bin/env bash
# Sonnet 4.6 · NO-ABDUCTOR arm (minimal_v3_fable prompt: generality + adversarial self-attack,
# no "build a generator/gate"). Fills the grid's Sonnet · no-abductor cell.
# Harness = claude-headless, byte-identical prompt to local/minimal_v3_fable.txt (keepalive baked in).
# Same launch shape as logs/sonnet/run2.sh; this prompt needs no --append-system-prompt (keepalive is in-prompt).
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/sonnet_noabductor
BASE=23dc6e754fef0d238db808dad02cbe8e3d72f2b3
PROMPT="$(cat "$PILOT/local/minimal_v3_fable.txt")"
mkdir -p "$LOG" /tmp/p11mf-scratch
# pristine base for the agent (step 3 tail of the runbook)
git -C "$WT" checkout -- . >/dev/null 2>&1
git -C "$WT" clean -fdq source/rust_verify source/rustc_mir_build source/rustc_mir_build_additional_files >/dev/null 2>&1
git -C "$WT" checkout --detach "$BASE" >/dev/null 2>&1
cd "$WT"
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"
echo "START $(date -u +%FT%TZ)" > "$LOG/meta.txt"
echo "model=sonnet cwd=$WT prompt=minimal_v3_fable.txt harness=claude-headless budget=4h abductor=none" >> "$LOG/meta.txt"
timeout 14400 claude -p "$PROMPT" \
  --model sonnet \
  --dangerously-skip-permissions \
  --output-format stream-json --verbose > "$LOG/stream.jsonl" 2> "$LOG/stderr.txt"
rc=$?
echo "END $(date -u +%FT%TZ) rc=$rc" >> "$LOG/meta.txt"
git -C "$WT" diff > "$LOG/sonnet_noabductor_killtime.patch"
echo "killtime diffstat:" >> "$LOG/meta.txt"
git -C "$WT" diff --stat >> "$LOG/meta.txt"
