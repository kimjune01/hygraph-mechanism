#!/usr/bin/env bash
# Sonnet gate2 arm — claude-headless, SAME harness as Fable (cleanest cross-model match).
# Task prompt byte-identical to gate2_arm.txt; only an operational keepalive is appended
# (background-build+poll) to survive the claude-headless silent-build watchdog — the same
# protocol Fable's minimal_v3 prompt already baked in. Not a change to task/diagnosis.
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/sonnet
mkdir -p "$LOG"
PROMPT="$(cat "$PILOT/prompts/gate2_arm.txt")"
KEEPALIVE='OPERATIONAL (harness keepalive, not part of the task): verus rebuilds are slow and silent. Never run a blocking build in the foreground for more than a minute. Run builds/gate in the background (append " >/tmp/p11g2-build.log 2>&1 &"), then poll every ~30s with a short echo + tail so output keeps streaming; only proceed once the build/gate finishes.'
# reset verus-p11 to clean base before the run (one arm per machine)
git -C "$WT" checkout -- . >/dev/null 2>&1
git -C "$WT" checkout --detach 23dc6e754fef0d238db808dad02cbe8e3d72f2b3 >/dev/null 2>&1
cd "$WT"
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"
echo "START $(date -u +%FT%TZ)" > "$LOG/meta.txt"
echo "model=sonnet cwd=$WT prompt=gate2_arm.txt harness=claude-headless" >> "$LOG/meta.txt"
timeout 10800 claude -p "$PROMPT" \
  --model sonnet \
  --append-system-prompt "$KEEPALIVE" \
  --dangerously-skip-permissions \
  --output-format stream-json --verbose > "$LOG/stream.jsonl" 2> "$LOG/stderr.txt"
rc=$?
echo "END $(date -u +%FT%TZ) rc=$rc" >> "$LOG/meta.txt"
git -C "$WT" diff > "$LOG/sonnet_gate2.patch"
echo "diffstat:" >> "$LOG/meta.txt"
git -C "$WT" diff --stat >> "$LOG/meta.txt"
