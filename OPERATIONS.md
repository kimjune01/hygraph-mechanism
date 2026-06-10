# Operations: running the graph-necessity ablation

Runbook for the experiment in [`README.md`](README.md), under the discipline in
[`docs/INHERITED-DISCIPLINE.md`](docs/INHERITED-DISCIPLINE.md). Data:
[`data/instances.jsonl`](data/instances.jsonl) ([schema](data/SCHEMA.md)).

We are good at running these. The point of this doc is that the **free checks run
to exhaustion before any token or EC2 dollar moves** (the Pro `bootstrap.sh`
discipline: print `READY` or the exact failing command, refuse to proceed).

## Stage 0 funnel (already run)

```
81 merged  →  60 have a closing issue (gh closingIssuesReferences)
            →  24 also bug-shaped with a shipped (merge-certified) gold test   ← the pool
            →   3 high-prior: a historical branchy graph already shows the
                  mechanism engaged on that issue
                  (slang-server#342→#310, sql-metadata#630→#401, wild#1924→#1915)
```

**Linkage was never the blocker — regeneration dissolves it.** The mechanism is
the *skill*, not the 2026 graph file, and running it on the same issue reproduces a
similar graph (the conclusion is invariant to *when* the graph was made). So we do
not need to recover each merged PR's own historical graph. We need a merged issue
with a gold test; then the graph is **historical where one exists, regenerated
otherwise**, both blind. The pool is 24 and we need a handful of existence cases.

**Generator-contamination is the one "when" that matters** (the graph is the
treatment, not cancelled by the differential): regenerate only with a model whose
cutoff predates the issue (Opus 4.7 / Sonnet 4.5).

**Selection: craft-only failure is the selector, not graph topology** (pilot 01).
The 3 "high-prior" cases were ranked by *historical* graph branchiness — but pilot
01 showed that signal is false: `sql-metadata#401`'s branchy graph was review
back-and-forth, not diagnostic depth, and the bug is a one-line fix craft-only
solves unaided. So don't pre-guess difficulty. **Run craft-only (pre-cutoff model)
across the 24-pool first; the instances where it _fails_ are the existence-case
candidates, and +M is tested only there.** craft-only silently passing is itself
data: a determined/easy instance, the Pro "craft-only ≈ recon" regime. See
[`pilots/01-sql-metadata.md`](pilots/01-sql-metadata.md) — and note it also
confirmed the reinvestigate-leak guard by catching a review-response graph in our
top candidate.

## Stage 0 — $0 pre-flight (enrich, gold-grade, freeze)

Per candidate, all free, all before tokens:

- **Enrich pointers** (`gh`, partly done): `linked_issue`
  (`gh pr view N -R repo --json closingIssuesReferences,body` → match to a repo
  graph issue), `merge_sha`/`parent_sha` (`mergeCommit.oid`, parent = `^1`),
  `shipped_test`/`test_files` (`files`), `issue_created_at`/`issue_comments`
  (`gh issue view`). Backoff on secondary rate-limit (the burst above hit it).
- **Graph source.** Default to **regenerate** (run the skill on the issue with a
  pre-cutoff model) — uniform, and no reinvestigate-leak to worry about. The
  historical graph, where one exists (the 3 high-prior), is a **cross-check** that
  regeneration reproduces the diagnosis, not a dependency. If you do use a
  historical file, pin it to the pre-submission snapshot
  (`git log --before=<pr_created_at> -1 -- repo-hypotheses/<file>`) so reinvestigate
  nodes don't leak.
- **Gold-grade** (the spend-$0 wall): clone, checkout `parent_sha`, build, and
  confirm the merged test is **red at parent** and **green on the gold fix**
  through the adapter. A candidate whose gold does not red/green cleanly is
  KNOWN_BAD and never runs.
- **Freeze** the eligible set, the selection rule, and the KNOWN_BAD exclusions
  with reasons, committed, before any ablation verdict lands.

## Infrastructure — boxes (the repos do not fit locally)

Reuse the Pro fleet; do not rebuild it. The relevant scripts in
`swebench-pro/driver/`:

- `provision_box.sh <name>` — one EC2 box: us-west-2, `m7i.xlarge`, 100 GB gp3
  (`EBS_GB` override), AL2 + docker, `shutdown -h +180` + shutdown-behavior=terminate
  (self-terminating), writes `/tmp/<name>.env` (KEY/PUBIP/IID/SG), prints `READY`.
