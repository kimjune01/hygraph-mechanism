# Lessons

Distilled from `worklog/WORK_LOG.md` (chronological) + `worklog/FABLE_WORKLOG.md`. The headline case is pilot 11 (verus #2219), a soundness bug whose correct fix is an XOR-shaped predicate: detect where rustc *believes a value uninhabited* but the code does *not* actually diverge, while leaving genuine divergence alone.

## Scientific findings (verus #2219)

1. **Prompt-method engineering gives no lift.** Six prompt-encoded "methods of inquiry" (hypothesis-graph, bi/tri-abduction, site-enum, self-verifier, neutral) × 3 draws: codex stayed narrow 0/18. Fable's strong (self_verifier) and weak (minimal) prompts produced the *same* external grade. The method encoded in the prompt does not change where the model lands.

2. **Model lift exists, prompt held constant.** Same `minimal_v3.txt`: codex → narrow (changed=114), Fable → wide (changed=269). Swapping only the model lifts narrow→wide. (Caveat: model+harness, not pure weights — codex-CLI vs claude-headless.)

3. **Tool lift.** The execution-gated `case-check` gate lifted codex 114→269 — to where Fable already lands with no tool.

4. **The divergence arm is the wall.** General-on-the-bug-arm is reachable (Fable, the tool); the XOR's *second* arm — within proof mode, telling an erased-ghost uninhabited value (the bug) from a genuinely-diverging one (sound) — is failed by every automated approach (codex prompts, codex+tool, Fable strong/weak, codex+corrected-gate). Only the human maintainer fix (#2501) clears it. Model-, prompt-, and tool-invariant.

5. **Enumeration is inducible; calibration is not** — the cleanest result, from a trace. On the weak prompt with no tool, Fable *constructed* the discriminating case (`v7`: a proof fn that genuinely diverges, then double-consumes — structurally identical to the held-out `t3`), then *labeled it "must ERROR"* by its own theory, its fix rejected it, and it counted that as a pass. The gold (#2501) says it must VERIFY. The model can build itself a wide net (enumeration); it cannot build itself an external oracle (calibration), because the correct label *is* the disputed predicate.

6. **WIDE-BUT-BROKEN is an attractor.** General on the bug arm + over-rejects genuine divergence. Both Fable (every draw) and the codex+tool fix land here.

7. **Diagnosis vs implementation.** Handing codex the *diagnosis* (a corrected gate that flags the divergence over-rejection) did not unlock it — it oscillated for ~2.5h (proven: non-monotone, floor never broken, low-mishandles states anti-correlated with divergence-preservation). So for codex the residual is *implementation*, not diagnosis. (Cross-family — does Fable, handed the diagnosis, also fail to implement — is the open run.)

8. **The load-bearing mechanism is the mode gate, not the inhabitedness query.** Both automated fixes reduce to "in ghost mode, keep the CFG edge so borrowck sees the following code." Fable did it with *no* `is_inhabited_from` call; codex's inhabitedness query is a behaviorally-redundant refinement on these probes. `#2501` is the genuinely finer method (separating erased-ghost artifact from real divergence) that neither automated discriminator captured. *(Corrects an earlier overclaim that the model "reached for the verifier's own oracle.")*

## Methodological lessons

9. **The stale-binary trap.** A vendored crate (`rustc_mir_build`) does not rebuild on plain incremental `vargo build`, so grades silently run on the old binary. This produced false headlines — a held-out conclusion was flipped *twice* before the cause was caught: the measurement, not the model, was the moving variable. **Mandatory:** force-fresh (touch sources) + verify binary identity (fingerprint / confirm a known case flips) before every grade.

10. **Held-outs outside the gate are the final check.** A gate is only as good as its *coverage* and its *calibration*. The handed gate missed divergence by coverage (its grammar never generated the shape); Fable's self-built gate missed it by calibration (had the shape, wrong label). Held-outs *outside* the gate caught both. Gate coverage sets the model's generalization frontier.

11. **Actions in the trace, cross-checked against external gold, don't lie — narration does.** A patch is a projection: WIDE-BUT-BROKEN collapses coverage/implementation/calibration failures into one artifact. The trace recovers the cause — but only the *actions* (the case it built, the label it assigned, the verdict it recorded), not the model's self-explanation. Mechanism claims need triangulation: external forced-fresh grade + trace actions + human-approved gold.

12. **Calibration comes from approved history — asymmetrically.** Goldens are free from the repo: the merged fix, the regression suite, the resolved-issue label. But the asymmetry is the XOR: you get strong goldens for "don't break what works" and "the reported case is wrong," and *no* golden for the generalization/look-alike disambiguation until a human adjudicates each. And approved ≠ perfect (`#2501` over-rejects `ho5`) — you inherit the humans' blind spots.

13. **Contamination control.** Confirm the fix post-dates the model's training cutoff (here Fable's Jan-2026 cutoff vs the #2230/#2501 fixes at Mar/Jun 2026 → structurally clean) and run a recall probe (the model can't recite the fix). Reaching the predicate is then reconstruction, not recall.

14. **Model+harness is ecological validity, not a confound** — *if scoped*. Compare deployed workflows (codex-in-CLI, Fable-headless / Claude-Code), and claim about the workflow, not the weights, unless you cross the harnesses.

15. **Adversarial gates before shipping.** Independent Fable/codex review caught real errors here: a 15/15 miscount, a crash-gate confound, and the syft binary-extractor data-loss. Volley before you commit a conclusion.

## The transferable pattern

16. **Represent-vs-tabulate / the coarse proxy recurs across domains.** rustc-uninhabited vs actually-non-returning (the verus XOR); `pkg.Type` vs per-package installed-evidence (syft PR #4905); a cataloger `language` tag vs subsumable-on-overlap. Rich taxonomies tempt you to tabulate the *category* when the real predicate is per-*instance*. **Absence has no test:** unit tests verify the cases you wrote, type systems verify well-formedness — neither checks completeness against the domain. Only an externalized completeness / symmetric-difference (XOR) check catches the omission, and it must carry external ground truth or it just re-tabulates the model's belief (lesson 5).
