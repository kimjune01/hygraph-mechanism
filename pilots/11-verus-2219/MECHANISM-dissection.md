# Mechanism dissection — how the executable gate lifted codex on verus #2219

*Case study, n=1. The claim is not "works more often" — it is "this is what the lift IS, dissected." Evidence = the codex hill-climb trace (`/tmp/p11cc-run.log`, 43,586 lines, 281 case-check invocations) + the resulting patch + the clean re-grade dataset.*

## The central mechanism
**The model's generalization frontier is set exactly by the gate's coverage.** Where the executable gate applies climbing pressure, the model reaches the correct *general* predicate by discovering and reusing the verifier's own oracle (not by enumerating cases). Where the gate is blind, the model over-generalizes. The gate does not teach the predicate; it shapes the frontier by where it pushes. The model supplies the discovery; the gate supplies the direction and the boundary.

## The lift, step by step (codex's own words, line-cited)
1. **Abduces the general principle up front** — L4708: *"erased_ghost_value::<T> preserves T exactly, so when ghost code produces `!`, the erased call has type `!` and Rust marks following MIR unreachable… A general fix should keep the ghost dependencies but avoid introducing artificial divergence for erased code."* It names the XOR — artificial (ghost-erased) vs real divergence.
2. **Aims for generality, not the repro** — L5070: *"checking all constructors of erased_ghost_value so the fix applies to any erased expression with never type, not just the exact call form in the issue."*
3. **First implementation is NARROW — keyed on `!`** — L6960: *"when an erased ghost call has result type `!`, lower only its preserved dependency expressions and leave the synthetic never temporary unassigned."* `result type !` = `is_never()`. **This is exactly the ceiling every prompt arm stopped at** (chg=0–114, never general).
4. **The gate feeds non-`!` uninhabited cases** — across 281 case-check invocations, empty enums and recursive-uninhabited (`Wrap{A(Void)}`) cases that `is_never()` does not catch → `mishandles>0` → cannot reach `pass=true`.
5. **To climb, it discovers and reuses rustc's own inhabitedness oracle** — it grepped (L732 `rg "never|uninhabited|Diverge…"`), found the existing `lint_and_remove_uninhabited` code (L1714–1721) where rustc computes `ty_is_inhabited`, and generalized its predicate from `is_never()` → `!ty.is_inhabited_from(tcx, parent_module, typing_env)`. **This is the lift: narrow `!`-check → the verifier's own general query.** Confirmed by source (`ty_is_visibly_uninhabited`) + VDBG (projection `<u8 as Tr>::A` arrives normalized to `Void`, `uninhab=true`).

## The over-rejection is the SAME mechanism, not a separate flaw
rustc's pre-existing code handles `is_never()` specially for divergence — L884 *"only checks whether ty.is_never(). Here, we have full type…"*, L889 `if !ty.is_never() && output_is_inhabited`. The model replaced the narrow `is_never` discrimination with broad `is_inhabited_from` for *keeping* the edge. But **the gate never presented a genuine-divergence-preserve case** (its 2856-grammar has no "legit divergence with post-divergence linear use" on the preserve side), so there was **no climbing pressure on the second XOR arm.** Result: it keeps the edge for *all* visibly-uninhabited returns, including genuinely-diverging ones → over-rejects `t3`/`ho5` (both base-VERIFY sound; `#2501` verifies `t3`). The over-rejection is located precisely in the region the gate left blind. That is the mechanism predicting its own failure mode.

## Why prompts can't do this (the contrast)
Prompt-encoded methods (graph / minimal / neutral / siteenum / abduction / self-verifier) oscillate between narrow modes (clean dataset: chg=0 ↔ 114, never `pass=true`). They state the general principle but have no executable pressure forcing the `is_never → is_inhabited_from` generalization; resampling rattles them between narrow implementations. The gate converts the model's already-correct abduction (L4708) into a *directed climb* by making the non-`!` cases fail until the predicate generalizes. The model always *could* abduce; the gate is what made the abduction *load-bearing*.

## The sharp prediction (falsifiable — this is the next experiment)
If "generalization frontier = gate coverage" is the mechanism, then **closing the blind spot** (add a genuine-divergence-preserve shape to case-check's grammar) should apply pressure on the second arm and the model should **carve out `is_never`/divergence, making the `t3`/`ho5` over-rejection disappear.**
- **Confirmed** → the gate shapes the frontier; coverage is the design lever.
- **Model thrashes / can't** → the divergence arm needs information the model can't recover at that program point (e.g. distinguishing genuine `loop{}` from ghost-erasure requires Verus mode info the MIR layer lacks) → the XOR's second arm is intrinsically harder, also a clean finding.

## Evidentiary status
- Lift + over-rejection: reproducible on the forced-fresh, fingerprinted harness (`clean_dataset.jsonl`).
- Mechanism: demonstrated in the trace, not asserted (line cites above).
- Open (for the loop-vs-corpus decomposition, not for rate): C1 control — does the model reach `is_inhabited_from` from the labeled corpus alone, or does it require the executable loop? That isolates which half of the prosthesis carries the discovery.
