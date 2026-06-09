# The Hypothesis Graph Is Load-Bearing

A mechanism paper, not a performance paper.

**Claim.** A harness-level data structure, the typed hypothesis graph, makes
bugfixes succeed that the same model cannot reach without it, on real GitHub
issues whose fixes are certifiably outside the model's training and where no gold
specification is handed over. This is an existence proof plus the mechanism that
generates the structure. It is not a resolve-rate claim.

---

## Why this exists: the wrong bench

The prior work ([`swebench-pro`](https://github.com/kimjune01/swebench-pro), the
[methodeutic-harness paper](https://june.kim/the-methodeutic-harness-on-swebench-pro))
chased a *performance* number: 95.3% on SWE-bench Pro, a ~31–37 point lift over
the best bare model. Two findings dismantled that as evidence for the method:

1. **The gate compensates.** A controlled ablation (`craft-only`) deleted the
   entire diagnosis stage and performance barely moved (≈94% vs 95.3%, and the
   gap rests on two instances). The mechanism: blind iteration against a cheap,
   trustworthy test oracle does the diagnosis stage's job for free. Pro *has*
   that cheap oracle.
2. **Pro is a spec-conformance bench, not a diagnosis bench.** Each instance
   hands the agent the requirements and interface; the gold tests name the
   missing surface. Abduction has nothing to abduce, so the hypothesis graph
   degenerates to a single transcription node. (See the paper's own flipt
   worked example: "abduction generates the diff in one move and needs no fan of
   competing hypotheses.")

Both findings point the same way: **SWE-bench Pro structurally cannot measure
the thing the harness is for.** It is the cheap-oracle, spec-given regime where
the method is *predicted* not to matter. The craft-only null is not a refutation;
it is the predicted signature of a mechanism that fires only when the oracle is
expensive or absent and the diagnosis is genuinely hidden.

The performance paper dies here. The mechanism paper begins here.

## The reframe

A mechanism paper has a different burden of proof. It does not need a
representative sample, a baseline arms-race, or a population rate. It needs a
few cases where the mechanism demonstrably operates, under control. Every knife
that cut the performance claim is blunt against the mechanism claim:

| finding | kills performance claim? | kills mechanism claim? |
|---|---|---|
| gate compensates, craft-only ≈ full | yes (lift not attributable) | no (predicts the bulk null) |
| 34% of Pro underdetermined | yes (biases the rate) | no (no rate is claimed) |
| thin hard tail | yes (can't measure the sliver) | no (a few cases suffice) |

We abandon the 95.3% as the result. The result is the controlled existence
cases.

## The right regime: our own deployment data

The methodeutic lineage already ran on real GitHub bugs. The `sweep` pipeline's
`investigate` skill is the inquiry stage under another name (abduction, kill
conditions, directed perturbation, follow the edge). It shipped **81 merged PRs
into 73 cold repositories** at a ~50.6% merge rate (May 2026), and it persisted
a hypothesis graph per issue at `~/Documents/sweep/repo-hypotheses/`.

This is the regime Pro could not reach:

- **No gold spec.** The agent saw the symptom a bug reporter actually filed.
- **No cheap oracle at solve time.** The grader was a human maintainer.
- **Real diagnosis required.** The cause was hidden in the codebase.

**Topology confirms the mechanism engages here.** Scanning the 385 persisted
graphs, the canonical per-issue files split sharply: some branch richly
(`antonmedv__fx__415`: 3 hypotheses, 16 kills, 3 perturbations, 355 lines;
`abhinav__git-spice__1149`: 4 H, 4 kills, 10 perturbations), others stay flat
(single-node or abandoned). On real bugs the graph branches where on Pro it
collapsed. The generator does diagnostic work in this regime.

## The experiment

Reconstruct each instance offline and run the ablation that Pro made meaningless.

For a targeted set of instances (branchy graph ⋀ revealed-hard ⋀ merged-with-test):

1. Check out the repo at the **pre-merge parent commit** on an EC2 box.
2. Recover the **symptom-only input** (the original issue text) and the **oracle**
   (the test the merged PR shipped: red at parent, green on the gold fix).
3. Run craft two ways, graded by the merge-certified test:
   - **without:** `craft( symptom + failing test )` — null handoff.
   - **with:** `craft( symptom + failing test + hypothesis graph )`.

The graph is the **artifact under test**. Whatever generates it (the `investigate`
/ `recon` inquiry process) is the **mechanism** the paper is about.

### What counts as gold: the merge, not the test

There is no pre-existing test oracle in this regime. The test the PR shipped was
written by the harness, but **that is irrelevant once it merged.** A merged test
is gold for exactly the same reason every SWE-bench gold test is gold: it was
accepted into `main` and now guards the repo. The field never audits whether a
human or a tool drafted a gold test, or how hard the maintainer stared at it; the
merge *is* the certification. A harness-authored test that merged has identical
standing. **The fix and the test were both attested by the same merge**, so the
gold is the merged fix+test bundle, and applying extra suspicion because the
harness drafted it would be special pleading the field does not apply to anyone
else.

Consequences:

- **Only merged PRs are eligible.** Closed-unmerged PRs carry no attestation and
  cannot be graded. They drop out of the experiment.
- **The grade is independent of the agent**, because the merge is a human
  decision external to the harness. That independence is what makes the existence
  case survive a skeptic.
- The one caveat is **inherited, not new**: a narrow gold test can in principle
  reject a different correct fix (test-overfitting). This applies identically to
  every human-authored SWE-bench gold test and is mitigated the same way (review).
  It is not a special liability of harness-drafted tests.

### Win condition (existence case)

`craft-only` **fails** the shipped test and `craft + graph` **passes**, on a
revealed-hard issue, with the graph showing real diagnostic branching. The chain:

- the graph was produced **blind** (the generator ran before the PR existed,
  never saw the oracle);
- if craft-only fails and craft+graph passes, the graph was **necessary** for
  that instance;
- the graph is producible **only** by the methodeutic generator;
- therefore the generator is necessary, via the graph, for that instance.

Three to five such cases is the paper.

### The null we commit to report

If `craft-only` passes nearly everywhere, the graph is **redundant even in the
regime built to favor it**, and the thesis is falsified. We report that outcome.
This is the doubt that puts the belief at genuine risk; "wrong bench" was the
consoling story, this is the test that can come back against us.

## Three independent legs of evidence

1. **Controlled ablation** (load-bearing): with/without graph, same model, graded
   by the shipped test. Establishes the graph was necessary.
2. **Graph topology**: rivals, kills, discriminating perturbations in the
   persisted artifact. Establishes the generator did non-trivial work, not luck.
3. **Revealed-difficulty counterfactual**: the issue was old and unsolved despite
   demand. A natural control group (the human market that failed the same issue)
   substituting for an experimental deprived arm.

## Contamination analysis

The graphs were generated by **Opus 4.7** (Jan 2026 cutoff) during the May 2026
deployment. This is clean here, and the reason is the argument:

- **Opus 4.7 is contaminated for Pro and clean here.** Pro's issues are
  2023–2025, so a Jan-2026 model postdates them. The deployment fixes are May
  2026, four months *after* cutoff: the model stopped training before the
  solution existed. The same model that disqualifies a Pro number certifies this
  one.
- **Certify the fix, not the issue.** A revealed-hard issue is old, so its bug
  report and a graveyard of failed prior attempts may well sit in training.
  "Non-contaminated" therefore means the *working fix is certifiably novel* (it
  did not exist until the harness produced it post-cutoff), **not** that the
  model never saw the issue.
- **The mechanism claim is differential, so residual priming cancels.**
  craft-only and craft+graph run the *same model* on *both* arms. Whatever the
  model absorbed from old issue chatter is a fixed offset present in both; it
  cannot manufacture a *gap* between the arms, only the graph can. This is why a
  within-instance ablation is robust where an absolute resolve rate is not, and
  it is the answer to "Opus just remembered the codebase": fine, it remembered
  equally in both arms, and craft-only still failed.

The age/recency tension is real and stated openly: **revealed-hard wants old
issues; contamination-clean wants new.** The resolution is to pin cleanliness to
the fix and let the differential carry the rest.

## Guards committed before running

- **Pre-submission graph snapshot.** The persisted file accumulates across
  rounds, and a `reinvestigate` lane adds nodes *after* the PR opens, fed by CI
  logs and review comments. The artifact under test must be the graph **as of
  first PR submission**, recovered from git history at or before each PR's
  `created_at`, so post-feedback information does not leak into the "with" arm.
- **Shipped-test oracle only.** Grade on the test the PR shipped. Do not synth a
  test from the issue (self-grading; self-authored checks went 4/4 false-green
  against the real grader in prior work). Do not grade by diff-overlap against
  the gold (a noisy recall metric).
- **Separate hard from neglected.** Issue age confounds difficulty with neglect.
  Require a demand signal (comments, +1s, multiple reporters, reopens) so
  "revealed-hard" means "unsolved despite demand," not "ignored in a dead
  corner."
- **Existence, not rate.** We look at merged instances and report counts, never a
  population resolve rate. The scope clause is stated wherever a number appears.

## Status / next steps

- [ ] Recover as-of-first-PR snapshots from `repo-hypotheses/` git history vs PR
      `created_at`; size the clean experimental pool.
- [ ] Build the targeting join: topology score ⋀ issue age+demand ⋀
      merged-with-test. Rank candidates.
- [ ] Pick 3–5; reconstruct checkout + shipped test on EC2.
- [ ] Run the with/without-graph ablation. Report survivors and the null.

## Provenance

This design is the output of a working session that started from "I chose the
wrong bench." The losing path (the performance paper on Pro) is the richest
artifact and is documented as such, not buried. See
[`swebench-pro`](https://github.com/kimjune01/swebench-pro) for the prior run and
[`docs/`](docs/) for the worked reasoning.
