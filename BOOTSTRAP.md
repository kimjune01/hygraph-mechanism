# Bootstrap — continue the hypothesis-graph mechanism experiment

Paste this into a fresh session to resume.

---

You are continuing a **mechanism-paper experiment** in `/Users/junekim/Documents/hygraph-mechanism` (git repo, clean, ~9 commits). Read these first, in order: `README.md`, `OPERATIONS.md`, `docs/INHERITED-DISCIPLINE.md`, `pilots/01-sql-metadata.md`. Then `data/instances.jsonl` (+ `data/SCHEMA.md`) and `data/recipes.jsonl`.

**The claim (narrow, bold, existence — not a rate):** a hypothesis-graph diagnosis artifact makes a code-fix agent (`craft`) succeed where `craft-only` fails, on merged GitHub bugs whose merge-certified test is the gold oracle. The graph is the *artifact under test*; the skill that generates it (`investigate`/`recon`) is the *mechanism*. SWE-bench Pro can't measure this (cheap oracle → gate compensates → craft-only ≈ recon); the deployment regime (real bugs, no spec, human-merged) can.

**Design invariants — do not let these drift:**
- Grade by the **merge-certified test** (red-at-base / green-on-gold). Merge = valid mechanical oracle; certify a +M *win* with a light degenerate-patch check (test-shaped hack?), not a heavyweight audit.
- **Run-handle, not test body**: craft gets a pass/fail script, never the assertion source (input oracle-leak guard).
- **Regenerate the graph blind** with a **pre-cutoff model** (Opus 4.7 / Sonnet 4.5). The graph is the *treatment*, so generator contamination does NOT cancel in the differential. Historical graphs in `sweep/repo-hypotheses/` are *targeting only* — many are reinvestigate/review-response artifacts that quote the maintainer's fix (pilot 01 caught one). Treat as contaminated unless pre-submission-snapshotted.
- Capture **source-only** diffs (exclude test dir). Same craft model across all arms.
- Ladder: **craft-only / +T / +G / +M** (reuse frozen prompts `swebench-pro/skills/{minimal,generic,recon}`). Negative controls: **flat-graph** and **shuffled-graph** (gap must track diagnostic fit, n=29 frame). Existence not rate. **Commit the null**: if craft-only passes everywhere, the graph is redundant and the thesis fails — report it.

**Selection (pilot-01 correction):** craft-only failure is the selector, NOT historical graph topology (false difficulty signal). 

**IMMEDIATE NEXT STEP: the craft-only selection sweep.** Run craft-only (pre-cutoff model) across the 24-instance pool (`data/instances.jsonl`, `regen_eligible==true`); the instances where craft-only **fails** are the existence-case candidates. Test the +M ladder only there. Each instance: `tools/gold_grade.sh` to validate red/green, then the pilot-01 harness pattern (`pilots/01-sql-metadata/check.sh` = run-handle; agent workdir at `merge_sha^1` with no test patch; separate grade dir at base+testpatch).

**Infra:** heavy repos (wild, slang-server, the tier-2 tail) don't fit locally — use boxes. Reuse the Pro fleet: `swebench-pro/driver/provision_box.sh`, `ablation_fleet.sh` (swap arms via `ARM_RUNNER`/`ARM_LEDGER`), `box_health.sh`, `drain_boxes.sh`. The one bespoke piece per repo is a build+test recipe (no prebuilt image like Pro had). One box per repo; self-terminate watchdog always; warm OAuth per box (~8h expiry); git-init so codex doesn't refuse the dir.

**Gotchas:** macOS bash 3.2 (no `mapfile`); `git diff HEAD` not `git diff` (checkout stages changes); `gh` secondary rate-limit on bursts (pace ~0.7s, retry/backoff); `rm -rf` blocked by hook (clone into fresh dirs); models on Max = $0, EC2 is the only marginal cost (~$0.20/box-hr).

**Logging:** append milestones to `worklog/WORK_LOG.md` (`### HH:MM — summary`, get time from `date`). Commit as you go. Send the design to codex (`codex exec -c model="gpt-5.5"`, no roleplay) when you change it.
