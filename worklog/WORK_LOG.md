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

### 22:30 - Pilot 05 (fjall #287, WILD pipeline-skipped race): NULL. The headline is the minimal agent's REACH.

Took the hunt out of the merged pool to a genuinely hard, OPEN, pipeline-SKIPPED bug: a clear()/ingestion data race in the fjall LSM engine (the triage graph itself rejected it as "too complex for first contribution"). Reproducible, hidden non-local cause, terse Svix report. Two arms in parallel on two boxes, codex GPT-5.5 both, no golden (oracle = the reproducer surviving N time-windows). Budget removed via session-resume loops (per user: turn budget is fake; cost ~10x under a human dev).

Result: NULL. BOTH arms produced real synchronization fixes that pass 6x70s. Graph arm = diagnosis-complete (lock clear vs ingestion+flush+compaction); minimal arm = narrower (clear vs ingestion). A gap-exposer built to crack minimal's narrower fix held 4/4 (background compaction never accumulates under continuous clear). By every empirical test the fixes are equivalent.

5 instances, 0 existence cases. The honest synthesis: the graph is not decoration, but it's also not pass/fail-necessary, for two compounding reasons: (1) selection artifact - the pipeline's triage routes easy/reproducible bugs past the graph; (2) BASELINE REACH - GPT-5.5 through the minimal mini-SWE-agent scaffold diagnosed and fixed a real storage-engine race that the pipeline skipped. The baseline is far stronger than assumed; that, not graph weakness, is why the graph rarely changes the verdict. Graph's residual demonstrated value collapsed to fix COMPLETENESS (more paths locked), which a single-reproducer oracle cannot score. Untested regimes: the review/audit loop, and localization-bottleneck bugs.

fjall #287 fix is validated and PR-ready (pilots/05-fjall-287/PR-READY.md + graph_src.patch); open when a box is up. Boxes torn down.

### 00:30 - Pilot 06 (bat #3710, localization region): NULL. 6 instances, 0 existence cases.

Refined target after the baseline-reach finding: the graph's only mechanism is diagnosis, so its frontier band (if any) is LOCALIZATION-hard bugs (symptom far from cause), not implementation-hard ones. Hunted warm Rust repos; cubecl compiler bugs need software-Vulkan (lavapipe) - too heavy. bat #3724 (man-page stray reset) was the genuine localization-hard pick but did NOT reproduce at HEAD (likely fixed). Ran bat #3710 (moderate localization, clean oracle) as the available test.

#3710 NULL: both arms produced correct fixes (a decorations_enabled gate in app.rs config-building, NOT the printer where decorations leak). Minimal found it unaided = exactly the graph's predicted fix; +M same idea, more thorough. Anti-gaming oracle (--decorations=always piped must keep decorations) held.

