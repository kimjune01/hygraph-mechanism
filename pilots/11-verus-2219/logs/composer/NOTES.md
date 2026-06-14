# Composer 2.5 — gate2 arm (in progress)

Repeat of the corrected-gate (gate2) capability probe, symmetric with the codex
and Fable arms. Same prompt (`prompts/gate2_arm.txt`), same verus-p11 checkout at
base `23dc6e754`, same committed gate (`gate2/gate.sh`, python3.13-pinned).

## Prior arms (the split this probes)
- **codex** (codex CLI): Outcome C — oscillated ~2.5h/17 evals, mishandles floor
  133 never broken while p1 preserved; the two XOR arms mutually exclusive across
  everything it tried. Wall = **implementation**.
- **Fable** (claude-headless, `model: fable`): near-A / PARTIAL. Given the p1
  divergence label, wrote a real ghost-vs-genuine discriminator; GATE pass=true;
  generalized to sealed held-outs; residual ho5 (un-calibrated generic-inst
  shape). Wall = **calibration**, not implementation.
- Composer 2.5 asks: which wall does it hit?

## Harness
Driver = `cursor-agent -p --force --model composer-2.5` (the only headless driver
for Composer 2.5). This is a **harness confound** vs codex (codex CLI) and Fable
(claude subagent) — flagged in WORK_LOG line 151 as fatal-for-ranking. The arm is
a capability *probe* (does it clear the implementation/calibration wall), reported
with the confound stated, not a clean head-to-head ranking. Pilot 09 already drove
Composer-2.5 via cursor-agent, so this is consistent tooling for the Composer family.

## NEW caveat — contamination (cutoff)
The graph-generator cleanliness argument (README) pins the *generator* to a
pre-cutoff model. Here Composer 2.5 is the **craft/solver** model. The fixes
(#2230 2026-03, #2501) may predate Composer 2.5's training cutoff (a current 2026
model), so a pass could reflect a **memorized fix**, not in-situ implementation.
Mitigations in place: the prompt forbids git history/branches/remotes and web; the
checkout has no reachable answer-bearing notes (no CLAUDE.md/.cursor/AGENTS.md);
gate internals are off-limits by instruction. But unlike the differential ablation,
this single-arm probe does NOT cancel residual memorization. Interpret a Composer
pass as capability-OR-recall; a *failure* is clean (memorized fix would only help).

## Grade plan (on completion)
```
./local/clean_regrade.sh /tmp/composer-grade.jsonl logs/composer/composer_gate2.patch
python3 tools/render_dataset.py /tmp/composer-grade.jsonl
# + sealed held-outs: gate2/sealed/
```
Buckets (REPRODUCE.md): GENERAL changed=269,h2 rejected,t3/ho5 verify ·
WIDE-BUT-BROKEN changed=269 but t3/ho5 over-rejected · NARROW changed<269 ·
Outcome C oscillates, never both arms.

## RESULT — Composer 2.5 = near-A / PARTIAL (same cell as Fable). [verified 2026-06-13]
Run: cursor-agent composer-2.5, ~1h (19:14→20:14Z), 553-line/7-file patch (`composer_gate2.patch`).
Self-report GATE pass=true — INDEPENDENTLY CONFIRMED by forced-fresh grade (bin_fp 22146aba7fb14123, rebuilt=true):
- Calibrated case-check: **pass=true, mishandles=0, valid-bug-still-accepted=0, valid-preserve-rejected=0** (bug arm general, 269/269; no calibrated over-rejection).
- Battery: t1/t2 REJECT, t3 VERIFY, h2_assoc/h2_nested REJECT, **ho5 REJECT** (over-rejects).
- Preserve: **p1 VERIFY, p2 VERIFY** — cleared the divergence golden codex oscillated on (Outcome C). IMPLEMENTATION WALL BROKEN.
- Sealed held-outs (never seen): **seal_proofdiv VERIFY, seal_exec VERIFY** — generalized, not tabulated.
- Residual: **ho5 over-rejected** — the un-calibrated generic-instantiation (`mk::<!>()`) divergence, IDENTICAL to Fable's residual.

PLACEMENT: codex(codex-CLI)=Outcome C (impl wall); Fable(claude-headless) & Composer-2.5(cursor-agent)=near-A
(impl cleared, calibration-bounded, same ho5 residual). The implementation wall is NOT universal — two of three families cleared it.

CONTAMINATION (load-bearing here; dates checked 2026-06-13):
- Base = Moonshot Kimi K2.5 (released 2026-01-27, pretraining cutoff reportedly ~Apr 2024). Base CANNOT hold the fix.
- BUT Composer 2.5 itself shipped 2026-05-18 — AFTER the verus fix (base commit 2026-03-08; #2230/#2501 later).
  Cursor's fine-tune / mid-training window (Jan–May 2026) OVERLAPS the fix's existence, so leakage via Cursor's
  training data cannot be excluded (RL/synthetic-task FT is an unlikely vector for recalling one public repo patch,
  but not impossible). NOT clean by release date.
- NO VENDOR ATTESTATION: Cursor states no knowledge cutoff for Composer 2.5 — neither the model docs
  (cursor.com/docs/models/cursor-composer-2-5) nor the official blog/tech report (cursor.com/blog/composer-2-5).
  They disclose only the Kimi K2.5 base checkpoint + post-checkpoint training (25× synthetic tasks + RL), no dates.
  So there is no cutoff to support a cleanliness claim; the FT window runs through the 2026-05-18 ship date.
- Verdict: Composer's pass = capability OR (less likely) fine-tune-recall. Sealed-VERIFY shows generalization, but a
  memorized mechanism generalizes too. Sonnet (claude-sonnet-4-6) is the cleaner arm IFF its cutoff predates the fix
  — verify its release/cutoff when grading that arm. Mechanism harness gremlins on this box (GNU-coreutils `stat -f`, missing default
calibration) corrupted clean_regrade's provenance/casecheck fields — bypassed via eval_full.sh (python3.13 + /usr/bin/stat
+ explicit --calibration). clean_regrade.sh should get the same portability fixes for clean repro.

## Date sources (added 2026-06-13 per codex review; sourcing the load-bearing cutoff claims)
- Composer 2.5 base = Kimi K2.5: Cursor blog "Introducing Composer 2.5" (cursor.com/blog/composer-2-5) states base checkpoint; NO cutoff attested (also confirmed absent on cursor.com/docs/models/cursor-composer-2-5).
- Composer 2.5 ship 2026-05-18: memeburn.com/cursor-composer-2-5-officially-launches/ ; techtimes.com (2026-05-20).
- Kimi K2.5 released Jan 2026 (base pretraining cutoff ~Apr 2024, secondary-source only): codecademy.com/article/kimi-k-2-5-... ; github.com/MoonshotAI/Kimi-K2.5.
- Sonnet 4.6: released 2026-02-17; training-data cutoff Jan 2026; reliable-knowledge cutoff Aug 2025 (secondary aggregation; cross-check against platform.claude.com/docs/en/about-claude/models/overview before publishing). ALL predate the verus fix (base 2026-03-08).
NOTE: these are secondary sources. Before any Zenodo/publication, replace with primary attestations (vendor model cards) or archive snapshots.
