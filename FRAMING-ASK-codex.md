# Framing ask: how to present the de-confound result in a mechanism paper

This is a **mechanism / existence paper**, not a statistical-significance paper. We are
NOT trying to prove the hypothesis graph is a better way of doing things in general. We are
trying to show: it works *in this way*, it *lifted capability in this one instance*, and we
can see *exactly how and what caused the lift*. n is tiny by design and that is fine for an
existence/mechanism claim. We do not want to wade into power, effect sizes, CIs, or "is the
rate real" — that machinery is the wrong register for this paper.

We need a framing for one finding that, read naively, looks like it weakens the claim, but
in a mechanism paper actually sharpens it. We want the prose framing, not a stats verdict.

## The setup (what the paper claims)

flux-rs/flux #1613: an open, maintainer-stuck bug in a refinement type checker. Same model,
same loop, methodology the only variable. Two arms:
- **minimal** (mini-SWE-agent prompt, no diagnosis artifact)
- **graph** (the methodeutic `inquire` stage produces a hypothesis graph)

The minimal arm produces an OVER-NARROW fix: it gates the repair on the reported example's
incidental feature (the mutated field carries a *function sort* rather than a plain `int`),
so it passes the reported program and the full 965-test suite but fails an off-suite
"soundness twin" receipt (a structurally identical valid program with int components). The
graph arm repairs the root cause (sort-agnostic) and verifies the twin. The advantage is
correctness *invisible to every test the project ships*, settled only by an off-suite
receipt. This failure mode is robust: the minimal arm fails the same way across GPT-5.5,
Sonnet, and Composer-2.5.

## The finding we need to frame honestly

The original flux graph PROMPT named the discriminating axis as the first "illustrative
dimension to isolate": *"the sort of the refinement component being updated (an abstract
function sort vs a plain int component)."* That is the exact axis separating the narrow fix
from the general one. So the prompt partly handed the agent the answer key.

We de-confounded: reran the SAME model (Sonnet) with the axis REMOVED from the prompt
(generic "which features are incidental, vary one at a time" guidance only). Three draws,
graded by the same off-suite oracle:
- draw #1: general + sound (DIVERGE) — reached the sort-agnostic fix with NO hint
- draw #2: over-narrow (NULL) — gated on `Sort::Func`
- draw #3: over-narrow (NULL) — gated on lambda presence

So de-biased: ~1/3 general. We are calling the trajectory OSCILLATORY (two modes: de-anchored
-> general; anchored -> narrow). NOT pure leakage (draw #1 reached general unaided), NOT
deterministic (naming the axis inflated the apparent rate toward 1).

Separately, a cross-repo instance (Verus #2427) NULLED: both arms narrow, because the graph
arm's perturbation set never spanned the discriminating axis (it varied within "closures",
never closure-vs-FnDef). Lesson stated in the repo: *the graph machinery is not the active
ingredient; the perturbation axis is. The graph lifts capability only when its perturbation
set spans the discriminating dimension.*

## The question for you

Given this is a mechanism/existence paper, what is the cleanest, most honest framing that:

1. Keeps the existence/mechanism claim intact (draw #1: the methodology de-anchored and
   reached the general fix unaided — we can see the exact node where it did).
2. Folds the prompt-leakage de-confound in as a SHARPENING (we can see exactly what caused
   the lift: the perturbation set spanning the discriminating axis) rather than as a
   statistical retreat.
3. Uses the Verus null as the boundary condition that makes the mechanism precise (it tells
   us when the lift will NOT happen), not as a refutation.
4. Avoids statsig register entirely — no rate-pinning, no "is 1/3 significant".

Specifically: what should replace the paper's current sentences
- "the split is identical, one bug now witnessed on two independent models"
- "the advantage tracks the methodology, not the model"
What is the right verb/scope for the lift claim? And how should we present the ~1/3 de-biased
result so a hostile reader sees it as mechanistic honesty (we found and named our own
confound) rather than as the result falling apart?

Give a concrete suggested framing/paragraph, what to cut, what to keep, and the single
sharpest sentence the result can honestly support.
