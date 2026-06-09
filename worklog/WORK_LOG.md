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

### 16:10 — Python-batch gold-grade on EC2 box (3 PASS / 2 KNOWN_BAD)

Default-to-box (repos too large for local). Built `tools/box_goldgrade.sh` (provision/grade/teardown around Pro `provision_box.sh`; pushes `gold_grade.sh` + recipes, runs the $0 red/green wall per recipe, writes `data/goldgrade.jsonl`). Fixed two `gold_grade.sh` bugs found in-flight — pre-flight tool, safe to edit: (1) work-dir reuse leaked prior-run gold files into "base" → hard `git reset --hard ^1 && git clean -fdx -e .venv`; (2) literal `$HOME` in remote work path → home-relative.

Graded the 5 Python instances (pybox, m7i.xlarge):
- **PASS** (eligible): `macbre/sql-metadata#630`, `mikey0000/PyMammotion#139`, `apache/airflow#66686`.
- **KNOWN_BAD** (methodology data — merge-certified ≠ discriminating): `ag2ai/ag2#2805` non-discriminating oracle (gold = defensive `task=None` init; shipped test never reaches the branch that reads `task`, so green at base with/without fix); `scverse/pertpy#965` env-sensitive oracle (seaborn figsize ticklabel bug #755 doesn't reproduce under seaborn 0.13.2 → regression test passes at base; low diagnostic depth anyway).

2/5 merged+shipped-test bugs fail the red/green wall — the wall earns its keep. Recipe gotchas frozen in `data/recipes.jsonl`: PyMammotion py3.14+pytest-asyncio; pertpy py3.12+formulaic+formulaic_contrasts; airflow fab provider needs `uv pip install -e ./devel-common` for the `tests_common` conftest plugin. Box torn down.

Next: Rust (7) + Go (4) batches on their own boxes; then the craft-only selection sweep on the PASS pool.
