# Attestation Displacing Trust: An Existence Proof

The durable result of the hypothesis-graph experiment is not that the graph won once. It is that
the win was knowable without trusting the thing that produced it. That is the finding worth keeping.

## The claim under test

A minimal agent and a hypothesis-graph agent, both driven by the same model (codex GPT-5.5),
same single-agent loop, same box, no oracle access, identical settings. The only variable is the
method: a linear bash loop versus a perturb-and-measure investigation that emits a graph. The
question was narrow and falsifiable. Does the graph ever produce a materially better, still-sound
fix than the minimal agent, on a bug where the minimal agent already passes every objective test?

Eight instances said no. The ninth, flux #1613, said yes, and said it cleanly.

## What happened on flux #1613

flux #1613 is an open refinement-type-checker bug with 41 comments and no maintainer fix. Both
agents produced a patch that verifies the reported program and passes the full compiletest suite
with zero failures. By every test the project ships, both fixes are done.

They are not the same fix. The minimal agent gated its repair on a shape coincidence: it fires
only when an ADT carries a function-sort field. The graph agent dumped the solver constraints,
located the real obligation as a `FoldLocal` equality at the call site, and repaired that:
it tracks the origin of a mutable borrow through a field projection and writes the callee's
post-state back to the borrowed place. The first fix is keyed to an incidental feature of the
example. The second is keyed to the cause.

The difference is invisible to the suite and visible to a receipt. Construct a program with the
same structure but plain integer refinements instead of a function-sort field. It is valid by the
issue's own accepted argument. The graph agent's fix verifies it. The minimal agent's fix rejects
it with the original error. Both fixes still reject an unsound twin where the setter shrinks the
length past its invariant, so the minimal fix is not broken. It is over-narrow, a confident false
positive that the project's own tests could never catch.

## The turn: the win is not the point

A better fix is a result. It is not the result. If the only output were "the graph's patch is
better, trust me," we would have replaced one unverifiable assertion with another. The minimal
agent already gave us a fluent, suite-green, wrong answer. A second fluent answer, even a correct
one, does not advance the epistemics. It just moves the coin to the other hand.

What advances the epistemics is that the graph agent did not ask to be believed. It emitted
nineteen nodes, and each node is a trial: a hypothesis, a perturbation stated as an exact command,
the observed output, and the edge the result generates. The structure is built to be checked, not
admired.

So I checked it. On a clean base build I controlled, I replayed the load-bearing nodes. The
differential that localized the bug reproduced: the original program errors, the refinement-
preserving variant verifies, the scalar variant verifies, the direct strong-reference variant
verifies. The deep node reproduced: the solver dump shows the `FoldLocal` tag at the exact source
location the graph named. The graph even recorded three of its own corrections, and each correction
is itself a replayable trial: a moment where it tested the stale binary by mistake, a first fix it
proved unsound with its own probe, an over-broad fix the suite caught breaking an unrelated test.
Nothing in the trail required my trust. Everything in it invited my replay.

## Attestation displacing trust

This is the existential reading of the existence proof. An agent is not a witness whose word we
weigh. It is a builder of truth, and the unit of what it builds is the attestation: a claim bound
to a procedure that reconstitutes it. The minimal agent offers a verdict. The graph agent offers a
ledger. You audit a ledger line by line, and at no point do you extend credit.

The asymmetry is the engine. A fabricated reasoning trace is expensive to sustain, because every
fabricated node has to survive a replay that the author does not control. A confident narrative is
cheap to invent, because nothing in it is pinned to a procedure. The minimal agent's over-narrow
fix is the cheap kind: it reads as finished and is wrong, and reading it harder never reveals the
flaw. The receipt reveals it in one command. The graph's diagnosis is the expensive kind: it
costs nineteen pinned trials, and that cost is exactly what makes it checkable. Verification is
not a tax on the method. It is the method.

## Reliability is the same epistemics, accumulated

"It always will" sounds like a stronger claim than "it did once," and it is, but it is not a
different kind of claim. Reliability is not a leap from one instance to a faith in all instances.
It is the same attestation discipline run more times, each line item verified, until the verified
set is large enough to act on. The graph makes reliability a measurable property rather than a
hope, because the same structure that lets you audit one fix lets you audit a thousand. You never
arrive at trust. You arrive at a body of attestations too large and too redundant to doubt, which
is a different and better place to stand.

This also tells you what to do when an agent is wrong, which it will be. A trusted oracle that
fails is a betrayal and leaves you nothing. A truth-builder that fails leaves a trail, and the
trail names the failed node. The minimal agent's failure is silent until a receipt finds it. The
graph agent's failures are written down by the graph agent, in advance, as the kills that generate
its next edge. One method hides its errors inside confidence. The other spends its errors as fuel.

## What this does and does not establish

One instance. The proof is existential, not statistical: there exists a bug where the method
produces a materially better and still-sound fix than a strong minimal agent on the same model,
and produces it with reasoning auditable at arbitrary depth. It does not establish a rate. It does
not establish that the graph wins on easy bugs, where the model's own reach already suffices and
the pipeline's triage routes the work past the graph anyway. The honest headline is not "the graph
is super effective." It is "the graph's advantage is real, it lives in correctness that oracles
cannot see, and it is the kind of advantage you can confirm yourself instead of taking on faith."

The faith part is the part we retired. That is the proof.

## Provenance

- Instance: flux-rs/flux #1613 (open, 41 comments, maintainer-stuck).
- Arms: codex GPT-5.5, single-agent, no-gate, identical settings; methodology is the only variable.
- Graph fix: `crates/flux-refineck/{checker.rs,type_env.rs,type_env/place_ty.rs}`, 82+/20-, root
  cause = `FoldLocal` obligation, repair = field-origin borrow tracking with post-state write-back.
- Minimal fix: `needs_tracked_reborrow` gated on a `Sort::Func` field (over-narrow).
- Discriminator: `receipt_int.rs` (graph VERIFY, minimal E0999); soundness twin `receipt_unsound.rs`
  (both reject); full compiletest suite 0 failed on both.
- Audit: load-bearing nodes (H2, H4, H5, H6, H7) replayed on a pristine base build; all reproduced.
- Artifacts: `pilots/08-flux-1613.md` (RESOLUTION), `pilots/08-flux-1613/graph_arm/HYPOTHESIS_GRAPH.md`
  (19 nodes), `graph_arm/graph_arm_src.patch`, `graph_arm/repro*.rs`, `tools/divergence_oracle.sh`.
- Sibling result: `METHODOLOGY-preregistration.md` (the deductive rung that this run finally fired).
