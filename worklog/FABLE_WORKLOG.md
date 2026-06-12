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
| Fable | minimal_v3 codex-exact (controlled) | headless | 269 | all ok | REJECT (over) | WIDE-BUT-BROKEN |

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

## 2026-06-12 01:20 - Controlled ablation RESULT: model lift confirmed (prompt held constant).

Fable on codex's EXACT minimal_v3.txt, headless, ~33 min, clean base start. Patch fable_ctrl.patch
(334-line diff, 184 ins, 4 files: erase.rs, builder/mod.rs, verus.rs, verus_expr.rs). Identity-verified
driver fp fde9a107 (reproduced after target-verus moved aside; t1 base->reject).

External forced-fresh grade (IDENTICAL battery to the weak draw):
- t1 REJECT, t2 REJECT, h2_assoc REJECT, h2_generic_nested REJECT  (bug arm GENERAL, incl. both
  out-of-grammar held-outs)
- t3 REJECT, ho5 REJECT  (over-reject genuine proof divergence)
- seal_exec VERIFY (correct exec divergence), seal_proofdiv REJECT (over-reject ghost divergence)
- case-check: changed=269 exactly, changed-outside-bugset=0, valid-preserve-rejected=0, pass=true,
  mishandles=0, crash=0

THE ABLATION (prompt held constant at minimal_v3.txt):
- codex gpt-5.5  -> NARROW  (chg=114, pass=false; stayed on the !-slice)
- Fable          -> WIDE-BUT-BROKEN (chg=269, pass=true; general on bug arm + both OOG held-outs)
Swapping ONLY the model lifts narrow -> wide. This is the model effect, isolated, with the prompt
identical and the keepalive/dropped-line confounds removed.

Mechanism again MODE/ghostness ("makes CFG-pruning mode-aware", new CallRuntimeErase: proof=Erase,
exec=Keep). Different file set from the weak draw (verus_expr.rs instead of fn_call_to_vir.rs etc.) but
same method and same external grade. So across THREE Fable draws (self_verifier strong, minimal weak,
minimal codex-exact controlled) the result is invariant: general-on-bug, broken-on-divergence.

STANDING PICTURE (all prompt-controlled where it matters):
- Prompt METHOD: no lift on either model (codex 0/18 narrow across 6 methods; Fable strong ~ weak ~
  codex-exact, all wide-but-broken, all chg=269).
- MODEL: the lift (Fable > codex), now prompt-controlled (same minimal_v3.txt: 114 vs 269).
- TOOL: lifted codex 114 -> 269, i.e. to where Fable already lands with no tool.
- The divergence arm is the wall for ALL of them (model-invariant, prompt-invariant, tool-invariant);
  only the human #2501 clears it.

Honest caveats: (1) model+harness confound remains (codex-CLI vs claude-headless; cannot run Fable in
codex-CLI). (2) n=1 per cell. (3) "lift" = narrow -> wide-but-broken, NOT narrow -> correct; Fable's
wide is still broken on divergence. (4) the wide-but-broken vs narrow boundary is the only model
difference observed; on the divergence arm the models are tied (both fail).

## NEXT RUN (open thread, not yet run on any box)

gate2-Fable: hand Fable the divergence DIAGNOSIS (gate2_arm.txt + the gate2/sealed held-outs as the
calibration it lacked) and ask whether it can IMPLEMENT the fix. This is the cross-family completion of
codex's outcome C (codex gate2 arm is the one still grinding on the other machine).

Why it is sharper after the v7 finding: Fable's miss was specifically CALIBRATION, not enumeration (it
built the discriminating case v7 and mislabeled it). gate2 supplies exactly the missing label. So the
run distinguishes two hypotheses:
- given the correct label, Fable implements the ghost-vs-genuine-divergence discriminator => the wall
  was calibration (a near-A; the model can do the XOR once told where it is wrong).
