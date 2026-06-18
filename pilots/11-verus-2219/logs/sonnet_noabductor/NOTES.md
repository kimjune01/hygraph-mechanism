# Sonnet 4.6 · no-abductor arm — NOTES

**Cell:** Sonnet · no abductor (fills the grid's provisional cell).
**Date:** 2026-06-18. **Harness:** claude-headless (`claude -p`, model `sonnet`), 4h budget (natural stop ~31 min, rc=0).
**Prompt:** `prompts/minimal_v3_fable.txt` (byte-identical to `local/minimal_v3_fable.txt` on the dev box) — generality + adversarial self-attack, **no** "build a generator/gate", keepalive baked in. No `--append-system-prompt`.
**Launcher:** `run.sh` (exact command used). **Patch:** `../../patches/sonnet_noabductor.patch` (+22/−1, one file).

## Result — **NARROW** (forced-fresh, identity-verified: `tools/clean_regrade.sh`, bin_fp `15c3f62374a3692a`, rebuilt=true)

| metric | value |
|---|---|
| case-check changed | **114** (< 269 ⇒ NARROW) |
| valid-bug-still-accepted | 155 (114+155=269 ✓) |
| valid-preserve-rejected | 0 (no over-rejection) |
| crash | 0 |
| cc.pass | false |
| battery t1 | REJECT ✓ (reported case fixed) |
| battery t2 | VERIFY ⚠ (empty-enum bug still accepted) |
| battery h2_assoc / h2_nested | VERIFY ⚠ / VERIFY ⚠ (out-of-grammar held-outs still accepted) |
| battery t3 | VERIFY ✓ (in-bar divergence preserved) |
| battery ho5 | VERIFY ✓ (stretch divergence preserved) |

Grade record: `grade.jsonl`, `grade.md`, `grade.console`.

## Mechanism — narrowest mode gate on the spectrum

The fix edits `lint_and_remove_uninhabited` (`source/rustc_mir_build/src/builder/mod.rs`): resolve the
`erased_ghost_value` **diagnostic-item DefId** and skip the `*target = None` CFG-edge removal **only for calls
to that one function**. So it preserves the borrowck-visible edge exactly when the uninhabited value flows
through Verus's `erased_ghost_value` erasure placeholder.

That catches the 114 bug cases routed through `erased_ghost_value`, but the other 155 unsound cases (empty-enum,
native-enum, array, tuple producers — the `t2`/`h2` shapes) reach uninhabitedness by paths that don't go through
`erased_ghost_value`, so the edge is still pruned and the double-consume slips through. Hence t2/h2 VERIFY.

Placement on the generality spectrum (all gate the same CFG-edge decision, at different widths):
- **this arm (Sonnet, no abductor):** gate on **one named function** (`erased_ghost_value`) → NARROW (114).
- **Fable / Sonnet gate2 / Composer:** gate on **all ghost-mode calls** → near-A (changed=269).
- **codex (tool):** gate on **inhabitedness query** → 269 on the bug axis.

Not over-conservative at all (t3/ho5 verify, preserve-rejected=0) — **clean but incomplete on the bug axis**.
Without an abductor/gate pushing generality, the model locked onto the single diagnostic item it found and
stopped self-attacking (it never constructed the empty-enum / non-`erased_ghost_value` unsound variants).

## Contamination — clean

`contamination.txt`. 0 real forbidden ops in the agent's Bash commands (no git history, no fetch/curl/wget, no
network). Sonnet 4.6 cutoff Feb 2026 < #2219 opened Mar 2026. (The raw step-7 grep count of 8 was entirely the
session-init tool manifest — "WebFetch"/"DesignSync" matching `fetch`/`origin` — not agent actions.)

## Operational notes (two traps hit, both known)

1. **Stale-binary trap (hard gate did its job).** The on-disk base binary was a stale **fixed** build — first
   t1 check ERRORED ("use of moved value"). Forced-fresh rebuild (touch `rustc_mir_build`+`rust_verify` →
   `vargo build`) restored base, which then wrongly-accepts t1 (`3 verified, 0 errors`). Recalibration reproduced
   base exactly: `valid-bug=269 valid-preserve=1794`. The runbook's step-3 build line assumes `vargo` is already
   on PATH; in a non-activated shell it exits 127 silently — prepend `$WT/tools/vargo/target/release`.
2. **`local/clean_regrade.sh` calibration-path trap (the recurring one).** `CC="$(dirname "$0")"` resolves the
   **local copy** to `local/`, which `setup.sh` never seeds with `calibration.json`, so case-check errors instantly
   → `pass=NA changed=0` and a 23s "grade" that looks complete. Use the tracked `tools/clean_regrade.sh`
   (CC=`tools/`, has calibration.json). Same lesson as the 2026-06-13 entry: **grade against tracked files, not
   generated/scratch copies.**
