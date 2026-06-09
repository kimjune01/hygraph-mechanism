#!/bin/bash
# gold_grade.sh -- the $0 pre-flight wall (OPERATIONS Stage 0).
# Reconstruct an instance at the pre-merge base and prove the merge-certified test
# is RED at base (bug present, test catches it) and GREEN on the gold fix.
# Splits the PR diff into test-files (the oracle) vs source-files (the gold fix) by
# a test-path heuristic, so a candidate that does not red/green cleanly is KNOWN_BAD
# and never enters the ablation. Shaped from macbre/sql-metadata#630.
#
#   gold_grade.sh <repo_url> <merge_sha> <build_cmd> <test_cmd> [workdir]
# env: TEST_RE overrides the test-path regex.
set -u
REPO_URL="$1"; MERGE="$2"; BUILD="$3"; TEST="$4"
WORK="${5:-/tmp/gg_$(basename "$REPO_URL" .git)}"
TEST_RE="${TEST_RE:-(^|/)(test|tests|spec|__tests__)/|_test\.|\.test\.|_spec\.}"

[ -d "$WORK/.git" ] || git clone -q "$REPO_URL" "$WORK"
cd "$WORK" || exit 2
# hard-reset so a reused work dir can't leak a prior run's gold files into "base"
git reset --hard -q "${MERGE}^1" 2>/dev/null && git clean -qfdx -e .venv 2>/dev/null \
  || { echo "GRADE: FAIL (no base ${MERGE}^1)"; exit 2; }

# split changed files into test vs source (bash 3.2 portable: no mapfile)
FILES=()
while IFS= read -r f; do [ -n "$f" ] && FILES+=("$f"); done < <(git diff --name-only "${MERGE}^1" "$MERGE")
TESTS=(); SRC=()
for f in "${FILES[@]}"; do
  if echo "$f" | grep -qE "$TEST_RE"; then TESTS+=("$f"); else SRC+=("$f"); fi
done
[ ${#TESTS[@]} -gt 0 ] || { echo "GRADE: SKIP (no test files in PR diff)"; exit 3; }

eval "$BUILD" >/tmp/gg_build.log 2>&1 || { echo "GRADE: FAIL (build); see /tmp/gg_build.log"; exit 2; }

# STAGE 1: base + test oracle only -> expect RED
git checkout "$MERGE" -- "${TESTS[@]}"
if eval "$TEST" >/tmp/gg_red.log 2>&1; then
  echo "GRADE: FAIL (test PASSES at base -- oracle does not catch the bug)"; exit 1
fi
# STAGE 2: + gold source fix -> expect GREEN
[ ${#SRC[@]} -gt 0 ] && git checkout "$MERGE" -- "${SRC[@]}"
if eval "$TEST" >/tmp/gg_green.log 2>&1; then
  echo "GRADE: PASS  (red-at-base, green-on-gold)"
  echo "  tests:  ${TESTS[*]}"
  echo "  source: ${SRC[*]}"
  exit 0
else
  echo "GRADE: FAIL (gold fix does not green the test -- KNOWN_BAD, like Pro's 3 defects)"; exit 1
fi
