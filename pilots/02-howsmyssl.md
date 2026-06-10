# Pilot 02 — jmhodges/howsmyssl #1005 (closes #301)

First **clean** end-to-end ablation (GPT-5.5 / codex, cutoff predates the May-2026
fix, so generator AND craft are contamination-clean). Same craft model both arms.
Run-handle, not test body. Box: gobox (EC2).

## What ran

1. **Gold-grade** (`tools/gold_grade.sh`): base `daf4aff6^1`, oracle `index_test.go`
   (`TestJSONRedirectContentType`), gold `howsmyssl.go`. RED at base, GREEN on gold. PASS.
2. **Blind recon** (codex, read-only, history truncated to pre-fix): localized
   `commonRedirect:482-490` calling `http.Redirect` without pre-setting `Content-Type`;
   identified the host-mismatch fall-through to the catch-all `/`; killed rivals
   (API handler returns 200/400 not 301; web handler is host-specific). Artifact:
   `pilots/02-howsmyssl/graph_M.blind.md`. **Converged with an independent Sonnet-4.5
   blind recon** (same localization, same killed rivals, same predicted fix shape) —
   evidence the graph is a property of bug+codebase, not the generator.
3. **Ladder** (codex craft, run-handle = binary PASS/FAIL, same model both arms):

| arm | strict gold | wall | src diff |
|---|---|---|---|
| craft-only | **FAIL** | ~765 s | 50 LOC |
| +M (blind graph) | **PASS** | ~603 s | 52 LOC |

## The finding: strict-gold +M "win" is an artifact of an over-specified, self-authored test

craft-only's strict failures were ALL on subcases absent from the issue:
`Vary: Accept` (every case), `*/*` must fall through to HTML, `application/json-patch+json`
must NOT match (exact media-type). It **passed** the two core cases
(`Accept: application/json` → `application/json`, and the case variant) — i.e. it
captured the essence of the issue and only missed maintainer rigor.

**Provenance check (decisive):** the merged PR #1005 is the agentic pipeline's own
(`@kimjune01`, 2026). Issue #301 (jmhodges, 2020) says only "the JSON endpoint returns
text/html, maybe return `{}`." `Vary` / `*/*` / `json-patch` exactness were introduced
**in the PR**, not the issue — the PR body advertises "8 new test cases." So the strict
gold test is **pipeline-authored and over-specified relative to the issue**. Grading +M
against it is circular (the mechanism graded against a test the mechanism wrote).

**Verdict under an essence oracle (issue-derived: `Accept: application/json` →
`application/json`): NO gap.** craft-only already passes the essence. howsmyssl #301 is
a committed **null** on the existence claim — and a positive result for the method:
the SWE-bench-Pro over-credit failure mode, reproduced and caught by the relax-to-essence rule.

## Protocol corrections (carried into OPERATIONS)

1. **The oracle is authored from the upstream ISSUE, never the PR's shipped test.**
   The pool's PRs are pipeline-authored; their tests over-specify. Merge = third-party
   confirmation the bug is real and was fixed acceptably, not a license to use the
   pipeline's test as the bar.
2. **Existence requires craft-only to fail the ESSENCE**, not the strict gold.
3. **Process lesson:** capture each arm's source patch immediately (craft-only's was
   lost to the +M tree reset; recovered the verdict from the strict failure log only).