- `ablation_fleet.sh` — the arm harness: `smoke | provision N | status | checkpoint
  | delta | teardown`, `WATCHDOG_MIN` self-terminate (720), pins claude+codex CLIs,
  pushes Max OAuth + codex auth, git-inits the repo. **`ARM_RUNNER`/`ARM_LEDGER` are
  the swap point** — the recon→ask swap it already does is our craft-only→+T→+G→+M
  swap. `box_health.sh`, `drain_boxes.sh`, `coordinator.py` round it out.

**What changes from Pro: there is no prebuilt image.** Pro pulled a per-instance
Docker image; we clone an arbitrary repo and build from source at `parent_sha`. So
the new, gating deliverable is a **per-repo build+test recipe** (clone, checkout
`parent_sha`, install the repo's own toolchain, run its test red-at-parent). This is
bespoke and is the reconstruct cost that does not shrink. First three:

| repo | toolchain | recipe sketch | box |
|---|---|---|---|
| `macbre/sql-metadata` | Python | `pip install -e . && pytest test/test_unions.py` | m7i.xlarge / 100 GB |
| `hudson-trading/slang-server` | C++/CMake | configure + build + `ctest` MarkupTests | m7i.xlarge / 100 GB |
| `wild-linker/wild` | Rust (lld-class) | `cargo test` version-node case | m7i.2xlarge / 150 GB (LTO) |

**Topology:** one box per repo (build toolchains conflict; isolation is mandatory),
all four arms run on that box against the one checkout. **Sizing:** the 3 high-prior
are moderate; the tier-2 tail (servo, godot, tidb, airflow) needs much bigger boxes
and is a separate decision. **Cost:** EC2 is the only marginal cost (models on Max =
$0); ~$0.20/box-hr, so the 3 high-prior end-to-end ≈ a few dollars. Self-terminate
watchdog always on; warm each box's OAuth until it returns OK before dispatch
(expires ~8h); git-init so codex doesn't refuse the dir.

## Stage 1 — reconstruct (per eligible instance, on its box)

Each repo on its own EC2 box (heavy-repo setup is the one cost that does not
shrink; keep to the targeted few):

- Checkout `parent_sha`; build env + deps; confirm the test runner reproduces
  **red at parent** (the gate self-test — discriminates before we trust it).
- Recover the **symptom-only input**: the issue body as of `issue_created_at`,
  no engineered spec.
- Load the **as-of-first-PR graph snapshot** (Stage 0).

## Stage 2 — the ablation ladder (same model + budget across arms)

Pin a model whose cutoff predates the issue (the fixes are post-cutoff; keep it
clean). Same craft model on all arms so craft-side contamination cancels. The
diagnosis artifact is generated by one of three frozen skills (reuse the Pro arms,
authored by codex as anti-sandbag controls):

| arm | diagnosis artifact | skill |
|---|---|---|
| **craft-only** | none (symptom + failing test) | — |
| **+T** | minimal: resolve, pass, report | `swebench-pro/skills/minimal` |
| **+G** | generic rigor, **no** Peircean vocab | `swebench-pro/skills/generic` |
| **+M** | methodeutic hypothesis graph | `swebench-pro/skills/recon` (frozen) |

`craft( symptom + failing test + <artifact> )`, artifact regenerated by the skill
with a pre-cutoff model (or the historical file for the high-prior 3). The ladder
reads off the full attribution from one set of runs:

- **+M vs craft-only** — does a methodeutic graph help? (the existence claim)
- **+M vs +G** — does the Peircean vocabulary earn anything, or is it generic
  structure? (re-tests the Pro diagnosis-recall null, M ≈ G, in the
  diagnosis-needed regime where it could flip)
- **+G vs +T** and **+T vs craft-only** — does generic structure beat the task
  floor, and does any diagnosis beat none?

The core existence proof needs only **+M vs craft-only**; run the full ladder on
the high-prior 3 plus a sample. These are the only relevant ablations.

Capture **source-only** diffs (strip test-file hunks, build/runtime blobs,
oversized hunks). An arm must **not** edit the gold test. Grade each arm on a
**fresh** checkout. The harness's internal gate is a stop signal only.

**The oracle is the issue's ESSENCE, authored from the upstream issue — NOT the
PR's shipped test** (pilot 02). The pool's PRs are the agentic pipeline's own
output, so their shipped tests are pipeline-authored and over-specified; grading
+M against them is circular (the mechanism graded against a test the mechanism
wrote) and reproduces the SWE-bench-Pro over-credit failure mode. What the merge
buys is third-party confirmation that the bug is real and was fixed acceptably —
not a license to use the pipeline's test as the bar. So per instance, author a
**minimal essence oracle** capturing the behavior the *issue* (third-party) states,
and drop the maintainer/pipeline rigor the issue never asked for (in pilot 02:
`Vary: Accept`, `*/*` exclusion, media-type-variant exactness were all PR-side
additions, not in issue #301). The shipped test is downgraded to a *reference*.
**Existence requires craft-only to fail the ESSENCE, not the strict gold.**
A null under essence-grading (craft-only already captures the essence) is a
committed result, not a discard.

**Craft gets a run-handle, not the test body.** Expose the failing test to craft as
a pass/fail signal it can run, not as source in the prompt. If the assertion body
is in context, every arm can pattern-match it, and +M-vs-craft-only partly measures
"graph helps hit the assertion" — the input oracle-leak from the Pro field card. In
the no-spec regime the test is tempting as the only behavior signal; that is the
trap. Run-handle keeps the differential about diagnosis.

**Compute-asymmetry scope.** +M includes an extra diagnosis pass craft-only never
gets, so part of any gap is upstream compute, not the graph's content. The claim
*the graph artifact helps* survives this; the stronger *diagnosis beyond compute
helps* needs a compute-matched craft-only arm (equal planning budget, no artifact).
State the scope; the matched arm is optional.

## Stage 3 — controls and adversarial verification

- **Flat-graph negative control:** run +M on flat-graph instances. Predict **no
  gap** (no diagnosis to be load-bearing).
- **Shuffled-graph negative control** (codex, for completeness): give craft a
  plausible but **wrong** graph from a different issue. Predict **no gap**. If a
  mismatched graph still helps, the benefit is generic scaffolding / extra context,
  not diagnosis. Pairs with flat-graph: flat = no diagnosis, shuffled = wrong
  diagnosis; the gap must **track diagnostic fit**, not mere presence of a document.
  A negative control needs breadth, not bug-class, so the frame is *all gradeable
  instances* (closing-issue ∧ shipped-test) regardless of bug/feature.
  **The frame caps at n=29** in the current merged set — run the whole 29 rather
  than sampling; reaching n=40 requires expanding the source PR set (the
  shipped-test oracle requirement is non-negotiable, so don't relax it to pad N).
- **Confirm the instrument moved:** verify arms actually differ downstream (graph
  injected and read), not a silent no-op (the A2 sentinel lesson).
- **Degenerate-patch check (not a heavyweight audit).** The merge already
  human-verifies the *gold*; it does **not** verify the *arm's* patch, which no
  maintainer saw. So the only residual is the Pro special-case move: did +M win by
  writing the smallest thing that satisfies a narrow assertion rather than a real
  fix? Default to trusting the merged test as the verdict; eyeball +M's diff for
  test-shaped hacks, and reserve a heavier look only when the merged test is narrow
  (one assertion, one case). Not a semantic re-audit of every win.

## Stage 4 — report

- **Tier-1 mechanical spine:** A fails / B passes on the merged gold test, fresh
  checkout, committed receipts (parent_sha, gold test, snapshot graph, both diffs,
  per-arm grade). A hostile reader re-derives.
- **The funnel and the committed null:** if A passes nearly everywhere, the graph
  is redundant even here, reported. Small-N is a stated scope.
- **Cost:** economic per-instance rate separate from cash.

## Operational hygiene (from the field card)

- Predeclare the **infra fault class** with invariants before any re-dispatch; a
  non-empty arm graded "fail" is a real loss.
- **Guard env at the call site** (`: ${REPO:?} ${SSH:?}`); tired-operator-at-hour-60
  is in the threat model.
- **Stream-monitor** every batch (heartbeat, alert on EMPTY/crash).
- **Never edit the harness/grader mid-run**; stage fixes, apply after DONE,
  re-grade from persisted patches.
