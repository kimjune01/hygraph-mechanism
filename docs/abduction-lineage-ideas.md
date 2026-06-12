# Abduction-tool lineage → ideas for the LLM-drives-an-externalized-abduction loop

*Compiled from a 4-way fan-out over the bi/tri-abduction tool lineage (Abductor/SpaceInvader,
Infer#, FootPatch, Gillian, Broom, HIP/SLEEK·S2, SLAC, SLAyer, Quiver) + the OSL theory.
Filtered for one question: what do 15 years of mechanized abduction teach us about getting a
SOTA LLM to produce a **general** fix to a verifier soundness bug, when the target predicate is
**XOR-shaped** and the model defaults to a monotone (narrow) approximation?*

## Our setting (the relevance filter)
- Bug: verus #2219. Ghost value of an uninhabited type → rustc prunes the post-call CFG edge →
  Verus skips the linearity check on `tracked` (affine) resources → a double-consume is accepted.
- Prompt arms that *encode the method* (hypothesis-graph, bi/tri-abduction spec) all failed (0/12+):
  the model **notates** the procedure but never **executes** the frame/anti-frame inference.
- The general fix is an **XOR / off-diagonal detector**: prune iff `(type uninhabited) ∧ ¬(ghost-erasure artifact)`
  — i.e. fire exactly where "rustc thinks uninhabited" and "actually non-returning" **disagree**.
  The model can *say* this and then writes a monotone proxy (key on the `erased_ghost_value` callee).
- Our move: `case-check`, a CLI that **externalizes** the coverage/abduction — enumerate a principled
  grammar of programs, run each through the verifier (judge), report mishandles; the LLM hill-climbs.
  Train signal = the tool; held-out eval = independent native-uninhabited probes (`enum Wrap{A(Void)}` …).

The lineage converges on **three architectural moves** and confirms our held-out worry is the real one.

---

## A. REPRESENTATION — make the fix-target two-sorted so the monotone special-case is *ill-typed*
*This is the deepest idea and the most direct attack on the XOR-tabulation problem.*

The whole reason the model "tabulates" (special-cases each grammar cell) instead of "representing"
(writing the XOR predicate) is that it's asked for **one undifferentiated condition**. Three tools
independently say: give the predicate **named, typed slots with directionality**, and the monotone
collapse becomes unrepresentable.

- **HIP/SLEEK · S2 second-order bi-abduction** abduces a *predicate*, not a formula, over a template
  with **unknown predicate variables** and two devices that prevent degeneracy: (i) **pre/post
  asymmetry** — pre-predicates may only be strengthened, post only weakened, so the inferred
  predicate cannot collapse to "always/never"; (ii) the **`#`-annotation** marking parameters as
  *instantiatable* vs *non-instantiatable* (back-pointers, continuations). Drop the annotation and S2
  synthesizes a trivially-FALSE/monotone precondition — *exactly our failure mode*.
- **SLAyer / Abductor footprint vs frame**: the fix predicate *is* an anti-frame/frame split. A value
  whose type *looks* uninhabited but is a **ghost-erasure artifact lives in the frame** (erased at
  runtime, never reached) → pruning its edge is unsound. The model emitted only the **footprint** side
  ("type uninhabited ⇒ prune") and never computed the **frame** (the not-touched, erased part).
- **OSL outcome assertion `φ ⊕ ψ`** (correctness ⊕ incorrectness): represent the target as **two
  outcomes**, not one predicate — "previously-unsound case must now be *rejected*" (under-approx) and
  "previously-sound cases still *verify*" (over-approx) — scored **separately**.

**STEAL → the two-slot fix template.** Represent the soundness condition as a predicate skeleton with
two named slots — `uninhabited?(τ)` and `ghost_erased?(v)` — where the second is **non-instantiatable /
frame-side** (the runtime never produces it). Hand the model this skeleton (a *sketch with typed
holes*), not a blank "write a general predicate." A fix that fills only the first slot is ill-typed
against the template. **Test the four-cell product** `{uninhabited,inhabited} × {ghost-erased,runtime-real}`:
the monotone special-case is correct on the diagonal and **fails off-diagonal** — demanding a non-empty,
passing **off-diagonal** converts vague "generality" into a concrete, checkable obligation.

---

## B. FEEDBACK — demand-driven, per-branch, one obligation at a time (not a flat mishandle list)
*Don't ask the model to hold the whole XOR; let the failing obligation be the gradient.*

- **Quiver (PLDI'24) — guided abductive inference *while verifying*.** Its engine (Argon) runs a
  **goal-directed** proof search: when a step needs a resource the context can't supply, it **records
  the missing resource as a hole and continues** — the accumulated holes *are* the inferred spec. The
  current verification obligation **is** the search heuristic; it only ever proposes "exactly what the
  proof needs next." The human gives a **sketch**; holes are filled **incrementally**, at point of need.
- **OSL tri-abduction.** Branching ≠ sequencing: both branches run from the same state, so bi-abduction
  (one anti-frame `M`, one frame `F`) is wrong. Tri-abduction infers **one shared `M` + two per-branch
  leftover frames `F₁,F₂`** in *one pass*, giving **non-monotone, branch-local** feedback ("which
  exclusive branch is broken and what each still needs") — the signal a XOR fix needs, and the one
  CEGAR's monotone "tighten one approximation" loop can't express.

**STEAL → demand-driven loop + a patch-sketch with two branch-holes.** After each failed `case-check`
run, surface the **single most-informative unmet obligation** (one failing cell + the branch it belongs
to), and have the model fill **one typed hole at a time**, rather than re-propose a whole predicate.
This is precisely the antidote to the method-encoding failure (notate-don't-execute): the tool executes
the composition; the model only discharges the next obligation.

---

## C. ARCHITECTURE — unsound-generate + sound-validate, and repair-as-query
*Our `case-check` is generator + judge; the lineage says the judge must also gate the patch, on the XOR criterion.*

- **Abductor PreGen/PostGen.** Abduction is deliberately **heuristic and unsound** (it even widens
  concrete heaps to `ls` unsoundly). The discipline that keeps it honest: a separate **sound forward
  re-execution (`PostGen`) filters** every candidate the generator (`PreGen`) proposed. *Keep the
  generator dumb and the filter sound* — exactly the "LLM proposes, verifier judges" split.
- **FootPatch (ICSE'18) — repair = frame inference run backwards as a matcher.** It forms a **Repair
  Query** (a Hoare triple with a hole, `{F∗P} ?C {F'∗Q}` = the desired *verdict transition*) and
  validates a candidate by **re-running the analyzer on the patched program** — accepting only if it
  removes the flagged report **without** breaking clean ones. Because the oracle is *static*, patches
  **cannot overfit to dynamic tests** (a structural anti-overfit defense). It also turns patching into
  **retrieval + substitution against a semantic query**, not free synthesis (sidesteps notate-don't-execute).

**STEAL → Repair-Query mode + flip-these-keep-those gate.** On a mishandle, emit the *desired
verdict-transition* as the query; after the model's edit, **re-run the entire grammar** and accept the
patch **iff** it flips exactly the mishandling cases and leaves every clean case unchanged. That gate
*is* the XOR ("change behavior exactly where uninhabited and non-returning disagree, nowhere else"),
encoded as a coverage check the model hill-climbs instead of a predicate it must hold. (We already added
the crash-gate; this generalizes it to the full flip-these-keep-those criterion.)

- **Infer# compositional summaries.** Per-procedure pre/post summaries analyzed **once, independent of
  callers**, then **recombined**. **STEAL:** make `case-check`'s output a **library of per-construct
  mishandle-summaries** (shape → {observed, expected} verdict) that recombine, and ask the model to fix
  **one construct-shape at a time**, letting compound cases be covered by composition — *bottom-up beats
  holding the whole inference at once*, the antidote to monotone-global collapse.

---

## D. A SIBLING TOOL — incorrectness/under-approximation to *discover* holes, with witnesses
*Our enumerate-and-check is over-approximate (a "mishandle" is a candidate). The discovery direction wants under-approximation.*

- **Gillian incorrectness bi-abduction / Exact SL.** Same engine does correctness and incorrectness;
  the only switch is whether the solver checks **validity** (over-approx, all-safe) or **satisfiability**
  (under-approx, *some* execution reaches the bad state). Under-approximation ⇒ **every reported hole
  carries an executable witness — zero false positives.**
- **Pulse-X / Incorrectness Separation Logic (O'Hearn et al.).** A bug is a **manifest error**: a real
  input + trace that crashes. **Dropping paths is free** (only risks false negatives, never false
  alarms) — Pulse's 20-vs-50 disjuncts: 3.1× faster, still 97% of bugs. License for an aggressive,
  incomplete, **search-toward-the-bug** finder. Works **backward from the failure** toward the exposing
  input (cf. Broom abducing the shape that triggers a leaf).

**STEAL → a `find-holes` sibling tool**, framed `[P] verifier(prog) [accepts ∧ ¬spec]`: search for an
under-approximate witness `(prog)` the verifier *accepts* but that *concretely violates* soundness.
Every report is a proof-of-unsoundness (no LLM confirmation needed), and path-dropping is a free
speed knob. This is the **breaker** we kept circling — and incorrectness logic is its formal basis.

---

## E. GRAMMAR COMPLETENESS — close under type-formers as a fixpoint; the off-diagonal cells
*The validity crux: a fix can pass a finite grammar yet miss an untested uninhabited form.*

- **SLAC (bi-abduction for arrays & lists).** Inhabitation of an aggregate is a **function of its parts
  + a former-specific rule** (product = all-fields, sum = some-variant, recursive = lfp). The sharp
  trap: SLAC's **empty array `Arr(t,t)`** is satisfiable though degenerate — the exact analog of
  **`[T; 0]` inhabited even when `T` is uninhabited**, a former that *flips* inhabitation status. Also
  "one type → many producers (seeds)": coverage = **type × producer** product.
- **S2 inductive predicate synthesis** derives base ∨ inductive-unfold definitions — inhabitation as a
  **least fixpoint over an unfolded recursive unknown**, exactly what `enum Wrap{A(Void)}`
  (uninhabited-by-recursion) needs; a finite table can't express it.

**STEAL → a fixpoint-closed generator.** Replace the hand list of types with **productive recursive
nonterminals + a fixpoint inhabitation judgment**, so the generator *itself* emits `Wrap{A(Void)}`,
mutually-recursive enums, **and** the status-flippers (`[T;0]`, zero-field struct, unit-variant enum).
"Passing implies generality" becomes the one checkable claim: *the generator is surjective onto
former-composition space, including the status-flip cells.* (This is exactly Fable's held-out gap:
both `case-check` and oracle T2 only have external-spec empty enums; the fixpoint generator closes it.)

---

## F. GENERALIZATION — the pattern is parametric, not Rust-only
- **Gillian** is a **language-parametric** core: define a memory model + instruction set, get
  verification + testing + bi-abduction *for free*; instantiated for JS **and** C. Empirical evidence
  that "externalized abductive coverage + judge" is a **pattern**, not a verus hack.

**STEAL → a parametric judge + grammar interface.** Factor `case-check` into (i) a `verdict =
accept|reject|crash` **judge adapter** and (ii) a language-parametric **type-former grammar**, so the
enumerate-judge-report loop retargets to Dafny / F* / Lean / flux by swapping only those two. Underwrites
the "if this works, it's domain-general" claim — bounded, as we said, by the existence of a sound judge.

---

## Concrete upgrades to `case-check` (prioritized)
1. **Two-slot fix sketch (A)** — hand the model a typed predicate skeleton (`uninhabited? ∧ ¬ghost_erased?`)
   with the frame-side slot non-instantiatable, + the **four-cell off-diagonal** as a required passing set.
   *Highest leverage: it's the actual test of "represent vs tabulate the XOR."*
2. **Flip-these-keep-those patch gate (C)** — generalize the crash-gate to: accept a patch iff it flips
   exactly the mishandling cases and changes no clean case (the XOR, externalized as the accept criterion).
3. **Fixpoint-closed grammar (E)** — generator emits recursively-uninhabited + status-flip forms itself;
   makes "passing ⇒ general" a surjectivity claim, and closes the held-out gap structurally.
4. **Demand-driven, one-obligation-at-a-time loop (B)** — surface the single next unmet cell + its branch,
   not a flat list; patch-sketch with two branch-holes (Quiver/tri-abduction).
5. **Per-construct mishandle-summaries that recombine (C/Infer#)** — fix one shape at a time, compose.
6. **`find-holes` incorrectness sibling (D)** — the witness-bearing breaker, `[P] verifier [accept ∧ ¬spec]`.
7. **Parametric judge+grammar split (F)** — for the cross-verifier generality claim.

## What this says about the *experiment* (not just the tool)
- The **two-slot sketch (1)** is the cleanest test of the headline question: *does externalizing the
  XOR get the model to **represent** it or only **tabulate** it?* Run it against the held-out native
  probes (`ho1 enum Wrap{A(Void)}`, `ho2` native struct-field, `ho4 [Void;1]`). Represent → rejects them;
  tabulate → still accepts them.
- The **discovery sibling (6)** is a *separate* experiment with its own clean payoff (LLM finds real
  soundness holes with witnesses) and its own theory (incorrectness logic), independent of whether the
  *fix* generalizes.
- OSL's **`correct ⊕ incorrect`** is the formal name for our held-out design: score the must-reject set
  and the must-verify set **separately**, so a band-aid (one polarity bought at the other's expense) is
  visible — which is exactly what the crash-gate + soundness-regression check now do.

## Sources
**Bi-abduction core / industrial:** [Compositional Shape Analysis by Bi-Abduction (POPL'09)](http://www0.cs.ucl.ac.uk/staff/p.ohearn/papers/popl09.pdf) · [JACM'11](https://www.cs.ox.ac.uk/people/hongseok.yang/paper/jacm11-biabduction-webversion.pdf) · [Abductor](http://www0.cs.ucl.ac.uk/staff/p.ohearn/abductor.html) · [Infer# (.NET blog)](https://devblogs.microsoft.com/dotnet/infer-interprocedural-memory-safety-analysis-for-c/)
**Repair:** [FootPatch (ICSE'18)](https://rijnard.com/pdfs/inferepair-icse-2018.pdf)
**Multi-lang / incorrectness:** [Gillian (arXiv 2001.05059)](https://arxiv.org/pdf/2001.05059) · [Gillian Part II (CAV'21)](https://giltho.github.io/publications/GillianCAV2021.pdf) · [Compositional SE for Correctness & Incorrectness (ECOOP'24)](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ECOOP.2024.25) · [Exact SL](https://www.cs.rhul.ac.uk/home/upac096/papers/incorrectness24.pdf) · [Incorrectness SL (ISL)](https://plv.mpi-sws.org/ISL/paper.pdf) · [Pulse-X](https://loc.bitbucket.io/pulse-x.pdf)
**Low-level / harness-free:** [Low-Level Bi-Abduction (Broom, arXiv 2205.02590)](https://arxiv.org/abs/2205.02590)
**Expressive / 2nd-order / data structures:** [S2 (CAV'14 TR)](https://loc.bitbucket.io/papers/s2-cav14.pdf) · [HIP/SLEEK](http://loris-5.d2.comp.nus.edu.sg/hip/) · [SLAC](https://www.jstage.jst.go.jp/article/jssst/41/1/41_1_50/_pdf) · [Brotherston array bi-abduction (CADE'17)](http://www0.cs.ucl.ac.uk/staff/J.Brotherston/CADE17/array_biabduction_SL.pdf) · [SLAyer (CAV'11)](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/201120CAV20SLAyer_20Memory20Safety20for20Systems-level20Code.pdf)
**Guided abduction / outcome logic:** [Quiver (PLDI'24)](https://dl.acm.org/doi/10.1145/3656413) · [project](https://plv.mpi-sws.org/quiver/) · [Outcome Separation Logic (OOPSLA'24, arXiv 2305.04842)](https://arxiv.org/abs/2305.04842)

*Note: Quiver is PLDI 2024 (not OOPSLA). OSL is OOPSLA 2024.*
