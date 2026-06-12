# Fable arm worklog (verus #2219)

Separate from `WORK_LOG.md` so it folds into the other machine without merge conflict.
Machine: second box (june.kim). Model "Fable" resolves to `claude-fable-5` via `claude --model fable`
(distinct from `claude-opus-4-8`; confirmed by CLI self-report). Jan-2026 cutoff predates the fixes
(#2230 / #2501), so contamination-clean. Runs are headless `claude --model fable -p`, NOT the Agent
tool, so the 10-min stream watchdog never applies and the keepalive scaffolding is unnecessary.

Reproduction harness: `pilots/11-verus-2219/REPRODUCE.md` + `setup.sh`. verus built at base
23dc6e75 (toolchain 1.93.1). case-check recalibrated to the local base binary:
`valid-bug=269 valid-preserve=1794` (exact match to dev box). All grades are forced-fresh and
identity-verified (move `target-verus` aside, rebuild, confirm `rustc_mir_build` recompiles and t1
flips base->reject) to defeat the vendored-crate stale-binary trap that produced earlier false headlines.

## Ablation table (this machine + folded-in dev-box rows)

| model | prompt / arm | harness | changed | bug arm (t1/t2/h2) | divergence (t3/ho5) | bucket |
|---|---|---|---|---|---|---|
| (ref) | base | - | 0 | accepts all (unsound) | VERIFY | buggy baseline |
| (ref) | #2230 maintainer narrow | - | 114 | t1 ok, t2 fail | VERIFY | narrow |
| (ref) | #2501 maintainer general | - | 269 | all ok | VERIFY | GENERAL (correct) |
| codex gpt-5.5 | 6 prompt methods x3 (18 draws) | codex-CLI | 114 / ~0 | t1 ok, t2 fail | VERIFY | NARROW (0/18) |
| codex gpt-5.5 | case-check tool (execution-gated) | codex-CLI | 269 | all ok | REJECT (over) | WIDE-BUT-BROKEN |
| Fable | self_verifier (strong) | Agent | 269 | all ok | REJECT (over) | WIDE-BUT-BROKEN |
| Fable | minimal_v3_fable (weak) | headless | 269 | all ok | REJECT (over) | WIDE-BUT-BROKEN |
| Fable | minimal_v3 codex-exact (controlled) | headless | running | - | - | pending |

Reading: prompt-method engineering lifted neither model (codex 0/18 narrow; Fable strong ~ weak,
identical external grade). What lifted: the execution-gated tool for codex (114 -> 269), and raw
capability for Fable (269 with no tool, no leak). The residual flaw (over-rejects genuine proof-mode
divergence) is invariant across both Fable prompts and matches the codex tool fix.

## 2026-06-12 00:11 - Fable draw on the WEAK prompt (minimal_v3_fable). Bucket: WIDE-BUT-BROKEN.

Headless `claude --model fable`, ~28 min, clean base start. Patch `fable_arm.patch` (276 ins / 33 del,
7 files: erase.rs, fn_call_to_vir.rs, rust_to_vir_expr.rs, rust_to_vir_func.rs, builder/expr/into.rs,
builder/mod.rs, rustc_mir_build_additional_files/verus.rs). Identity-verified driver fp cd0c7e69
(reproducible after target-verus moved aside; t1 base->reject confirms MIR/erase changes are live).

External forced-fresh grade:
- t1 REJECT, t2 REJECT, h2_assoc REJECT, h2_generic_nested REJECT  (bug arm GENERAL, incl. both
  out-of-grammar held-outs, same coverage as #2501)
- t3 REJECT, ho5 REJECT  (OVER-REJECT genuine proof divergence; both maintainer fixes VERIFY these)
- case-check: changed=269 exactly, changed-outside-bugset=0, valid-preserve-rejected=0, pass=true,
  mishandles=0, crash=0

Sealed held-outs (gate2/sealed, never seen by the model):
- seal_exec (real EXEC divergence): VERIFY  (correct; Fable keeps rustc Unreachable for exec-never)
- seal_proofdiv (ghost/proof divergence): REJECT  (over-reject; structurally identical to t3/p1 which
  are SOUND preserve cases per gate2_arm.txt and #2501)

Mechanism: Fable distinguishes exec-never (keep Unreachable, sound) from proof-never (preserve the edge
to catch the bug). It then preserves the edge for ALL proof-never, so genuine proof-mode divergence
(t3, ho5, seal_proofdiv) is over-rejected. It solved the easy arm (exec vs ghost) and missed the hard
arm (within proof: erased-ghost bug vs genuinely-diverging), because at MIR level `mk::<!>(){loop{}}`
and the erased-ghost bug look identical and "which is it" IS the predicate under test. Same wall the
self_verifier Fable draw and the codex tool fix hit; only the human maintainer (#2501) clears it.

Significance vs the self_verifier draw: this is the WEAK prompt (generality + adversarial self-attack
only; no "build a generator" instruction, no axis-family leak). It reaches the SAME wide-but-broken fix
as the strong tool-building prompt. So the wide-but-broken profile is robust to prompt strength, and the
divergence wall is not an artifact of the tool-building scaffold.

## 2026-06-12 00:46 - Controlled ablation launched (codex-exact minimal_v3.txt). PENDING.

Point raised by operator: for a clean model ablation the Fable prompt must match the one codex ran.
Diff of minimal_v3.txt (codex) vs minimal_v3_fable.txt (Fable): lines 1-28 byte-identical (bug
statement, generality/no-over-reject definition). Identical site hint and causal framing. Deltas were
only (a) keepalive scaffolding (added for the Agent watchdog, method-neutral) and (b) one dropped
redundant "legitimate programs must still verify" line (cuts against Fable on the over-rejection axis,
cannot inflate its lift).

Since this machine runs Fable headless (no Agent watchdog), the keepalive is unnecessary, so we re-run
Fable on codex's EXACT minimal_v3.txt. Clean base rebuilt first (driver fp 2e752dd9, t1 accepts = bug
reproduces). Residual confound named: codex-CLI vs claude-headless harness (model+harness comparison
with prompt held constant, not pure weights).

Expected read on completion: same prompt, codex NARROW (chg=114) vs Fable WIDE (chg=269) = model lift
with prompt controlled. Result + verified changed-count to be appended here when the run finishes.
