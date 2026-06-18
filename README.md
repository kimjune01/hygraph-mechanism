# The Hypothesis Graph

[![DOI](https://zenodo.org/badge/1264985202.svg)](https://doi.org/10.5281/zenodo.20691973)

*A mechanism case study, not a performance paper: the evidence, the harness, and the full reasoning trail.*

Claim: a harness-level data structure, the typed hypothesis graph, makes bugfixes succeed that the same model cannot reach without it, on real GitHub issues whose fixes are certifiably outside the model's training and where no gold specification is handed over. This is an existence proof plus the mechanism that generates the structure. It is not a resolve-rate claim.

---

### If you arrived from the paper

The tool this work produced lives in its own repo:

> ### → [abductor](https://github.com/kimjune01/abductor)
> Execution-gated abductive evaluation for LLM program repair: the `case-check` gate, generalized and AGPL-licensed. Ships the `/debug` skill and an example prompt.

This repo holds the controlled cases, the grading harness, and the complete reasoning trail. A short map:

- [`RESULTS.md`](RESULTS.md): the visual dashboard, the arc, the family split, the battery, and diagrams. Start here for the picture.
- [`LESSONS.md`](LESSONS.md): the findings and methodological lessons, distilled from the worklog.
- [`REPRODUCE.md`](REPRODUCE.md): how to re-derive them, and the five traps that produce false results if skipped.
- [`pilots/11-verus-2219/`](pilots/11-verus-2219/): the headline case, a verifier soundness bug whose correct fix is an XOR-shaped predicate (see its [`MANIFEST.md`](pilots/11-verus-2219/MANIFEST.md)).
- [`OPERATIONS.md`](OPERATIONS.md) and [`METHODOLOGY-preregistration.md`](METHODOLOGY-preregistration.md): the protocol and the pre-registration.
- [`worklog/`](worklog/): the raw chronology (`WORK_LOG.md`) and the independent Fable arm (`FABLE_WORKLOG.md`).

### What is done, what is planned

Two bodies of evidence live here, at different stages, and the README covers both.

The Verus #2219 case study is complete. It is the mechanism evidence the paper cites, and its artifacts are indexed below.

The sweep-deployment reconstruction, from "The next phase" onward, is planned: a broader test of whether the mechanism recurs across the 81-PR deployment set, with its checklist open in "Status". Read that half as a preregistered protocol, not a finished result.

---

## How to cite

This repository is archived on Zenodo: [10.5281/zenodo.20691973](https://doi.org/10.5281/zenodo.20691973) (concept DOI, always the latest version). It is the artifact backing the paper [*The Hypothesis Graph: Semantic Memory Written by Methodeutics*](https://june.kim/the-hypothesis-graph-semantic-memory-methodeutics). Cite the DOI for the mechanism evidence; cite the paper for the argument.

> Kim, June (2026). *The Hypothesis Graph: a mechanism case study* (Version 1.1.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.20691973

The machine-readable record is in [`CITATION.cff`](CITATION.cff); Zenodo metadata in [`.zenodo.json`](.zenodo.json). To point at a single artifact, cite the DOI followed by the repo-relative path from the index below (e.g. `…/pilots/11-verus-2219/MECHANISM-dissection.md`).

## Artifact index

These are the completed Verus #2219 artifacts. Every claim the paper rests on this repo for maps to a committed path; paths are stable, so cite them against the DOI.

| Backs (in the paper) | Artifact |
|---|---|
| The Verus #2219 lift, dissected end to end | [`pilots/11-verus-2219/MECHANISM-dissection.md`](pilots/11-verus-2219/MECHANISM-dissection.md), [`RESULT-corrected.md`](pilots/11-verus-2219/RESULT-corrected.md) |
| The ablation grid (narrow / wide-but-broken / general) | [`pilots/11-verus-2219/RESULT-corrected.md`](pilots/11-verus-2219/RESULT-corrected.md), [`results/`](pilots/11-verus-2219/results/) |
| The tiny bench and its two goldens (construction + human-approved) | [`pilots/11-verus-2219/MANIFEST.md`](pilots/11-verus-2219/MANIFEST.md), [`gate2/`](pilots/11-verus-2219/gate2/) |
| Forced-fresh, identity-verified dataset (21 artifacts, rebuild-confirmed) | [`pilots/11-verus-2219/clean_dataset.jsonl`](pilots/11-verus-2219/clean_dataset.jsonl) ([rendered](pilots/11-verus-2219/clean_dataset.md)) |
| The climb trace (per-arm session logs) | [`pilots/11-verus-2219/logs/`](pilots/11-verus-2219/logs/) |
| Out-of-grammar held-outs (assoc-type projection, nested generic) and the divergence guards | [`pilots/11-verus-2219/heldout2/`](pilots/11-verus-2219/heldout2/), [`heldout/`](pilots/11-verus-2219/heldout/) |
| The externalized gate (enumerate / calibrate / gate) | [`pilots/11-verus-2219/tools/case-check.py`](pilots/11-verus-2219/tools/case-check.py) + [`calibration.json`](pilots/11-verus-2219/tools/calibration.json); generalized tool → [abductor](https://github.com/kimjune01/abductor) |
| The corrected gate (base + approved-fix golden) | [`pilots/11-verus-2219/gate2/`](pilots/11-verus-2219/gate2/) |
| Recall probe (model does not recover the post-cutoff fix) | [`BOOTSTRAP-instance-probe.md`](BOOTSTRAP-instance-probe.md), [`pilots/11-verus-2219/RESULT-corrected.md`](pilots/11-verus-2219/RESULT-corrected.md) |
| Cross-workflow arms (codex, Fable, Sonnet 4.6, Composer 2.5) | [`pilots/11-verus-2219/patches/`](pilots/11-verus-2219/patches/), [`logs/`](pilots/11-verus-2219/logs/), [`worklog/FABLE_WORKLOG.md`](worklog/FABLE_WORKLOG.md) |
| Preregistration (one sentence per loop) | [`METHODOLOGY-preregistration.md`](METHODOLOGY-preregistration.md) |
| The localization-hard candidate band | [`CANDIDATES-localization-hard.md`](CANDIDATES-localization-hard.md) |
| flux #1613 auditability trail (19-node, frozen) | [`pilots/08-flux-1613/`](pilots/08-flux-1613/) at tag `flux-1613-trail-v1` |
| Verus #2427 boundary case (oracle in place, did not engage) | [`pilots/10-verus-2427/`](pilots/10-verus-2427/) |
| The null-regime pilots (minimal baseline kept succeeding) | [`pilots/03-qrtool/`](pilots/03-qrtool/), [`04-slang-server/`](pilots/04-slang-server/), [`05-fjall-287/`](pilots/05-fjall-287/), [`06-bat-3710/`](pilots/06-bat-3710/) |
| Findings and methodological lessons | [`RESULTS.md`](RESULTS.md), [`LESSONS.md`](LESSONS.md) |
| Reproduction (and the traps that void a result) | [`REPRODUCE.md`](REPRODUCE.md), [`pilots/11-verus-2219/REPRODUCE.md`](pilots/11-verus-2219/REPRODUCE.md) |

---

## Why this exists: the wrong bench

The prior work ([`swebench-pro`](https://github.com/kimjune01/swebench-pro), the [methodeutic-harness paper](https://june.kim/the-hypothesis-graph-semantic-memory-methodeutics)) chased a *performance* number: 95.3% on SWE-bench Pro, a ~31–37 point lift over the best bare model. Two findings dismantled that as evidence for the method:

1. The gate compensates. A controlled ablation (`craft-only`) deleted the entire diagnosis stage and performance barely moved (≈94% vs 95.3%, the gap resting on two instances). Blind iteration against a cheap, trustworthy test oracle does the diagnosis stage's job for free, and Pro has that cheap oracle.
2. Pro is a spec-conformance bench, not a diagnosis bench. Each instance hands the agent the requirements and interface, and the gold tests name the missing surface. Abduction has nothing to abduce, so the hypothesis graph degenerates to a single transcription node.

Both point the same way: SWE-bench Pro cannot measure the thing the harness is for. It is the cheap-oracle, spec-given regime where the method is predicted not to matter. The craft-only null is not a refutation; it is the predicted signature of a mechanism that fires only when the oracle is expensive or absent and the diagnosis is genuinely hidden.

The performance paper dies here. The mechanism paper begins here.

## The reframe

A mechanism paper has a different burden of proof. It does not need a representative sample, a baseline arms-race, or a population rate. It needs a few cases where the mechanism demonstrably operates, under control. Every knife that cut the performance claim is blunt against the mechanism claim:

| finding | kills performance claim? | kills mechanism claim? |
|---|---|---|
| gate compensates, craft-only ≈ full | yes (lift not attributable) | no (predicts the bulk null) |
| 34% of Pro underdetermined | yes (biases the rate) | no (no rate is claimed) |
| thin hard tail | yes (can't measure the sliver) | no (a few cases suffice) |

So the 95.3% is not the result. The result is the controlled existence cases.

---

## The next phase: deployment reconstruction (planned)

Everything below is the protocol for the broader test, not a finished run. It asks whether the mechanism that fired on Verus #2219 recurs across the deployment set, under the same controls.

### The right regime: our own deployment data

The methodeutic lineage already ran on real GitHub bugs. The `sweep` pipeline's `investigate` skill is the inquiry stage under another name (abduction, kill conditions, directed perturbation, follow the edge). It shipped 81 merged PRs into 73 cold repositories at a ~50.6% merge rate (May 2026), and it persisted a hypothesis graph per issue at `~/Documents/sweep/repo-hypotheses/`.

This is the regime Pro could not reach:

- No gold spec. The agent saw the symptom a bug reporter actually filed.
- No cheap oracle at solve time. The grader was a human maintainer.
- Real diagnosis required. The cause was hidden in the codebase.

Topology suggests the mechanism engages here. Scanning the 385 persisted graphs, the canonical per-issue files split sharply: some branch richly (`antonmedv__fx__415`: 3 hypotheses, 16 kills, 3 perturbations, 355 lines; `abhinav__git-spice__1149`: 4 H, 4 kills, 10 perturbations), others stay flat (single-node or abandoned). On real bugs the graph branches where on Pro it collapsed.

### The experiment

Reconstruct each instance offline and run the ablation that Pro made meaningless. For a targeted set of instances (branchy graph ⋀ revealed-hard ⋀ merged-with-test):

1. Check out the repo at the pre-merge parent commit on an EC2 box.
2. Recover the symptom-only input (the original issue text) and the oracle (the test the merged PR shipped: red at parent, green on the gold fix).
3. Run the craft ablation ladder, graded by the merge-certified test. The core existence claim is two arms; the full ladder adds the Pro vocab controls ([`OPERATIONS.md`](OPERATIONS.md) Stage 2):
   - `craft-only`: `craft( symptom + failing test )`, the floor.
   - `+M`: `craft( symptom + failing test + methodeutic graph )`.
   - `+G / +T`: generic-rigor / minimal diagnosis artifacts, to ask whether the Peircean vocabulary earns anything or just generic structure (this re-tests the Pro null).

The graph is the artifact under test; the mechanism the paper is about is the skill that generates it (`investigate` / `recon`).

### The graph: historical or regenerated, both blind

The deployment reconstruction may use either a historical graph or a regenerated blind one, and both are valid only if the generator predates the fix. The conclusion does not depend on when the graph was made, since the mechanism is the skill and running it on the same issue reproduces a similar graph. So:

- where a historical graph already covers the closing issue (the 3 high-prior cases), use it: it was generated blind in May 2026 before the fix existed;
- where none exists (the rest of the pool), regenerate it by running the skill on the issue, blind to the PR and fix.

One constraint makes "when" truly irrelevant: the graph is the treatment (only the with-arm gets it), so generator contamination does not cancel in the differential the way craft-model contamination does. Regenerate only with a model whose cutoff predates the issue (Opus 4.7 / Sonnet 4.5, as in the original run), or a current generator could leak a memorized fix into the graph and inflate the with-arm.

### What counts as gold: the merge, not the test

There is no pre-existing test oracle in this regime. The test the PR shipped was written by the harness, but that is irrelevant once it merged: a merged test is gold for the same reason every SWE-bench gold test is gold, because it was accepted into `main` and now guards the repo. The field never audits whether a human or a tool drafted a gold test; the merge is the certification, and a harness-authored test that merged has identical standing.

Consequences:

- Only merged PRs are eligible. Closed-unmerged PRs carry no attestation and drop out.
- The grade is independent of the agent, because the merge is a human decision external to the harness. That independence is what makes the existence case survive a skeptic.
- One limit is inherited, not new: a narrow gold test can in principle reject a different correct fix (test-overfitting). This applies identically to every human-authored SWE-bench gold test and is mitigated the same way, by review.

### Win condition (existence case)

`craft-only` fails the shipped test and `craft + graph` passes, on a revealed-hard issue, with the graph showing real diagnostic branching. The chain:

- the graph was produced blind (the generator ran before the PR existed, never saw the oracle);
- if craft-only fails and craft+graph passes, the graph was necessary for that instance;
- the graph is producible only by the methodeutic generator;
- therefore the generator is necessary, via the graph, for that instance.

Three to five such cases is the target for this phase.

### The null we commit to report

If `craft-only` passes nearly everywhere, the graph is redundant even in the regime built to favor it, and the thesis is falsified. We report that outcome. This is the doubt that puts the belief at genuine risk: the test that can come back against us.

### Three independent legs of evidence

1. Controlled ablation (load-bearing): with/without graph, same model, graded by the shipped test. Establishes the graph was necessary.
2. Graph topology: rivals, kills, discriminating perturbations in the persisted artifact. Establishes the generator did non-trivial work, not luck.
3. Revealed-difficulty counterfactual: the issue was old and unsolved despite demand. The human market that failed the same issue is a natural control group substituting for an experimental deprived arm.

### Contamination analysis

The graphs were generated by Opus 4.7 (Jan 2026 cutoff) during the May 2026 deployment. This is clean here, and the reason is the argument:

- Opus 4.7 is contaminated for Pro and clean here. Pro's issues are 2023–2025, so a Jan-2026 model postdates them. The deployment fixes are May 2026, four months after cutoff: the model stopped training before the solution existed. The same model that disqualifies a Pro number certifies this one.
- Certify the fix, not the issue. A revealed-hard issue is old, so its bug report and a graveyard of failed prior attempts may well sit in training. Non-contaminated therefore means the working fix is certifiably novel (it did not exist until the harness produced it post-cutoff), not that the model never saw the issue.
- The mechanism claim is differential, so residual priming cancels. craft-only and craft+graph run the same model on both arms. Whatever the model absorbed from old issue chatter is a fixed offset present in both; it cannot manufacture a gap between the arms, only the graph can. This is why a within-instance ablation is robust where an absolute resolve rate is not.

The age/recency tension is real and stated openly: revealed-hard wants old issues, contamination-clean wants new. The resolution is to pin cleanliness to the fix and let the differential carry the rest.

### Guards committed before running

- Pre-submission graph snapshot. The persisted file accumulates across rounds, and a `reinvestigate` lane adds nodes after the PR opens, fed by CI logs and review comments. The artifact under test must be the graph as of first PR submission, recovered from git history at or before each PR's `created_at`, so post-feedback information does not leak into the with-arm.
- Shipped-test oracle only. Grade on the test the PR shipped. Do not synth a test from the issue (self-grading: self-authored checks went 4/4 false-green against the real grader in prior work). Do not grade by diff-overlap against the gold (a noisy recall metric).
- Separate hard from neglected. Issue age confounds difficulty with neglect. Require a demand signal (comments, +1s, multiple reporters, reopens) so revealed-hard means unsolved despite demand, not ignored in a dead corner.
- Existence, not rate. We look at merged instances and report counts, never a population resolve rate. The scope clause is stated wherever a number appears.

### Status

Stage 0 run (see [`OPERATIONS.md`](OPERATIONS.md)). The regenerate design dissolves the linkage problem; the pool is the gradeable merged set:

81 merged → 60 with a closing issue → 24 also bug-shaped with a shipped (merge-certified) gold test → 3 high-prior (a historical branchy graph already shows the mechanism engaged): `slang-server#342`, `sql-metadata#630`, `wild-linker/wild#1924`. A handful of existence cases is enough; 24 shots is ample.

- [x] Build the manifest; gh-enrich all 81 (closing issues, merge SHAs, shipped tests); funnel to the 24-case pool.
- [ ] Gold-grade the 3 high-prior (red-at-parent / green-on-gold on `parent_sha`), freeze KNOWN_BAD.
- [ ] Reconstruct on EC2; run the three-arm ablation (graph historical or regenerated with a pre-cutoff model); grade by the merged test.
- [ ] Flat-graph negative control + adversarial refute; report survivors and the null.

---

## Documents

- [`OPERATIONS.md`](OPERATIONS.md): the runbook (stages 0–4, $0 pre-flight first).
- [`docs/INHERITED-DISCIPLINE.md`](docs/INHERITED-DISCIPLINE.md): every Pro/audit lesson translated to this regime; two become new guards (Type III notes-control, flat-graph negative control).
- [`data/instances.jsonl`](data/instances.jsonl) ([schema](data/SCHEMA.md)): the pointer manifest, 81 merged PRs, gh-enriched (merge SHA, test files, topology), with the eligibility funnel.

## LLM collaboration

Frontier models are both the subject under study and the instruments here. The case arms run vendor CLIs over Claude (Opus and Fable) and codex (GPT-5.5) as generator and challenger, with versions and billing recorded in the per-pilot manifests. The writeup was drafted and revised with Claude (Opus 4.8 and Fable 5) and reviewed by codex (GPT-5.5). The claims, methodology, data, and reproduction are the author's, and every number is recomputable from the committed artifacts.

## Provenance

This design started from "I chose the wrong bench." The losing path, the performance paper on Pro, is documented rather than buried; see [`swebench-pro`](https://github.com/kimjune01/swebench-pro) for the prior run and [`docs/`](docs/) for the worked reasoning.
