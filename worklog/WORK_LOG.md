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

### 18:40 — Corrected ablation protocol; pilots 02-03 (both null); harness validated

Long methodology session, driven by user steers. Net: the protocol is now right and the harness runs end-to-end on real instances. Two committed nulls, no existence case yet, plus the selection heuristic to find one.

Protocol corrections (all from the skeptic frame "was the hypothesis graph needed at all"):
- **Oracle = the issue's ESSENCE, authored from the upstream issue, NOT the PR's shipped test.** The pool's PRs are the agentic pipeline's own (TDD tests = pipeline homework); grading +M against them is circular and reproduces SWE-bench-Pro over-credit. Essence oracle is mechanism-agnostic.
- **Baseline = adapted mini-SWE-agent** (industry-recognized minimal, >74% Verified), not my improvised prompt. `tools/minimal_prompt.tmpl` = its verbatim system+instance prompt with litellm to codex, /testbed to box-sh, git-diff-submit to run-handle.
- **Selector: blind-graph SIZE is a cheap leading indicator of diagnostic depth.** Deep graph means hard diagnosis means existence candidate. Blind-regenerated, not pilot-01's discredited historical-graph branchiness. Existence requires baseline to fail the ESSENCE.

Pilots (both null):
- **02 howsmyssl #301**: strict gold = craft-only FAIL / +M PASS, but craft-only PASSES the issue ESSENCE; the strict gap was Vary/wildcard/json-patch, all PR-side over-spec. Caught the over-credit failure mode.
- **03 qrtool #695**: corrected protocol. Adapted mini-SWE-agent baseline PASSED essence in ~91s (5 LOC). +M moot. Shallow blind graph predicted it. Mechanism-agnostic oracle accepted exit-1/"could not find a QR code" where strict gold demanded exit-65/"no QR code found".

Tools: box_goldgrade.sh, pipe_setup.sh, minimal_prompt.tmpl, /tmp/box-sh (base64 proxy to SUT). Gold-graded pool: 6 PASS (sql-metadata, PyMammotion, airflow, howsmyssl, toolhive, qrtool), 2 KNOWN_BAD (ag2, pertpy), wild BLOCKED (lld registry).

Finding so far: in this pool the graph is mostly NOT needed (determined-cause regime), consistent with the manifesto ("bug-fix-shaped issues"). Existence cases live in the deep-graph tail: compiler/type-checker/linker internals. Next: recon-triage flux #833 (soundness hole), burn-onnx, tach by blind-graph depth; full ablation only on the big graphs.

### 20:15 - The nulls are a SELECTION ARTIFACT (triage fast-paths easy bugs past the graph)

Pilot 04 (slang-server #310) nulled too: deepest genuine graph in the pool, blind-reproduced, but the minimal mini-SWE-agent baseline implemented the correct dynamic N+1 delimiter in ~123s. Tally: 4 nulls, 0 existence cases.

User's key insight (verified). The pipeline's issue-SELECTION skill biases the pool. Read sweep/skills/triage.md at the 2026-05-09 issue-scan commit (44ca3077):
- Scoring rewards "clear repro (code fence / stack trace / steps)" +5 ("machine-leverage"); penalizes "no body / vague" -3; kill-list DROPs "vague, no repro, no error".
- Prioritize order: "reproducible-locally > correctness > maintainer-filed".
- The smoking gun: "Fix-ready fast-path. A 1-line fix with a confirmed reproducer doesn't need a hypothesis graph."

So the pipeline ROUTES easy/reproducible bugs past the graph, and our pool (merged PR + shipped test) IS that fast-pathed subset. We measured the graph where the pipeline itself says it is not needed. The nulls EXONERATE the graph: selection artifact, not decoration.

Existence-case condition (precise): reproducible (passes repro filter, gradeable) + cause hidden/non-local (NOT fix-ready) + terse report (issue does not hand over example/fix). Triage admits these (clear-repro scores +5 regardless of cause-hiddenness) but does not prioritize them, so a few leak into the merged pool.

Reframe: the right pool is NOT merged fix-ready PRs; it is issues the pipeline sent to /investigate (graph-built) that were reproducible-but-hidden-cause. For now hunting the leaked ones: tidb #42770 (reproducible SQL panic, two-path scalar+vectorized fix -> not fix-ready). Gold-grading on gobox.
