# Hypothesis Graph

## H0 Observation

Reproducer: /tmp/p08g-scratch/reported.rs

Observed: fails with `error[E0999]: type invariant may not hold (when place is folded)` at `self.slot.set(0)`.

Constraint dump (`-Fdump-constraint=true`, `log/reported.{impl#1}-update.simp.fluxc`):

```text
forall self: loc, s: Container.
  (s.0.0 > 0) =>
    forall a0: loc.
      (0 < s.0.0) ~ Call at 20:9: 20:25
      forall a1: int. ((a1 = 0 || s.0.1(a1)) = s.0.1(a1)) ~ FoldLocal at 20:9: 20:25
```

H0 result [induction]: reported program fails because local pointer folding demands equality
between the callee-updated `Slot[s.len, |j| j == 0 || old(j)]` and the original `Slot[s]`.
This is stronger than the outer `Container` fold invariant, which only needs `s.len > 0`.

## H1 Competing Hypotheses

- H1a [abduction]: the defect is specific to function-valued abstract refinements (`int -> bool`).
- H1b [abduction]: the defect is any abstract refinement update through a mutable reference stored
  in a refined aggregate field, because local pointer folding uses the pre-call field type as an
  invariant bound.
- H1c [abduction]: the outer field invariant itself is the failing condition, not local pointer
  folding.
- H1d [abduction]: the nested `self.slot.set(...)` receiver shape is essential; direct `&mut Slot`
  calls should fail the same way.

Next perturbations: change one surface feature at a time: direct mutable argument, no-op setter,
scalar abstract update, no field invariant, and invalid invariant-breaking update.

## H2 Differential Narrowing Results

- P1 `direct_arg.rs` [induction]: before fix failed with `FoldLocal`; after fix verifies.
  Trajectory: convergent with local-pointer-bound hypothesis. Verdict: containing `Container`
  field is not essential to triggering the over-strong fold.
- P2 `noop_setter.rs` [induction]: verified before and after fix.
  Trajectory: divergent/kill for "any setter call" hypothesis. Verdict: mutation of the abstract
  refinement is load-bearing.
- P3 `scalar_grow.rs` [induction]: before fix failed with `FoldLocal`; after fix verifies.
  Trajectory: convergent. Verdict: function-valued abstract component is incidental; scalar
  abstract-index mutation through the same local pointer fold has the same root.
- P4 `no_field_invariant.rs` [induction]: after removing the callee length precondition, before fix
  still failed with the same `forall a. updated_hdl(a) = old_hdl(a)` `FoldLocal`; after fix verifies.
  Trajectory: convergent. Verdict: the outer field invariant is not the cause of the bad equality.
- P5 `invalid_shrink.rs` [induction]: before fix failed; after fix still fails with `Fold` at the
  outer container fold and note pointing at `slot.len > 0`.
  Trajectory: desired divergent soundness check. Verdict: relaxing local pointer folding did not
  accept an update that violates the repacked field invariant.
- P6 `post_visible.rs` [induction]: unusable probe; surface desugaring rejects `s.slot.get(j)` in
  that sort-literal position. Verdict: not evidence for/against the checker fix.

## H3 Root Cause

Root cause [deduction + induction]: `unfold_local_ptrs` converts an `&mut T` actual to a temporary
local pointer so it can be passed to a callee expecting `&strg T`. The callee's `ensures` updates
that temporary location. `fold_local_ptrs` then required the updated pointee type to subtype the
pre-call bound exactly (`T_after <: T_before`) before discarding the temporary. For abstract
refinement updates this emits equality of the old and new abstract index (e.g.
`forall a. (a == 0 || old(a)) == old(a)`), even when the only obligation needed to repack the
surrounding type is the original bound predicate (e.g. `slot.len > 0`).

## H4 Fix

Fix [deduction]: local pointer folding now checks the updated pointee against an existentially
packed version of the original mutable-reference bound. This preserves predicates from the bound
but does not require the old abstract index value. After the check, mutable-reference bounds in the
environment that match the original bound are rewritten to the updated pointee type, so later folds
validate the actual post-call state.

Post-fix observations [induction]: reported, direct_arg, noop_setter, scalar_grow, and
no_field_invariant verify. invalid_shrink is rejected at the outer fold with the expected
`slot.len > 0` note.
