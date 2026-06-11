# Adversarial review request — de-biased re-run of the "hypothesis-graph vs minimal" debugging probe

You are an adversarial methodologist. No roleplay, no praise. Find the holes. Be concrete.

## Background
A prior result ("pilot-08") claimed a DIVERGENCE on flux #1613 (a refinement-type-checker bug): a "minimal" debugging prompt produced an OVER-NARROW fix while a "hypothesis-graph" prompt produced a GENERAL+SOUND fix, same model (codex GPT-5.5). It was billed as the project's first clean existence case.

We discovered the pilot-08 GRAPH prompt likely NAMED the discriminating axis (the leaky prompt told the agent which feature to vary). A later de-confound on a different model (Sonnet) showed the divergence dropped to ~1/3 and oscillatory once the axis-naming was removed. The original pilot-08 prompt was never preserved, so its cleanliness was an assumption. We are now re-running pilot-08 PROPERLY and adding a cross-repo instance.

## Design (both instances)
- Within-model A/B. Same model (codex GPT-5.5), same reasoning effort (medium), same sandbox/harness. ONLY the prompt differs: minimal vs de-biased graph. Both prompts are AXIS-NEUTRAL (leakage-checked: neither names the discriminating dimension; the graph prompt gives generic "which surface features are incidental vs load-bearing" de-anchoring guidance only).
- Three-way behavioral oracle per instance, VALIDATED against the real maintainer patches (base / narrow / general) before running arms.
- Integrity: repos scrubbed so the real fix is unreachable from the base (git history/branches/origin removed, gc-pruned; verified `git show <fixSHA>` fails). Full-log audit of every arm for git-history/answer-key/network access — all CLEAN so far.

## Instance A — flux #1613 (composite-sort abstract-refinement setter; FALSE-POSITIVE bug: base wrongly REJECTS a valid program)
Oracle: T1 reported program (valid, should VERIFY), T2 int-component receipt (valid, should VERIFY — the DISCRIMINATOR: over-narrow fix rejects it), T3 unsound len-shrink twin (invalid, must be rejected E0999).
Validated: base T1 E0999/T2 E0999/T3 E0999; real narrow patch T2 E0999; real general patch T2 VERIFY.
Results so far (de-biased, GPT-5.5, paired draws):
- graph: draw1 general+sound, draw2 general+sound, draw3 general+sound  (3/3 general)
- minimal: draw1 general+sound, draw2 OVER-NARROW (T2 E0999), draw3 pending  (1/2 general)
(draw 4 of both still pending)

## Instance B — verus #2219 (ghost-! CFG-pruning bypasses linearity check; SOUNDNESS bug: base wrongly ACCEPTS an invalid double-consume)
Maintainer-certified narrow->general: PR #2230 fixed the `!` case (narrow); PR #2501 generalized to "other uninhabited types" (its own body: "overly conservative because there might be other uninhabited types").
Oracle: T1 reported `!` repro (invalid, must REJECT), T2 ghost EMPTY-ENUM twin (invalid, must REJECT — the DISCRIMINATOR), T3 legit tracked-! divergence (valid, must VERIFY).
Validated against real patches: base T1 VERIFY(bug)/T2 VERIFY(bug)/T3 VERIFY; narrow #2230 T1 REJECT/T2 VERIFY(over-narrow)/T3 VERIFY; general #2501 T1 REJECT/T2 REJECT/T3 VERIFY.
Results so far (de-biased, GPT-5.5, paired draws):
- draw1: graph OVER-NARROW (T1 REJECT/T2 VERIFY), minimal OVER-NARROW (same). BOTH narrow — no divergence.
- Mechanism: the graph arm tested `!` vs NON-uninhabited (concluded "! is load-bearing") but NEVER tested `!` vs another uninhabited type (no empty-enum probe). So it shipped a `!`-specific fix == the maintainers' own narrow #2230. The discriminating dimension was not in its perturbation set.
- graph draws 2-3 + minimal draw 2 pending.

## Questions
1. Does this de-biased paired design validly test whether pilot-08's divergence was a prompt-leakage artifact? What would still confound it?
2. Emerging pattern: flux = graph reliably general / minimal oscillates general<->narrow (probabilistic lift); verus = both narrow (graph's perturbation set missed the discriminating dim). Is "graph raises P(general) above minimal" a defensible claim from this, or not yet? What sample size / what additional control is the minimum to claim it honestly?
3. The two instances fail to diverge for OPPOSITE reasons (flux: bug below capability edge, model reaches general either way on most draws; verus: discriminating dim not perturbed). Is that a coherent "capability-edge" story or post-hoc rationalization? How would you falsify it?
4. The verus null: is it informative (methodology genuinely doesn't reliably surface the right perturbation) or vacuous (one unlucky draw)? How many graph draws before the verus null means something?
5. Given all this, state the most defensible claim the project can make, and the claim it CANNOT make. Be blunt about whether removing the leak has effectively killed the original headline.
