# PR draft — flux-rs/flux #1613 (flux house style)

Pattern-matched against recent merged flux PRs (#1638/#1639/#1637/#1633): short, dev-to-dev,
a mechanism paragraph, a tight bullet list, a how-to-test note. No formal essay. Conventions cited
(#1632 unord, #1633 IndexMap-for-determinism) to show we read the repo. Disclosure built in as a
provenance offer, not a disclaimer. No CONTRIBUTING.md / PR template / AI policy exists in the repo,
so nothing is required; we disclose anyway on academic-etiquette + thesis grounds.

---

**Title:** Propagate callee post-state when folding mutable field borrows (#1613)

---

Fixes #1613. Folding a `&mut` field back after a setter call re-proved the post-call type against
the field's *original* bound, so a setter that changes an abstract refinement could never close the
fold even when the field invariant it has to preserve was untouched. In the issue, `set(0)` rewrites
`hdl`, and `fold_local_ptrs` then asks the new `Slot` to be a subtype of the old
`{Slot[slot] | slot.len > 0}` bound, which forces the new `hdl` to equal the old one. Hence `E0999`
on a program whose only obligation is `slot.len > 0`, which `set` never touches.

This records where a mutable borrow came from and, when the temporary local pointer is folded,
writes the callee's post-state back into the borrowed place instead of re-checking it against the
stale bound. The enclosing struct then folds normally and the field invariant is checked against the
actual post-state.

A couple of things I ruled out:

- Just dropping the `FoldLocal` subtyping check makes #1613 pass but is unsound: a setter that
  shrinks `len` to `0` then verifies under `slot.len > 0`.
- Propagating for *every* `&mut` argument regresses `neg/surface/local_ptr00.rs` (a plain
  `&mut i32{v <= 10}` handed to a strong incrementer must stay rejected). A bare `&mut` has no
  enclosing place to re-fold, so it still needs the subtyping obligation.

So the write-back only fires when the borrow goes through a field projection (`has_field_projection`);
plain mutable refs keep the original check. The new `borrows` map is an `UnordMap` to match
`local_names` in the same file and the recent unord/IndexMap-for-determinism moves (#1632, #1633).

Tests: `pos/abstract_refinements/issue-1613.rs` (the reported program plus an int-sort variant of
the same shape, both verify) and `neg/abstract_refinements/issue-1613.rs` (a setter that drops `len`
to `0`, still rejected). `cargo xtask test` passes basic + with-deps with no regressions.

Provenance: the diagnosis and the fix were both produced by an automated hypothesis-graph agent
(perturb, classify the trajectory, follow the kill condition). I did not hand-verify the proof or
hand-write the patch; the only manual edit was conforming the new map to `UnordMap`. What backs it
is all machine-checkable and rerunnable: the recorded trail (including the constraint dump that
located the `FoldLocal` obligation and the two dead ends above), an independent pair of receipts
(a sort-varied positive that a narrower fix rejects, and an unsound `len`-shrinking twin that must
stay rejected), and `cargo xtask test`. Trail here: https://github.com/kimjune01/hygraph-mechanism/blob/flux-1613-trail-v1/pilots/08-flux-1613/graph_arm/HYPOTHESIS_GRAPH.md . I'm the submitter, not the
author of the reasoning, and happy to reshape the borrow-origin tracking if you'd structure it
differently.

---

## Open items before push (ours, not PR body)

- Publish a clean `HYPOTHESIS_GRAPH.md` for the `<HG link>` (gist or public branch). The graph is
  pure #1613 diagnosis (H0-H24); H22's "competing fix gated on Sort::Func" is the only oblique
  reference to our internal A/B and can stay or be softened to "a narrower shape-gated fix."
- Fold the int-sort variant into the committed `pos/.../issue-1613.rs` as a permanent generality
  fence (it is the receipt that stops a future narrower patch from regressing the general behavior).
- Commit source diff + the two `issue-1613` tests only; exclude scratch `repro*.rs`.
- Confirm final wording, then fork -> branch -> commit -> push -> PR as kimjune01.