Honest standing: 6 instances (sql-metadata, howsmyssl, qrtool, slang-server, fjall #287 wild-skipped race, bat #3710), zero existence cases. "Super effective" is dead - if it were, a crude A/B on a few random bugs would show it; instead nulls are free and a single existence case has resisted a long hunt. The live residual is "narrow conditional value" in a localization-hard band that (a) we have not decisively tested (the one strong candidate didn't reproduce; #3710 was too contained to misdirect the baseline) and (b) is being eaten from below by model capability and routed around by the pipeline's own triage. Recurring infra lesson: driving codex over the ssh-proxy starves its turn budget on multi-iteration runs; on-box codex is the fix for any future multi-instance hunt.

### 09:40 — DIVERGENCE CONFIRMED on flux #1613 (fluxbox2)

Reran the crashed graph (investigate-methodology) arm to completion: codex GPT-5.5, single-agent, no-gate, identical settings to minimal — only methodology differs. Produced a 19-node hypothesis graph + a root-cause fix (track mutable-borrow FIELD origins, write callee post-type back to the borrowed place; checker.rs+type_env.rs+place_ty.rs, 82+/20-). Three-way oracle, same box/build: T1 #1613 both VERIFY; T2 int-field receipt (receipt_int.rs) GRAPH=VERIFY, MINIMAL=E0999 (the discriminator — minimal's function-sort gate is over-narrow, rejects a valid composite-int program); T3 unsound len-- twin both correctly E0999; graph-arm full compiletest suite 0 failed. First true divergence across 9 instances — exactly the predicted regime (not pass/fail on the original, but correctness/completeness invisible to the oracle, only a receipt settles). Per operator standard (they have to prove it), AUDITED not trusted: replayed load-bearing nodes on a pristine base build — H2 E0999, H4/H5/H6 differential all VERIFY as claimed, H7 constraint dump shows FoldLocal@23:9 at predicted location. Graph self-corrected 3x in its own trail (H9 installed-binary error, H10 unsound first fix via own bad_len probe, H14 over-broad propagation breaking local_ptr00). Calibrated: n=1, decisive on this instance; first proof the methodology produced a materially better (general+sound) fix than minimal on same model WITH replayable reasoning. Updated pilots/08-flux-1613.md RESOLUTION section. Box still up (6h watchdog).

Accountability note recorded in-session: I overstated the skill as "super effective / a real achievement" in a prior session without the adversarial A/B; that inflation is the thing this experiment corrected. The number is the artifact now.

### 11:45 — flux #1613 fix shipped to maintainers: hardened, dual-judge audited, public ledger, comment posted

Took the graph-arm fix from "wins the A/B" to "in front of the maintainers."

- HARDENED to merge-ready (graph H19-H24): write-back composes across sequential setters, generalizes to nested field projections, preserves plain `&mut` checking; conformed `FxHashMap`->`UnordMap` to match `type_env.rs` `local_names` and the recent #1632/#1633 determinism PRs; full basic + with-deps suite 0 failed.
- DUAL-JUDGE AUDIT (graph H25-H26): Opus 4.8 + GPT-5.5 audited all 25 nodes blind, per-node, for inferential soundness. Both families CONVERGED from different angles on the field-projection gate (H15) as the one load-bearing UNPROVEN step (a syntactic proxy for "an enclosing fold rechecks the invariant"). Tested every constructible escape shape with the invalid len-shrinking setter: E1 no-ensures, E2 plain-ensures, N1 nested-negative (the missing twin codex flagged), N3 free-fn -> all correctly REJECT; N2 enum-variant field inexpressible (E0433). Residual: empirically discharged, not formally proven -> flagged FOR the maintainers in the comment.
- PUBLISHED github.com/kimjune01/hygraph-mechanism PUBLIC (full transparency per user: "merit discriminates no substrate"; "silicon in verba"). Dual license: CC BY-SA 4.0 for content, All Rights Reserved for code so the fix hands to flux under their license without copyleft poisoning. Frozen tag `flux-1613-trail-v1`, permalink HTTP-200 verified.
- COMMENT POSTED to flux #1613 (issuecomment-4669497718) as kimjune01. Matched the thread's quote-and-respond tone (answered ranjitjhala's "something simpler", mapped nilehmann's step 4/5, their vocab), surfaced the honest gate caveat to the fold-machinery experts, plain LLM disclosure. Review pipeline: codex-sniff (cut the "no longer too late" overclaim + fixed the disclosure) -> em-dashes converted to voice -> /not-but (0 cuts, both negations EARNED per subagent triage). Caught + corrected a "verified by hand" lie in the PR draft mid-session (we verified by replay/oracle/suite, not by hand). Issue 22d old, 12d quiet (debate stalled at "Agree 100%").
- PR ON HOLD per user: get a maintainer response first. Branch staged, merge-ready.
- Frame: flux (refinement types) named as a contribution lane aligned with the attestation thesis (compiler = substrate-blind verifier, proof obligation = receipt). ATTESTATION-displacing-trust.md written this session; the whole experiment now public as the accountability ledger.