- given the label, Fable still oscillates / cannot encode it => implementation wall, cross-family
  (same failure shape as codex's gate2 outcome).

State: the M4 Pro (this box) ran the two minimal variants (weak minimal_v3_fable + controlled
codex-exact minimal_v3), NOT gate2. gate2-Fable is the next run when a box is spun back up. This box
stays cool for now.

## 2026-06-12 - TRACE analysis of the weak draw: the v7 self-mislabel (calibration is the wall, not enumeration)

Read the full headless session transcript of the weak draw
(~/.claude/projects/-Users-junekim-Documents-verus-p11/e57b5cb5-*.jsonl), not just the patch.

Arc (one build, no fix-loop):
- reproduce (base verifies, bug confirmed) -> ~14 min pure diagnosis (verus.rs, into.rs Call/NeverToAny
  lowering, mod.rs lint_and_remove_uninhabited at :854 flagged as "the key site", erase.rs, as_temp.rs,
  block.rs) -> hypothesis "all construction sites have mode info available" -> keyed the fix on
  MODE/ghostness -> made ALL edits in one pass -> built once (got it right first compile) -> while it
  compiled, wrote the v1-v14 adversarial matrix -> ran matrix ("All variants pass") -> regressions
  (lifetime 94/0, modes 112/0) -> report.

The mechanism of the miss is visible in its OWN probe labels. Fable split divergence into two
pre-labeled classes:
- exec + never -> "must VERIFY": v5_exec_divergence (loop{}), v10_exec_divergence_valid
  (diverge_exec()->!). Its fix kept these verifying, so it concluded "exec divergence preserved."
- proof + never -> "must ERROR": v6 (tracked ! param), v7_extbody_proof_never
  (#[external_body] proof fn diverging()->!; consume(t); consume(t)), v9 (proof ctor of uninhabited).
  Its fix rejected all, so it счел them pass.

v7 is the smoking gun. It is STRUCTURALLY IDENTICAL to t3/ho5 (a proof fn that genuinely diverges,
then double-consume). Fable CONSTRUCTED the discriminating case itself, then LABELED it "must ERROR" by
its own theory (proof-never = bug). Its fix produced REJECT on v7, and it counted that as a pass. The
gold (per #2501, which VERIFIES t3) says v7 should VERIFY. So the failure is not that Fable could not
think of the hard case: it built the hard case and graded it with the same wrong key it used to write
the fix. "Is a proof fn returning ! the erased-ghost bug or sound divergence?" IS the predicate under
test, and Fable answered it identically in both its fix and its test oracle, so self-validation agreed
with itself and passed.

Contrast of the two automated misses (now both grounded):
- codex case-check tool: missed divergence by COVERAGE (its 2856-case grammar had no
  genuine-proof-divergence-preserve shape to fail against).
- Fable weak draw: missed divergence by CALIBRATION (it HAD the shape, v7, but assigned the wrong
  label).
This is the cleanest demonstration of the thesis: enumeration is inducible (weak prompt, no tool, Fable
still produced v7), calibration is not (the correct label for v7 cannot be self-bootstrapped because it
is the disputed predicate). Only #2501 had a truth outside the model's own belief.

Side-by-side of the two FIX discriminators (verified from casecheck_pilot.patch vs fable_arm.patch):
- codex: keep the return edge iff is_erased_ghost_value_call AND ty_is_visibly_uninhabited(ty) =
  !ty.is_inhabited_from(tcx,...). Inhabitedness query gates the keep; also carries
  keep_uninhabited_return_edge: mode != Exec.
- Fable: keep the return edge for ALL CallGhostness::Ghost (Spec/Proof) calls, unconditionally; no
  inhabitedness query in the new code.
Behaviorally identical on every probe (the inhabitedness query is near-redundant given the mode gate,
since only uninhabited returns prune the CFG). Both are MODE-driven at the load-bearing level, both
general on the bug arm (incl. out-of-grammar h2), both over-reject genuine proof divergence. The
inhabitedness query that RESULT-corrected credited as "the" mechanism is a behaviorally-redundant
refinement on these probes; the shared method is "in ghost mode, keep the edge so the borrow check sees
the following code." #2501 is the genuinely finer method (separates erased-ghost artifact from real
proof divergence), which neither automated discriminator captures.
