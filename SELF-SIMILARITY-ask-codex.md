# Is the hypothesis graph self-similar, or is that just cute self-reference?

Context: a mechanism/existence paper on the "hypothesis graph" (hygraph) — a typed,
persistent semantic memory for an inquiry. Nodes = a falsifiable hypothesis bound to a
world-facing trial (exact command + outcome), credence capped by reasoning mode
(abduction/deduction/induction). Edges = kills that name the next hypothesis. Soundness
invariant = every node replayable from its recorded trial by a stranger who doesn't trust
the author. Over a deterministic substrate it's effectively a CRDT (append-only nodes,
monotone kill/witness status).

The paper was built on bug-fixing (flux refinement type checker, etc.). Two findings forced
a reframe:
1. The capability "lift" (graph arm beats minimal arm) is minor/probabilistic and melting as
   models improve; run properly paired at gpt-5.5, the flux divergence did not reproduce.
2. A bug fix is not "discovery" by Sutton's standard anyway — it's specification-recovery
   (recovering human-intended behavior), not the production of new knowledge.

So we're demoting the lift and the Sutton-discharge, promoting auditability/accountability.

## The new claim to evaluate: SELF-SIMILARITY

A bug-fix inquiry is not the unit of analysis — it's one existential NODE in a higher-level
hygraph. The flux #1613 inquiry (19 nodes, terminal witness) is a single node ("the method
helps here") in a higher-level hygraph whose question is "does mechanized inquiry produce
accountable, checkable reasoning, and in what regime?" The levels nest by warrant-preserving
composition: the child graph discharges the parent node's kill condition; warrant flows up.

That higher-level hygraph IS the paper. Pilots are nodes (hypothesis: "graph lifts capability
here"; trial: the two-arm experiment; outcome; kill or witness). Nine pilots, eight nulls,
one divergence = a hypothesis graph over the meta-question, with the soundness invariant
holding because every pilot has committed receipts. The de-confound was a node the trajectory
classifier marked oscillatory -> split. The recursion is already in our worklog: "using the
investigate skill's own evidence-trajectory classifier to adjudicate the skill."

Three claimed consequences:
- **Discovery relocates to the right altitude.** A bug fix isn't discovery-class; the
  meta-question (the operating envelope of mechanized inquiry) is open and has no
  human-supplied target, and the paper-as-hygraph is discovering its answer (the boundaries,
  the CRDT property, the capability melt, the discovery-class ceiling). The discovery is the
  characterization, reached by running the method on itself.
- **Existence-vs-universal resolves by level-crossing.** A bug node proves existence (this
  trial passed). The universal one inquiry can't close (correct scope; "the method helps in
  regime R") is approached one level up by the perturbation coverage of many bug-nodes. Level
  N = existence; level N+1 = coverage-toward-universal.
- **It's a result, not a metaphor — but only because the meta-graph obeys the same invariant,
  and its violations are the same boundary recurring.** The paper-as-hygraph is a real hygraph
  iff its nodes replay for a stranger. Pilots that don't (an unpreserved prompt on pilot-08)
  are exactly the author-dependence boundary showing up one level up. Discounting pilot-08 was
  pruning a non-replayable node. The session's edits (prune pilot-08, split the oscillatory
  de-confound, kill the over-claimed lift) are the hygraph's own operations applied to itself.

## Questions — be direct, no preamble, no praise sandwich

1. Does the self-similarity claim hold, or is it cute self-reference dressed as structure?
   What is the strongest version, and where does it overreach?
2. Is relocating "discovery" to the meta-level a legitimate move or a dodge — does it actually
   escape the Sutton objection (spec-recovery isn't discovery), or just launder it up a level?
3. Does the recursion BOTTOM OUT, or is there an infinite-regress / "needs a meta-oracle"
   problem? At the top level, what plays the role of the deterministic trial/oracle that makes
   a node replayable? If the meta-graph's "trials" are experiments graded by human judgment,
   does the soundness invariant actually hold at the top, or does it degrade to the same
   author-trust the whole paper is trying to escape?
4. Is "the editing is methodeutics applied to itself" a real demonstration that the structure
   is load-bearing, or is it unfalsifiable (anything can be narrated as a hypothesis graph
   after the fact)? What would make it falsifiable?
5. Should self-similarity be the paper's central framing, a single section, or a footnote?
