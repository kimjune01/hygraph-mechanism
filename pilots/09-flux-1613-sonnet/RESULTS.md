# Pilot 09 — flux #1613 divergence across THREE model families

3-way oracle (VERIFY = passes verification, E0999 = rejected). Same base commit 68d61714,
same blind issue text, same toolchain, same oracle. Per model, two arms differing only in
methodology: minimal (mini-SWE-agent prompt) vs graph (investigate hypothesis-graph prompt).
GPT-5.5 = original pilot-08 (codex CLI). Sonnet = Claude-subagent harness. Composer-2.5 =
cursor-agent headless. Note the harness differs by model; the WITHIN-model min-vs-graph
differential is the clean signal, not cross-model absolute comparison.

| program            | base  | GPT5.5-min | GPT5.5-graph | Sonnet-min | Sonnet-graph | Composer-min | Composer-graph |
|--------------------|-------|------------|--------------|------------|--------------|--------------|----------------|
| T1 reported #1613  | E0999 | VERIFY     | VERIFY       | VERIFY     | VERIFY       | VERIFY       | VERIFY         |
| T2 int receipt     | E0999 | E0999      | VERIFY       | E0999      | VERIFY       | E0999        | E0999          |
| T3 unsound twin    | E0999 | E0999      | E0999        | VERIFY(!)  | E0999        | VERIFY(!)    | E0999          |

## What replicates, and what doesn't (honest reading)

**Universal: the minimal arm fails the same way on every model.** All three minimal arms
fix the reported case (T1) but produce an OVER-NARROW fix that fails the int-component
receipt (T2 E0999), by gating the repair on the presence of a `Sort::Func` field. Both
newer models (Sonnet, Composer) make that fix UNSOUND on top (T3 accepted): they skip/relax
the fold check for Func-sorted composites, which also lets the invalid len-shrinking twin
through. This failure mode is robust across GPT-5.5, Sonnet, and Composer-2.5.

**The graph methodology's benefit is capability-graded, not all-or-nothing:**
- **GPT-5.5 graph** and **Sonnet graph**: full rescue — general (T2 VERIFY) AND sound
  (T3 E0999). The divergence (graph beats minimal on T2) reproduces cleanly. n=2 families.
- **Composer-2.5 graph** (the weakest model): PARTIAL rescue. The methodology bought
  SOUNDNESS (minimal unsound -> graph sound, T3 E0999) but NOT GENERALITY (still T2 E0999).
  Composer's graph arm actually RAN the correct differential perturbations (int-only,
  two-int, identity-setter, changed-via-field, unsound-shrink) but mis-scoped the result:
  it deliberately Func-gated and labeled the valid int-component-change program (T2) as an
  "expected" failure / out of scope. The process executed; the judgment didn't reach the
  sort-agnostic root cause.

## Interpretation
The minimal-arm over-narrowness is model-independent — strong evidence it's a property of
the task+scaffold, not a single model's quirk. The graph methodology lifts the fix toward
general+sound, and the SIZE of that lift scales with model capability: strong models
(GPT-5.5, Sonnet) reach general+sound; the weakest model (Composer) gets only as far as
sound-but-still-narrow. The methodology is not magic on a weak model — it constrains the
search and catches the soundness hole, but cannot manufacture the diagnostic judgment the
strong models supply. That is a more defensible claim than "graph always wins": the
treatment helps monotonically, and how much depends on the generator.

## Caveats
- n=1 instance; 3 model families x 2 arms. Decisive on THIS bug, not a population rate.
- Harness confound across models (codex CLI vs Claude subagent vs cursor-agent). Within-model
  min-vs-graph is clean; cross-model absolute behavior is not.
- Compute asymmetry: graph arm runs more passes than minimal (inherent; scope stated).
- T2/T3 reconstructed locally and re-validated against the original GPT-5.5 patches
  (base E0999 / min E0999 / graph VERIFY) before grading any new arm.

## Artifacts (per arm: patch + scratch where applicable)
- sonnet_minimal.patch, sonnet_graph.patch, graph_scratch/
- composer_minimal.patch, composer_graph.patch, composer_graph_scratch/
- oracle/ : t1_issue1613.rs, t2_receipt_int.rs, t3_unsound_twin.rs, grade.sh

## Contamination (this round is clean, three independent reasons)
1. **Issue postdates cutoffs.** #1613 filed 2026-05-19 (~3 weeks before this run); for these
   generators that is almost certainly post-cutoff — they never saw the issue or its thread.
2. **No fix exists to memorize.** The only sort-agnostic fix is PR #1651 (kimjune01's own,
   opened 2026-06-10, UNMERGED). It is in no public corpus.
3. **The minimal arm is a built-in memorization probe.** If a model had the real fix latent in
   weights, the minimal "just fix it" arm — path of least resistance — would emit it. Instead
   every minimal arm (GPT-5.5, Sonnet, Composer, [Fable pending]) reaches for the WRONG,
   over-narrow Func-gate. A model regurgitating a memorized general fix would not reliably
   produce the narrower one. The divergence is methodology, not recall; the minimal arm's
   stubborn over-narrowness IS the control.
