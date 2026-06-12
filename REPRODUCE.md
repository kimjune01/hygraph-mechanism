# Reproducing the results

This repo is a mechanism case study, not a benchmark. Reproduction means re-deriving the *specific findings* under control, not a population rate. Start with [`LESSONS.md`](LESSONS.md) for what was found and [`README.md`](README.md) for why the regime matters.

## Headline case: verus #2219 (pilot 11)

A soundness bug whose correct fix is an XOR-shaped predicate. Everything to reproduce it lives in [`pilots/11-verus-2219/`](pilots/11-verus-2219/):

- **Step-by-step runbook:** [`pilots/11-verus-2219/REPRODUCE.md`](pilots/11-verus-2219/REPRODUCE.md) — build verus at base `23dc6e75`, recalibrate the gate to your binary, run an arm, grade.
- **The gate:** `tools/case-check.py` (+ `calibration.json`) — the fixpoint-closed type-former enumeration; `gate2/` is the corrected gate (case-check + a human-approved divergence golden from `#2501`).
- **The grading harness:** `tools/clean_regrade.sh` + `tools/render_dataset.py` — forced-fresh, identity-verified builds (defeats the stale-binary trap, lesson 9) over a sealed battery + held-outs.
- **The arms (patches + logs):** prompt-method arms (`*_draw*.patch`, `logs_*`), the `case-check` tool arm (`casecheck_pilot.patch`), the corrected-gate codex arm (`gate2_codex_terminated.patch`), and the Fable arms (`fable_*.patch`).
- **The clean dataset:** `clean_dataset.jsonl` / `clean_dataset.md` — 21 artifacts at fixed toolchain, every row provenance-stamped.
- **Findings writeups:** `RESULT-corrected.md`, `MECHANISM-dissection.md`, and `worklog/FABLE_WORKLOG.md`.

## Non-negotiables (or you will get false results)

These are the traps that produced false headlines mid-study (see `LESSONS.md`):

1. **Force-fresh + verify binary identity before every grade.** The vendored `rustc_mir_build` crate does not rebuild on incremental `vargo build`. The harness handles this; manual builds must `touch source/rustc_mir_build/src/**` and confirm a known case flips.
2. **Recalibrate the gate to your own base binary** — `calibration.json` is build-specific.
3. **Grade only same-toolchain artifacts together** — base/#2230 are 1.93.1, #2501 is 1.95.0.
4. **Grade on held-outs *outside* the gate** (`oracle/`, `heldout2/`, `gate2/sealed/`) — passing the gate is tabulation-complete; the held-outs catch it.
5. **Read traces, not just patches** — the patch is a projection; the cause (coverage vs implementation vs calibration) is only in the trace's *actions*, cross-checked against the maintainer fix.

## Other pilots

`pilots/01..10` are the earlier instances (SWE-bench-style tasks, flux, the multi-model deconfound). Each has its own `*.md` or `RESULTS*`. The verus pilots (10, 11) are where the XOR/oracle-absent regime is cleanest.
