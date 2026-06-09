# Operations: running the graph-necessity ablation

Runbook for the experiment in [`README.md`](README.md), under the discipline in
[`docs/INHERITED-DISCIPLINE.md`](docs/INHERITED-DISCIPLINE.md). Data:
[`data/instances.jsonl`](data/instances.jsonl) ([schema](data/SCHEMA.md)).

We are good at running these. The point of this doc is that the **free checks run
to exhaustion before any token or EC2 dollar moves** (the Pro `bootstrap.sh`
discipline: print `READY` or the exact failing command, refuse to proceed).

## Reality check from Stage 0 (already run)

The honest funnel over the 81 merged PRs:

```
81 merged  →  49 look like bugs  →  32 have an issue-graph in the repo
            →  11 have a branchy non-degenerate graph in-repo
            →   1 merged PR cleanly links to its OWN branchy, test-bearing graph
                 (hudson-trading/slang-server#342 → issue #310, H5/k3/p4,
                  test: tests/cpp/MarkupTests.cpp)
```

**The blocker is linkage, not compute.** The richly-branching graphs
(`antonmedv/fx#415`, 16 kills) are mostly *standalone investigations that never
merged*; the merged PRs (`fx#414`) addressed *different* issues whose graphs are
flat or absent. So the clean "ablate the merged PR's own graph" pool is ~1 today.
Three ways forward, to decide before Stage 1:

1. **Recover more links.** Parse each merged PR body for the `[HG]` link or issue
   URL the `drip` step wrote, and check dash-form graphs (`owner-repo.md`, 200 of
   them) for the merged issues. May lift the pool from ~1.
2. **Relax provenance** (with eyes open): the ablation needs *a blind graph for the
   bug* + *a merge-certified test*, not necessarily from the same run. A branchy
   standalone graph for an issue later fixed-and-merged still grades, as long as
   the graph predates the fix (blind). Weaker provenance narrative; state it.
3. **Accept a small-N existence proof.** A mechanism paper needs a few cases. Even
   1–3 airtight Tier-1 cases is an existence proof; report the funnel so small-N is
   a stated scope, not a hidden cap.

## Stage 0 — $0 pre-flight (enrich, gold-grade, freeze)

Per candidate, all free, all before tokens:

- **Enrich pointers** (`gh`, partly done): `linked_issue`
  (`gh pr view N -R repo --json closingIssuesReferences,body` → match to a repo
  graph issue), `merge_sha`/`parent_sha` (`mergeCommit.oid`, parent = `^1`),
  `shipped_test`/`test_files` (`files`), `issue_created_at`/`issue_comments`
  (`gh issue view`). Backoff on secondary rate-limit (the burst above hit it).
- **Pre-submission snapshot** (`git`, in `~/Documents/sweep`):
  `git log --before=<pr_created_at> -1 --format=%H -- repo-hypotheses/<file>` then
  `git show <sha>:repo-hypotheses/<file>`. No snapshot ≤ `pr_created_at` →
  excluded (can't separate task-time nodes from reinvestigate nodes).
- **Gold-grade** (the spend-$0 wall): clone, checkout `parent_sha`, build, and
  confirm the merged test is **red at parent** and **green on the gold fix**
  through the adapter. A candidate whose gold does not red/green cleanly is
  KNOWN_BAD and never runs.
- **Freeze** the eligible set, the selection rule, and the KNOWN_BAD exclusions
  with reasons, committed, before any ablation verdict lands.

## Stage 1 — reconstruct (per eligible instance)

Each repo on its own EC2 box (heavy-repo setup is the one cost that does not
shrink; keep to the targeted few):

- Checkout `parent_sha`; build env + deps; confirm the test runner reproduces
  **red at parent** (the gate self-test — discriminates before we trust it).
- Recover the **symptom-only input**: the issue body as of `issue_created_at`,
  no engineered spec.
- Load the **as-of-first-PR graph snapshot** (Stage 0).

## Stage 2 — the ablation (three arms, same model + budget)

Pin a model whose cutoff predates the issue (the fixes are post-cutoff; keep it
clean). Same model on all arms so contamination cancels in the differential.

- **A · craft-only:** `craft( symptom + failing test )`
- **B · with graph:** `craft( symptom + failing test + graph )`
- **C · notes control:** `craft( symptom + failing test + equal-length generic
  notes )` — the Type III guard (graph vs any-notes; skip only if scoping the
  claim to "this artifact helps", not "the typed structure helps")

Capture **source-only** diffs (strip test-file hunks, build/runtime blobs,
oversized hunks). An arm must **not** edit the gold test. Grade each arm against
the **fixed** merged test on a **fresh** checkout. The harness's internal gate is
a stop signal only; the merged test is the verdict.

## Stage 3 — controls and adversarial verification

- **Flat-graph negative control:** run B on flat-graph instances. Predict **no
  gap**. If flat graphs also produce a gap, diagnosis is not the driver and the
  result is suspect. The gap must **track topology**.
- **Confirm the instrument moved:** verify A vs B actually differ downstream (graph
  injected and read), not a silent no-op (the A2 sentinel lesson).
- **Adversarial refutation:** an independent cross-family model tries to refute
  each surviving Tier-1 case (default refuted): infra artifact? different-but-
  correct fix the narrow test rejects? Only survivors are claimed.

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
