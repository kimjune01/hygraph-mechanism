# Pilot 03 - sorairolake/qrtool #1002 (closes #695)

First run of the **corrected** protocol: industry-standard minimal baseline
(adapted mini-SWE-agent) + **issue-derived, mechanism-agnostic essence oracle** +
clean codex (GPT-5.5, cutoff predates the May-2026 fix). Box: rustbox (EC2).

## Harness corrections validated here
- **Baseline = adapted mini-SWE-agent** (`tools/minimal_prompt.tmpl`): its verbatim
  system+instance prompt (bash-only, issue-as-task, reproduce/edit/verify, source-only),
  with the litellm backend swapped for codex, `/testbed` -> box work tree via `/tmp/box-sh`
  (whose fresh-subshell-per-command model already matches mini's), and the git-diff
  submission swapped for our run-handle. No longer my improvised prompt.
- **Essence oracle, not the gold test** (`/tmp/qrtool_check.sh`): the issue's essence is
  "decoding a no-QR image must not return silent empty output." The oracle asserts
  non-zero exit + a no-QR-ish message, accepting ANY exit code / wording. The gold test
  over-specified exit==65 + exact string "no QR code found". Verified red-at-base (exit 0,
  silent) / green-on-gold.

## Result

| arm | essence | wall | fix |
|---|---|---|---|
| baseline (mini-SWE-agent) | **PASS** | ~91 s | 5 LOC in `app.rs`: empty detection -> `Error: could not find a QR code in the image`, exit 1 |
| +M | not run | - | moot: baseline already passes the essence, so no gap is possible |

**Null on the existence claim.** The minimal agent captured the essence unaided. The
mechanism-agnostic oracle did its job: the baseline's exit-1 / "could not find a QR code"
differs from gold's exit-65 / "no QR code found", yet both satisfy the essence -- a strict
gold test would have falsely failed this correct fix.

## Why it was a null (and how we could have predicted it)
The blind recon graph was **shallow**: one call-path trace (`detect_grids` -> `grids_as_bytes`
returns `Ok(vec![])` -> `for content in contents` no-ops -> silent `Ok(())`), two rivals
killed. Small graph -> shallow diagnosis -> moderate fix-symptom distance -> determined cause.
**Heuristic confirmed: blind-graph size is a cheap leading indicator of diagnostic depth**,
and qrtool's was small. (This is the *blind-regenerated* graph's size, which reflects real
diagnostic work - not pilot-01's discredited *historical*-graph branchiness, which was review
noise.) Graph saved at `pilots/03-qrtool/graph_M.blind.md`.

## Carry-forward
- Existence cases live in the **deep-graph tail**. Next: recon-triage candidates (recon is
  ~80s of codex), rank by blind-graph depth, run the full baseline-vs-+M ablation only on the
  big graphs. Compiler/linker/type-checker internals (flux #833, wild #1915) are the bets.
- **wild #1924 gold-grade is blocked** (not a defect): its integration-test harness has its own
  linker registry and rejects `lld` for `SoSingleLinker` even when installed; needs dedicated
  multi-linker test config. Revisit with setup, do not rabbit-hole.
- Process: reset work trees with `git reset --hard HEAD` (not `git checkout -f .`, which
  restores from a staged index - leaked gold once here).
