#!/usr/bin/env bash
# Generate machine-local copies of the Fable prompt + grading harness with your paths substituted.
# Usage: ./setup.sh <absolute-path-to-verus-checkout-at-23dc6e75>
set -euo pipefail
WT="${1:?usage: ./setup.sh /abs/path/to/verus}"
HERE="$(cd "$(dirname "$0")" && pwd)"              # .../pilots/11-verus-2219
DEV_WT="/Users/junekim/Documents/verus-p11"        # paths baked in on the dev box
DEV_CC="/tmp/case-check"
LOCAL="$HERE/local"; mkdir -p "$LOCAL"

subst() { sed -e "s#$DEV_WT#$WT#g" -e "s#$DEV_CC#$HERE/tools#g" "$1" > "$2"; }

subst "$HERE/prompts/minimal_v3_fable.txt" "$LOCAL/minimal_v3_fable.txt"
subst "$HERE/prompts/self_verifier.txt"    "$LOCAL/self_verifier.txt"
subst "$HERE/tools/clean_regrade.sh"       "$LOCAL/clean_regrade.sh"; chmod +x "$LOCAL/clean_regrade.sh"
subst "$HERE/gate2/gate.sh"                "$LOCAL/gate.sh"; chmod +x "$LOCAL/gate.sh"

echo "wrote $LOCAL/{minimal_v3_fable.txt,self_verifier.txt,clean_regrade.sh,gate.sh}"
echo "verus worktree: $WT"
echo
echo "REMAINING MANUAL STEP: these scripts assume the rustup-shims dir is /tmp/rustup-shims."
echo "If yours differs (check 'tools/activate' in your verus checkout), fix it:"
echo "  grep -rl /tmp/rustup-shims \"$LOCAL\" | xargs sed -i '' 's#/tmp/rustup-shims#<your-shims-dir>#g'   # macOS sed"
echo
echo "Then: recalibrate (step 3 of REPRODUCE.md), hand $LOCAL/<prompt> to a Claude Code fable agent, grade with $LOCAL/clean_regrade.sh."
