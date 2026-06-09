# `instances.jsonl` schema

One row per merged PR (the only eligible category; see README). Local fields are
populated now; gh-dependent fields are `null` until Stage 0 enrichment
([`../OPERATIONS.md`](../OPERATIONS.md)).

| field | source | meaning |
|---|---|---|
| `instance_id` | local | `owner__repo__pr<N>` |
| `repo`, `pr_number`, `pr_url`, `pr_title` | receipts | PR pointers |
| `pr_created_at`, `merged_at` | receipts | timestamps (pre-submission snapshot cutoff) |
| `additions`, `deletions` | receipts | diff size |
| `title_class` | heuristic | `bug` / `nonbug` / `unknown` (nonbug = feat/docs → likely KNOWN_BAD) |
| `graph_candidates[]` | local join | issue-numbered graphs in the same repo, each with `issue`, `graph_path`, `n_hyp`, `n_kills`, `n_perturb`, `n_lines`, `degenerate` |
| `degenerate` (per graph) | local | graph mentions DNS/clone-failed/unavailable/no-PR/standalone — perturbations proposed, not executed; treat counts as unreliable |
| `n_branchy_nondegenerate` | local | count of candidate graphs with (`n_kills>=2` or `n_perturb>=2`) and not degenerate |
| **`linked_issue`, `issue_url`, `issue_created_at`** | gh | exact PR→issue (`closingIssuesReferences`); resolves the repo-match ambiguity |
| **`issue_age_days`, `issue_comments`, `prior_pr_attempts`** | gh | revealed-hard + demand signal (hard ≠ neglected) |
| **`parent_sha`, `merge_sha`** | gh | reconstruct the pre-fix checkout (`merge_sha^1`) |
| **`shipped_test`, `test_files`** | gh | merge diff carried a test → gradeable gold |
| **`pre_submission_graph_recoverable`** | git | `repo-hypotheses` history has a snapshot ≤ `pr_created_at` |
| **`eligible`, `exclude_reason`** | derived | final gate after enrichment + gold-grade |

**Eligibility (all must hold):** merged ∧ `title_class!=nonbug` ∧ exact `linked_issue`
with a non-degenerate branchy graph ∧ `shipped_test` ∧ `pre_submission_graph_recoverable`
∧ gold reds-at-parent/greens-on-gold. Anything failing one goes to `exclude_reason`
(frozen KNOWN_BAD, not post-hoc filtering).
