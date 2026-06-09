# Pilot 01 — macbre/sql-metadata #630 (closes #401)

First end-to-end run. **Purpose: shake out the machinery, not produce a clean
result.** Provisional because the generator and craft models are current-gen
Sonnet (contaminated for this May-2026 fix); the real run pins pre-cutoff models.

## What ran

1. **Reconstruct + gold-grade** (`tools/gold_grade.sh`): base = `bd107e78^1`, oracle
   = `test/test_unions.py` (2 F2P), gold = `column_extractor.py`. RED at base, GREEN
   on gold. ✓
2. **Blind generator** (recon subagent, Sonnet): given only issue #401 + base repo,
   forbidden the PR/fix/tests/post-base commits. Localized `_Collector.add_alias:203`
   (dict overwrite), killed 2 rivals, predicted list-promotion fix. Artifact:
   `pilots/01-sql-metadata/graph_M.blind.md`. ✓
3. **Run-handle** (`pilots/01-sql-metadata/check.sh`): scores the agent's source
   (test dir excluded) against the hidden F2P tests in a separate grade tree;
   prints PASS/FAIL only, never the test body. ✓
4. **Ladder** (craft subagents, Sonnet, same model both arms):

| arm | result | tool-uses | wall |
|---|---|---|---|
| craft-only | **PASS** | 16 | 84 s |
| +M (blind graph) | **PASS** | 7 | 39 s |

## Findings

1. **Machinery works end to end** — reconstruct → blind generate → craft ablation →
   hidden-test grading, ~6 min, a few cents. Every tool validated on real data.

2. **The contamination guard earned its keep — concretely.** The high-prior
   *historical* graph (`macbre-sql-metadata.md`) turned out to be a **review-response
   (reinvestigate) artifact**: it quotes reviewer @collerek's CHANGES_REQUESTED and
   his *suggested implementation* ("adopt verbatim"). Injecting it would have handed
   craft the maintainer's answer. Caught by reading it; regenerated blind instead.
   This is the pre-submission/reinvestigate leak the guard was written for, found in
   the wild on our best candidate.

3. **No existence gap here — and that's consistent with the theory.** Both arms pass.
   `#401` is **low-difficulty**: the symptom names the wanted behavior (aggregate to a
   list) and the fix is one line in an obviously-named function (small fix-symptom
   distance). That is exactly the regime where the mechanism predicts craft-only ≈
   craft+graph — the Pro "determined cause" result, reproduced. The contaminated
   model also inflates craft-only.

4. **Secondary signal (not the claim):** +M reached the fix in **7 tool-uses / 39 s**
   vs craft-only's **16 / 84 s** — the graph roughly halved effort even where it did
   not change the outcome. Directional only; the existence claim needs craft-only to
   *fail*.

## The selection lesson — flip the funnel

"Branchy historical graph" was a **false difficulty signal**: `#401`'s branchiness
came from review back-and-forth, not diagnostic depth. So graph topology is a bad
selector for the hard instances we need.

**The right selector is craft-only failure itself.** Run craft-only (pre-cutoff
model) across the pool; the instances where it *fails* are the existence-case
candidates, and +M is tested only there. Don't pre-guess difficulty — let craft-only
reveal it. `#401` is now data: a determined/easy instance where craft-only suffices.
