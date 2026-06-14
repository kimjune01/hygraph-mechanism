# Pilot 11 (verus #2219) — manifest

Soundness bug whose correct fix is an XOR-shaped predicate. See `REPRODUCE.md` to run, `RESULT-corrected.md` + `MECHANISM-dissection.md` for findings.

## Layout
- `tools/` — `case-check.py` (+ `calibration.json`): the fixpoint-closed type-former gate; `clean_regrade.sh`, `render_dataset.py`: forced-fresh identity-verified grading harness.
- `gate2/` — corrected gate: `gate.sh` (case-check + a human-approved divergence golden), `preserve/` (p1=proof-divergence from #2501, p2=exec-divergence), `sealed/` (held-outs the model never sees).
- `oracle/` — t1/t2/t3 battery; `heldout/`, `heldout2/` — out-of-grammar held-outs (projection, nested-generic) + sound-divergence guards.
- `prompts/` — the arm prompts (minimal/graph/abduction/site-enum/neutral/self-verifier, v2/v3 variants, gate2_arm, the Fable variants).
- `patches/` — every produced patch, by arm:
  - prompt-method: `{graph,minimal}_draw*`, `v2_*`, `v3_{graph,minimal,neutral,siteenum}_draw*`, `abduction_draw*`, `selfverifier_draw*`
  - tool arm: `casecheck_pilot.patch`
  - corrected-gate codex arm: `gate2_codex_terminated.patch` (outcome C, oscillation)
  - Fable: `fable_sv_draw1_{partial,final}` (self_verifier), `fable_arm` (weak prompt), `fable_ctrl` (codex-exact controlled)
  - corrected-gate Composer 2.5 arm: `composer_gate2.patch` (near-A; cursor-agent)
  - corrected-gate Sonnet 4.6 arm: `sonnet_gate2_run2.patch` (near-A, the verified PASS-0 snapshot; `sonnet_gate2.patch` = run-1 truncated killtime)
- `logs/` — per-arm session logs (`abduction/`, `sv/`, `v3/`, `graph_scratch/`, `composer/`, `sonnet/` — each with NOTES.md + eval output + stream).
- `results/` — `RESULTS_*tally.txt` grade tallies.
- `clean_dataset.{jsonl,md}` — the 21-artifact fixed-toolchain dataset (provenance-stamped).
