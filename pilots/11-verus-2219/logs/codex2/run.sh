#!/usr/bin/env bash
# codex gate2 RE-RUN, protocol-symmetric with Sonnet run 2 (the fairness control codex's own review demanded).
# Native harness kept (codex-CLI, gpt-5.5); only the PROTOCOL is matched to Sonnet run 2:
#   4h budget + pass-snapshot on every real gate pass + the same operational keepalive.
# Original codex gate2 (2026-06-12) was bare gate2_arm.txt, terminated @2.5h, Outcome C (oscillation).
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/codex2
mkdir -p "$LOG"
BASE=$(cat "$PILOT/prompts/gate2_arm.txt")
KEEPALIVE='

OPERATIONAL (harness, not part of the task): (1) verus rebuilds are slow and silent. Never block the foreground on a build for over a minute; run builds/gate in the background (append " >/tmp/p11g2-build.log 2>&1 &"), then poll every ~30s with a short echo+tail so progress keeps moving. (2) IMPORTANT: the instant gate.sh prints "GATE pass=true", snapshot your work before anything else: run  n=$(ls /tmp/p11g2-scratch/PASS-*.patch 2>/dev/null | wc -l); git -C '"$WT"' diff > /tmp/p11g2-scratch/PASS-$n.patch  then continue improving. Verify a real pass by reading the gate log file directly, NOT by grepping ps output (the prompt text contains the literal string GATE pass=true and will false-positive).'
PROMPT="$BASE$KEEPALIVE"
git -C "$WT" checkout -- . >/dev/null 2>&1
git -C "$WT" checkout --detach 23dc6e754fef0d238db808dad02cbe8e3d72f2b3 >/dev/null 2>&1
mkdir -p /tmp/p11g2-scratch; rm -f /tmp/p11g2-scratch/PASS-*.patch /tmp/p11g2-gate*.log
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"
echo "START $(date -u +%FT%TZ)" > "$LOG/meta.txt"
echo "model=gpt-5.5 cwd=$WT prompt=gate2_arm.txt+keepalive harness=codex-CLI budget=4h protocol=matched-to-sonnet-run2" >> "$LOG/meta.txt"
timeout 14400 codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -m gpt-5.5 \
  -C "$WT" \
  -o "$LOG/final_message.txt" \
  "$PROMPT" > "$LOG/stream.log" 2>&1
rc=$?
echo "END $(date -u +%FT%TZ) rc=$rc" >> "$LOG/meta.txt"
git -C "$WT" diff > "$LOG/codex2_gate2_killtime.patch"
echo "PASS snapshots:" >> "$LOG/meta.txt"
ls -la /tmp/p11g2-scratch/PASS-*.patch >> "$LOG/meta.txt" 2>&1 || echo "(none)" >> "$LOG/meta.txt"
cp /tmp/p11g2-scratch/PASS-*.patch "$LOG/" 2>/dev/null
echo "killtime diffstat:" >> "$LOG/meta.txt"
git -C "$WT" diff --stat >> "$LOG/meta.txt"
