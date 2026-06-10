# #1613 issue-comment draft (matches thread tone: technical, dialogic, their vocab, humble)

Framing rationale: the thread is an unresolved design debate (nilehmann: prophecies; ranjitjhala:
&mut-field semantics). We do NOT lead with "merge this." We contribute a concrete experiment that
sits in the design space nilehmann already named ("track the origin"), state the honest caveat,
and defer to their fold-machinery expertise on whether it's the right layer. PR mentioned as ready,
not pushed.

---

> Prophecies are one way but maybe there is something simpler.

Took a swing at the "something simpler" — as a datapoint, not an argument against prophecies.

It seems to hit @nilehmann's step 4/5 directly:

> 4. Fold the inner `&mut`. We must put a value whose type is `Slot[s]`, but we have `Slot[s']`
> 5. Fold the outer `&mut` ... it's already too late.

Right now `fold_local_ptrs` does step 4 by subtyping the post-call `Slot[s']` back against the old `Slot[s]`. I changed one case: if the `&mut` came from a field projection of an owned place, remember that origin and write `Slot[s']` back to the field, so the enclosing fold sees `s'` instead of the stale `s`. Mechanically it's a `borrows: Local -> Place` map plus that one branch.

Evidence it does something: @enjhnsn2's original #1613 program checks, an int-sort variant of it checks, a setter that *shrinks* `len` is still rejected, and the existing negative local-ptr tests still reject (full basic + with-deps suites pass).

The caveat is the part that matters: the field-projection case is a syntactic proxy for "there will be an enclosing fold that rechecks the invariant," and I don't have a proof the proxy is sound — I only tried a few escape shapes and they still reject. So this is either a real lightweight origin-tracking lane or just an approximation that happens to cover this example, and that's the call I can't make from outside the fold machinery.

Branch/PR and a writeup of the dead ends (e.g. just removing the `FoldLocal` check verifies the example but is unsound) are here: https://github.com/kimjune01/hygraph-mechanism/blob/flux-1613-trail-v1/pilots/08-flux-1613/graph_arm/HYPOTHESIS_GRAPH.md . I used LLM assistance to generate and prune hypotheses during the investigation; the unproven gate above is the part I'd want reviewed most skeptically.

---

## Notes (not for the comment)

- Vocabulary deliberately theirs: FoldLocal, unfold/fold, `s` vs `s'`, "track the origin",
  existential placement. Signals we read all 41 comments, not just the OP.
- Leads with nilehmann's origin-tracking hook -> positions the fix inside the live debate.
- Honest gate caveat is the dual-judge finding, surfaced to the exact people who can adjudicate it.
- Disclosure kept to one clause at the end (consistent with PR), framed as heads-up not apology.
- If reception is warm -> PR references this comment. If they say "prophecies are the way" -> the
  comment still stands as a useful negative/partial result, no face lost.
