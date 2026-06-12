# Boundaries of the hypothesis graph, and what it can inherit from the literature

## The object
The hypothesis graph (hygraph): a typed, persistent semantic memory for one inquiry.
- **Node** = a falsifiable hypothesis bound to a world-facing trial (exact command + observed
  outcome), credence capped by the reasoning mode that earned it (abduction = proposed/low,
  deduction = traced/high, induction = test-backed/moderate).
- **Edge** = a kill condition that, when it fires, names the next hypothesis (generate-edge-
  from-kill). Self-extending, no external controller.
- **Soundness invariant** = every node replayable from its recorded trial by a stranger who
  does not trust the author.
- Over a deterministic substrate it behaves as a CRDT (append-only nodes, monotone
  kill/witness status), so it composes as a conflict-free merge over a fixed immutable base.

It currently runs on code (refinement type checkers, etc.), where trials are cheap,
deterministic, perturbable.

## Already cited (don't just re-suggest these)
- Truth-maintenance systems (de Kleer 1986) — dependency structure, mechanical retraction.
- Abstract argumentation (Dung 1995) — attack relations as first-class.
- Sequential testing / e-values (Wald 1947; Vovk & Wang 2021) — anytime-valid stopping.
- Bayesian networks / causal DAGs (Pearl 1988/2009) — typed nodes, directed edges (we keep
  the topology, drop the probabilistic semantics).
- Bi-abduction / separation logic (Calcagno 2009; O'Hearn 2019) — frame inference.
- Soar/ACT-R memory typology (Laird; CoALA, Sumers 2024) — the smem/pmem/epmem slots.
- Delta debugging (Zeller & Hildebrandt 2002) — mechanical perturbation as inference.

## A boundary map we've drafted (extend, correct, or break it)
1. **Substrate**: needs reproducible + deterministic + perturbable + reversible + cheap-enough
   trials. Knock out determinism -> CRDT/replay fails; perturbability -> degrades to a
   plausibility tree; reversibility -> can't replay; cheapness -> economics break.
2. **Epistemic reach**: proves EXISTENCE (this trial passed), not universals (correct scope is
   a quantifier over an open set it can't close — it only raises coverage by perturbation). It
   HOLDS and TESTS variation but does not GENERATE it (that's the model's abduction).
   Binary-verdict native; graded/probabilistic evidence needs machinery it dropped. Falsifiable
   fragment only — design judgment/taste can't be a node.
3. **Trajectory/termination**: clean on convergent; oscillatory means the hypothesis is too
   coarse (must split); chaotic can't terminate. Completeness boundary (possibly fundamental,
   Gödel/halting-flavored): everything ATTESTED is checkable, but nothing guarantees everything
   RELEVANT is attested — "have all relevant hypotheses been considered?" looks undecidable in
   general.
4. **Provenance/durability**: replay sound only if a node carries its FULL reconstitution
   (we have nodes tagged "(operator)" that a stranger can't reconstruct — author-dependence
   caught in the act). Half-life: replay inherits its apparatus's lifespan. Composition clean
   only over a shared immutable base.
5. **Topology/scale**: degenerates to a checklist if kills don't NAME successors (needs path-
   dependence to earn "graph"). Flat markdown queryable only while it fits a context window;
   cross-instance retrieval/dedup unbuilt.

## Questions — be direct, no preamble, no praise sandwich
1. **Boundaries.** Where is this map wrong, thin, or missing a cluster? In particular: are
   there genuine IMPOSSIBILITY results (not just limitations) — e.g. is the completeness
   boundary (attested vs relevant) actually undecidable, and is there a clean way to state it?
   Is there a boundary in the TYPING itself (are abduction/deduction/induction the right or a
   complete set of node types for this structure)?
2. **Inheritance.** For each capability the hygraph wants, name the mature literature that
   already solved a version, and say precisely WHAT TRANSFERS and WHAT BREAKS (the failure mode
   we keep hitting is importing truth-by-assertion semantics from knowledge graphs, when a
   hygraph node is a claim-under-trial, not an asserted fact):
   - composition/merge; provenance/replay; querying the smem; next-hypothesis generation
     (where to look next); termination/stopping; credence/belief semantics; cross-instance
     accumulation & generalization; contradiction/conflict handling; scale/topology.
   Go beyond the already-cited list. Flag any borrow that would import the wrong semantics.
3. If you had to name the ONE boundary that most constrains what hypothesis graphs can become,
   and the ONE body of literature most underexploited here, what are they?
