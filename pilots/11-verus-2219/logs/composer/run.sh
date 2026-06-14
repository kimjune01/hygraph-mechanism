#!/usr/bin/env bash
# Composer 2.5 gate2 arm — symmetric with codex (codex CLI) and Fable (claude-headless).
# Harness for THIS arm = cursor-agent (the only driver for Composer 2.5); harness confound noted (WORK_LOG line 151).
set -uo pipefail
WT=/Users/junekim/Documents/verus-p11
PILOT=/Users/junekim/Documents/hygraph-mechanism/pilots/11-verus-2219
LOG=$PILOT/logs/composer
PROMPT="$(cat "$PILOT/prompts/gate2_arm.txt")"
cd "$WT"
# put vargo + shims on PATH so the agent can build (same env the gate uses)
export PATH="$WT/tools/vargo/target/release:/tmp/rustup-shims:$PATH"
echo "START $(date -u +%FT%TZ)" > "$LOG/meta.txt"
echo "model=composer-2.5 cwd=$WT prompt=gate2_arm.txt" >> "$LOG/meta.txt"
# 3h budget (codex ran ~2.5h before termination)
timeout 10800 cursor-agent -p --force --model composer-2.5 \
  --output-format stream-json "$PROMPT" > "$LOG/stream.jsonl" 2> "$LOG/stderr.txt"
rc=$?
echo "END $(date -u +%FT%TZ) rc=$rc" >> "$LOG/meta.txt"
# capture whatever patch the agent left, regardless of self-reported verdict
git -C "$WT" diff > "$LOG/composer_gate2.patch"
echo "diffstat:" >> "$LOG/meta.txt"
git -C "$WT" diff --stat >> "$LOG/meta.txt"
