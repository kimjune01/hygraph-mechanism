# Inherited discipline: what the Pro run and audit cost, and what each lesson becomes here

These lessons were paid for in a week and ~$1,000 on
[SWE-bench Pro](https://github.com/kimjune01/swebench-pro): the
[*How Not to Run SWE-bench Pro*](https://june.kim/how-not-to-run-swebench-pro)
field card, the [*Precisely Wrong*](https://june.kim/type-iii-error) Type III
post, and the [determinacy audit](https://github.com/kimjune01/swebench-pro-audit).
This doc translates each into the mechanism-paper regime (see [`../README.md`](../README.md)).
Some transfer verbatim, some change form, two become new guards, a few reverse.

## The load-bearing inheritance: you can't bootstrap the oracle you don't have

On four hard Pro losses, codex wrote its own check from the prose and stopped when
it went green. It went **green 4/4; the official grader failed all 4.** A
self-authored check is not an independent oracle.

**Here:** this is exactly why the harness's shipped test is not an oracle until it
merges. Pre-merge it is self-authored (the agent wrote the fix and the test). The
**merge is the only independent signal** in a regime with no pre-existing oracle.
Already folded into the README; it is the spine of the grading design.

## New guard 1: the Type III trap, one level up (am I measuring the mechanism or an easier proxy?)

The whole reason this repo exists is a Type III error: a precise answer to the
wrong question. *Precisely Wrong* names the failure mode and *the rigor made it
worse* (variance driven to zero around a biased target). The mechanism paper can
commit the same error in miniature.

**The confound:** "craft + graph beats craft-only" does not by itself show the
**typed inquiry** helped. The graph might help craft simply by being a structured
**summary** of the codebase, and any prose notes of equal length would do the
same. The Pro paper already flagged this (graph-vs-summary, deferred) and its
prompt ablation found the methodeutic vocabulary **inert** (M ≈ G ≈ T). So
"the graph is load-bearing" and "the typed methodeutic structure specifically is
load-bearing" are **two different claims**.

**The discipline:**
- The existence claim we make is the narrow one: *this graph artifact is
  load-bearing* (with vs without). That is an honest existence proof and the
  default scope.
- The stronger claim (*the typed structure beats generic notes*) requires a
  **third arm**: `craft( symptom + test + equal-length generic notes )`. If graph
  ≈ notes, the mechanism is "having notes," not methodeutics, and we say so. If
  graph beats notes, the typed structure earned it.
- Do not let "the graph helped" silently inflate into "methodeutics helped." That
  substitution is the Type III error in this paper's clothing.

## New guard 2: the flat-graph negative control (specificity is harder to fake than magnitude)

The audit's strongest move was specificity: effects appearing only where the
mechanism predicts, with a **symmetric advocate pass recovering none** of the
determined cases (12 refuted negative controls). The Pro paper made the same
argument (perturbation effect on underdetermined causes, near-zero on determined).

**Here, the control is free and built in.** Some persisted graphs are **flat**
(single-node, no diagnosis); some **branch** (rivals, kills, perturbations). The
mechanism predicts:
- **branchy graph → gap** (craft+graph beats craft-only),
- **flat graph → no gap** (nothing was diagnosed, so the graph can't be
  load-bearing).

Run both. If flat graphs **also** produce a gap, then something other than
diagnosis is driving the result (the notes confound, contamination, or an
instrument bug), and the whole claim is suspect. The result is only trustworthy if
**the gap tracks topology.** That specificity is the signature that survives a
skeptic; a uniform gap does not.

## New guard 3: the graph is the treatment, so pin the generator's cutoff

The mechanism claim is differential (craft-model contamination cancels across
arms), but the **graph is given only to the with-arm** — it is the treatment, not a
shared covariate. So generator contamination does **not** cancel: a generator whose
cutoff postdates the fix can leak a memorized solution into the graph, and "graph
helps" becomes "the generator recalled the answer." Because the conclusion is
invariant to *when* the graph was made (the skill reproduces it), we regenerate
freely — but only with a model whose cutoff **predates the issue** (Opus 4.7 /
Sonnet 4.5). This is the one place "regenerate now" is not free.

(Corollary: the **pre-submission snapshot** guard below applies only if you reuse a
*historical* graph; regenerating fresh sidesteps reinvestigate-leak entirely.)

## Capture and grading discipline (transfers directly)

- **Capture source only.** Each ablation arm's diff is stripped of test files,
  build/runtime blobs, and oversized hunks before grading. Critically, **an arm
  must not be allowed to edit the merge-certified gold test** — that is the Pro
  "capture leak" (test edits in the graded diff) and it would let an arm game the
  oracle. Grade against the **fixed** merged test.
- **The verdict is the gold test on a fresh reconstructed checkout**, not the
  harness's internal gate. The internal gate is a **stop signal allowed to lie**;
  it never decides the existence case.
- **No oracle in the input.** The arm sees the symptom only. It must not see the
  gold test body, and the with-arm gets the **as-of-first-PR** graph (no
  reinvestigate / post-merge nodes). Both are oracle-leak vectors in new clothes.

## Spend $0 before tokens, and confirm the instrument moved (the A2 sentinel)

- **Gold-grade every candidate first, free.** For each instance, confirm the
  merged test is **red at the parent commit and green on the gold fix** through the
  adapter before any ablation runs. A candidate whose gold does not red/green
  cleanly is a bad golden (see exclusions) and never enters the run.
- **Confirm the knob actually changes behavior.** A Pro review arm clean-stopped
  35 runs on a sentinel that matched the prompt's own echo; 13 real findings were
  discarded and it was nearly reported. Before trusting the ablation: verify
  craft-only and craft+graph **actually differ downstream** (the graph is really
  injected, the arm really reads it). An experiment that runs clean and changes
  nothing is the most expensive kind of nothing.

## Two-tier honesty and hostile-reader reproducibility (from the audit)

- **Tier the cases.** Tier 1 (mechanical spine, no buy-in): craft-only fails the
  merged gold test, craft+graph passes, both graded on a fresh checkout against the
  fixed test. A hostile reader reproduces from committed artifacts and has nothing
  to argue. Tier 2 (needs judgment): the graph shows "real" diagnostic work. Lead
  with Tier 1.
- **Commit every receipt:** parent commit hash, the merged gold test, the
  as-of-first-PR graph, both arms' source-only diffs, the per-arm grade. Verdicts
  must be re-derivable, like the audit's.
- **Adversarial verification.** Have an independent cross-family model try to
  **refute** each Tier-1 case (default to refuted): is craft-only's failure
  genuine, or an infra artifact, or a different-but-correct fix the narrow test
  rejected? Only survivors are claimed. If any judgment is involved, report the
  agreement floor (the audit's κ = 0.52, all disagreement skeptic-stricter).

## Predeclare exclusions and infra fault classes (no re-roll lever)

- **KNOWN_BAD, frozen before the run.** Some merged PRs are bad goldens: docs/typo
  fixes with no diagnosis, trivial one-liners, rubber-stamp merges, or a shipped
  test that does not actually capture the bug (the audit's KNOWN_MISMATCH shape:
  the test grades something other than the stated issue). Freeze the excluded list
  with reasons before grading; do not let exclusions become post-hoc filtering on
  results already seen.
- **Predeclare the infra fault class with invariants** (auth death, build failure,
  OOM, sub-90s zero-diff) **before any re-dispatch lands**, exactly as the
  `auth_storm` class was committed the day it first appeared. A non-empty arm that
  graded "fail" is a real loss no matter how we feel about it. Otherwise "that one
  was infra" becomes a knife applied to losses we dislike, and an honest run
  becomes a curated one.

## What reverses or no longer applies

- **No leaderboard framing.** Pro's "you rebuilt the harness, there's no slot to
  win" lesson dissolves: this is a mechanism paper, not a ranking. Do not gesture
  at a resolve rate or a model comparison. Existence cases only.
- **Contamination is satisfied by construction, not audited away.** Pro's "the
  public split is contaminated, your number is an audition" reverses in our favor:
  the deployment fixes are post-cutoff and certifiably novel, and the mechanism
  claim is **differential** (same model both arms), so residual priming cancels.
  See the README contamination section.

## Meta-lessons (the ones that are about us, not the bench)

- **Redundant checks must fail independently.** Two Pro skeptic docs shared one
  premise and went down together (common-mode). Our three checks are deliberately
  independent: the ablation (does the graph help), the flat-graph control (does the
  gap track topology), the adversarial refutation (is each case genuine). If all
  three agree it is less likely a shared blind spot.
- **"Too good" is the alarm that gets through.** Vivid evidence cannot be doubted
  from the inside; the one feeling that breaks frame is *this is too clean*. If
  craft-only fails 100% and craft+graph passes 100%, **stop and read the cold
  source**: is craft-only actually running, is the graph actually injected, is the
  gold test actually discriminating? Too-clean is a stop sign, not a result.
- **Paper doubt is not doubt.** The committed null (README) is the live doubt that
  puts the belief at genuine risk. If craft-only passes nearly everywhere, the
  graph is redundant even in the regime built to favor it, and we report that.
- **Stop testing bundles.** Pull one part, hold the rest fixed, let the difference
  name the cause. The entire design is this lesson made into a protocol.
