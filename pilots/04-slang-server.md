# Pilot 04 — hudson-trading/slang-server #342 (closes #310)

The **deepest genuine-diagnosis instance in the pool** (historical graph depth 7, and the
blind regen reproduced its key kill), run under the corrected protocol. Box: cppbox (EC2,
C++/CMake, slang built from source). Clean codex (GPT-5.5, pre-cutoff).

## Why this was the strongest existence candidate
The historical graph genuinely *killed the obvious fix*: the maintainer suggested "just use
double backticks," but SystemVerilog's `` `` `` token-paste operator and the `` name```MACRO_A ``
case mean any fixed delimiter < 4 collides. Correct fix = dynamic `N+1` delimiter. That is the
skeptic-refuter shape (obvious fix fails, diagnosis is load-bearing) — and the blind recon
reproduced it independently (killed "fixed double/triple delimiter," found the `appendCodeBlock`
quad-backtick precedent). Deep, real, generator-invariant diagnosis.

## Essence oracle (render-correctness, mechanism-agnostic)
`/tmp/ss_check.sh`: applies the agent's `Markdown.cpp` to a warm grade tree (base source +
gold test), incremental-rebuilds `server_unittests`, runs the two backtick cases, and accepts
ANY render-correct wrapping (delimiter run > longest internal run + padding) — minimal `2/4`
OR the reporter's static `4/4`. Drops the gold's exact-minimal over-specification. Verified
red-at-base / green-on-gold.

## Result

| arm | essence | wall | fix |
|---|---|---|---|
| baseline (mini-SWE-agent) | **PASS** | ~123 s | dynamic `maxBacktickRun + 1` delimiter + space padding |
| +M | not run | — | moot: baseline passes the essence, no gap possible |

**Null.** The minimal agent implemented the *correct general fix* (dynamic delimiter, handling
the triple-backtick case) — not even the static-4 shortcut. The graph was not needed.

## Why even the deepest graph didn't help — the load-bearing finding
The graph's depth is real, but the **issue body carries the discriminating signal**: it shows
the `` name```MACRO_A `` triple-backtick example AND the reporter states "valid SV has at most 3
consecutive backticks, wrap with 4." A competent minimal agent reads the issue, sees the
token-paste example, and writes the dynamic fix. The graph's H₁-kill (obvious double-backtick
fix fails) targeted the *maintainer's* comment, which the agent never sees; the *reporter's*
framing already steers toward the right answer.

So depth-of-graph did NOT predict an existence case here. What predicts a null is **whether the
issue underdetermines the fix** — and a well-written bug report (example + suggested fix) does
not, regardless of how deep the diagnosis *could* go.

## Standing tally (corrected protocol): 4 nulls, 0 existence cases
sql-metadata (#401), howsmyssl (#301), qrtool (#695), slang-server (#310) — across the full
depth range, the minimal agent captured the essence unaided. In this pool (the pipeline's own
merged bug-fix issues, with well-specified reports), the hypothesis graph is **not load-bearing
for first-pass diagnosis**. See `worklog` for the honest reframe and the two untested regimes
(genuinely underdetermined symptoms; the review/iteration loop).
