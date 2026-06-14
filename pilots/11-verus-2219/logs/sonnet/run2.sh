#!/usr/bin/env bash
# Sonnet gate2 arm — RE-RUN (run 1 was budget-killed at 3h mid-pivot, never cleared; fair longer shot).
# Same harness as Fable (claude-headless). Task prompt byte-identical to gate2_arm.txt.
# Two operational additions in the appended keepalive (NOT task/diagnosis changes):
#   (1) background-build+poll to survive the silent-build watchdog (as run 1);
#   (2) snapshot the diff to /tmp/p11g2-scratch/PASS-<n>.patch the instant gate.sh prints pass=true,
#       so a passing state cannot be lost to a later pivot or the budget kill (run 1's failure mode).
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/sonnet
PROMPT="$(cat "$PILOT/prompts/gate2_arm.txt")"
KEEPALIVE='OPERATIONAL (harness, not part of the task): (1) verus rebuilds are slow and silent — never block the foreground on a build for over a minute; run builds/gate in the background (append " >/tmp/p11g2-build.log 2>&1 &"), poll every ~30s with a short echo+tail so output keeps streaming. (2) IMPORTANT: the instant gate.sh prints "GATE pass=true", immediately snapshot your work before doing anything else: run  n=$(ls /tmp/p11g2-scratch/PASS-*.patch 2>/dev/null | wc -l); git -C '"$WT"' diff > /tmp/p11g2-scratch/PASS-$n.patch  — then you may keep improving. Verify a real pass by reading the gate log file directly, NOT by grepping ps output (the prompt text contains the literal string GATE pass=true and will false-positive).'
git -C "$WT" checkout -- . >/dev/null 2>&1
git -C "$WT" checkout --detach 23dc6e754fef0d238db808dad02cbe8e3d72f2b3 >/dev/null 2>&1
rm -f /tmp/p11g2-scratch/PASS-*.patch
cd "$WT"
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"
echo "START $(date -u +%FT%TZ)" > "$LOG/meta2.txt"
echo "model=sonnet cwd=$WT prompt=gate2_arm.txt harness=claude-headless budget=4h re-run" >> "$LOG/meta2.txt"
timeout 14400 claude -p "$PROMPT" \
  --model sonnet \
  --append-system-prompt "$KEEPALIVE" \
  --dangerously-skip-permissions \
  --output-format stream-json --verbose > "$LOG/stream2.jsonl" 2> "$LOG/stderr2.txt"
rc=$?
echo "END $(date -u +%FT%TZ) rc=$rc" >> "$LOG/meta2.txt"
git -C "$WT" diff > "$LOG/sonnet_gate2_run2_killtime.patch"
echo "PASS snapshots captured:" >> "$LOG/meta2.txt"
ls -la /tmp/p11g2-scratch/PASS-*.patch >> "$LOG/meta2.txt" 2>&1
cp /tmp/p11g2-scratch/PASS-*.patch "$LOG/" 2>/dev/null
echo "killtime diffstat:" >> "$LOG/meta2.txt"
git -C "$WT" diff --stat >> "$LOG/meta2.txt"
