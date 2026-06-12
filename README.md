# The Hypothesis Graph Is Load-Bearing

*A mechanism paper, not a performance paper — the evidence, harness, and full reasoning trail behind it.*

**Claim.** A harness-level data structure, the typed hypothesis graph, makes
bugfixes succeed that the same model cannot reach without it, on real GitHub
issues whose fixes are certifiably outside the model's training and where no gold
specification is handed over. This is an existence proof plus the mechanism that
generates the structure. It is not a resolve-rate claim.

---

### If you arrived from the paper

The tool this work produced lives in its own repo:

> ### → [**abductor**](https://github.com/kimjune01/abductor)
> Execution-gated abductive evaluation for LLM program repair — the `case-check` gate, generalized and AGPL-licensed. Ships the `/debug` skill and an example prompt.

This repo holds the controlled cases, the grading harness, and the complete reasoning trail. A short map:

- [`RESULTS.md`](RESULTS.md) — the visual dashboard: the arc, the family split, the battery, and diagrams. **Start here for the picture.**
- [`LESSONS.md`](LESSONS.md) — the findings and methodological lessons, distilled from the worklog.
- [`REPRODUCE.md`](REPRODUCE.md) — how to re-derive them, and the five traps that produce false results if skipped.
- [`pilots/11-verus-2219/`](pilots/11-verus-2219/) — the headline case: a verifier soundness bug whose correct fix is an XOR-shaped predicate (see its [`MANIFEST.md`](pilots/11-verus-2219/MANIFEST.md)).
- [`OPERATIONS.md`](OPERATIONS.md) · [`METHODOLOGY-preregistration.md`](METHODOLOGY-preregistration.md) — the protocol and the pre-registration.
- [`worklog/`](worklog/) — the raw chronology (`WORK_LOG.md`) and the independent Fable arm (`FABLE_WORKLOG.md`).

The narrative below is the conceptual spine: why the standard benchmark can't measure the mechanism, and what regime can.

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
3. Run the craft ablation ladder, graded by the merge-certified test. The core
   existence claim is two arms; the full ladder adds the Pro vocab controls
   ([`OPERATIONS.md`](OPERATIONS.md) Stage 2):
   - **craft-only:** `craft( symptom + failing test )` — floor.
   - **+M:** `craft( symptom + failing test + methodeutic graph )`.
   - **+G / +T:** generic-rigor / minimal diagnosis artifacts — does the Peircean
     vocabulary earn anything, or just generic structure? (re-tests the Pro null.)

The graph is the **artifact under test**; the **mechanism** the paper is about is
the skill that generates it (`investigate` / `recon`).

### The graph: historical or regenerated, both blind

The conclusion does not depend on *when* the graph was made — the mechanism is the
skill, and running it on the same issue reproduces a similar graph. So:

- where a **historical** graph already covers the closing issue (the 3 high-prior
  cases), use it: it was generated blind in May 2026 before the fix existed;
- where none exists (the rest of the pool), **regenerate** it by running the skill
  on the issue, blind to the PR and fix.

One constraint makes "when" truly irrelevant: the graph is the **treatment** (only
the with-arm gets it), so generator contamination does **not** cancel in the
differential the way craft-model contamination does. Regenerate only with a model
whose cutoff **predates the issue** (Opus 4.7 / Sonnet 4.5, as in the original
run), or a current generator could leak a memorized fix into the graph and inflate
the with-arm.

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

## Documents

- [`OPERATIONS.md`](OPERATIONS.md) — the runbook (stages 0–4, $0 pre-flight first).
- [`docs/INHERITED-DISCIPLINE.md`](docs/INHERITED-DISCIPLINE.md) — every Pro/audit
  lesson translated to this regime; two become new guards (Type III notes-control,
  flat-graph negative control).
- [`data/instances.jsonl`](data/instances.jsonl) ([schema](data/SCHEMA.md)) — the
  pointer manifest: 81 merged PRs, gh-enriched (merge SHA, test files, topology),
  with the eligibility funnel.

## Status / next steps

Stage 0 run (see [`OPERATIONS.md`](OPERATIONS.md)). The regenerate design dissolves
the linkage problem; the pool is the gradeable merged set:

**81 merged → 60 with a closing issue → 24 also bug-shaped with a shipped
(merge-certified) gold test → 3 high-prior** (a historical branchy graph already
shows the mechanism engaged): `slang-server#342`, `sql-metadata#630`,
`wild-linker/wild#1924`. We need a handful of existence cases; 24 shots is ample.

- [x] Build the manifest; gh-enrich all 81 (closing issues, merge SHAs, shipped
      tests); funnel to the 24-case pool.
- [ ] Gold-grade the 3 high-prior (red-at-parent / green-on-gold on `parent_sha`),
      freeze KNOWN_BAD.
- [ ] Reconstruct on EC2; run the three-arm ablation (graph historical or
      regenerated with a pre-cutoff model); grade by the merged test.
- [ ] Flat-graph negative control + adversarial refute; report survivors and the null.

## Provenance

This design is the output of a working session that started from "I chose the
wrong bench." The losing path (the performance paper on Pro) is the richest
artifact and is documented as such, not buried. See
[`swebench-pro`](https://github.com/kimjune01/swebench-pro) for the prior run and
[`docs/`](docs/) for the worked reasoning.
