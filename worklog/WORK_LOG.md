# Work Log

## 2026-06-09

### 15:07 — Reframe to mechanism paper, design + first tools + pilot 01

Project: hygraph-mechanism (new repo, /Users/junekim/Documents/hygraph-mechanism). Session: reframed the methodeutic-harness thesis after the "wrong bench" realization, designed the experiment, built the first tools, ran pilot 01.

Key moves:
- Diagnosed: SWE-bench Pro can't measure the harness (cheap-oracle gate compensates; craft-only ≈ recon; 34% underdetermined). The performance paper dies; reframed to a MECHANISM paper (existence proof, not resolve rate) — every Pro "devastating" finding becomes consistent evidence under the mechanism frame.
- Claim: a hypothesis-graph diagnosis artifact makes craft succeed where craft-only fails, on merged GitHub bugs whose merge-certified test is the gold oracle. Graph = artifact under test; the generating skill = mechanism.
- Data: gh-enriched all 81 merged deployment PRs. Pool = 24 (merged + closing-issue + shipped-test + bug). Manifest at data/instances.jsonl.
- Design: craft-only / +T / +G / +M ladder (reuse frozen Pro M/G/T prompts); run-handle not test-body; flat-graph + shuffled-graph negative controls; merge = valid mechanical oracle (codex sniff tempered "merge=correct" to "merge=valid oracle, certify wins by light degenerate-patch check"); regenerate graph with pre-cutoff model (graph is the treatment, contamination doesn't cancel).
- Infra: reuse Pro fleet (provision_box.sh / ablation_fleet.sh ARM_RUNNER swap); the one new bespoke piece is per-repo build+test recipes (no prebuilt image like Pro).
- Tools built: gold_grade.sh (v1, validated).
- PILOT 01 (sql-metadata#630/#401), contaminated machinery run: pipeline works end-to-end; contamination guard caught a real review-response (reinvestigate) graph in the top candidate, regenerated blind; both arms PASS (low-difficulty one-line fix → no gap, consistent with determined-cause regime); +M halved effort (7 vs 16 tool-uses).
- SELECTION FLIP: craft-only failure is the selector, not historical graph topology (false difficulty signal).

Next: craft-only selection sweep across the 24-pool (pre-cutoff model) to surface instances where craft-only fails = the existence-case candidates; heavy repos (wild, slang-server) need boxes.
