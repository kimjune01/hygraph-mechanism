# Reproduce the verus #2219 Fable arm on another machine

The repo carries the prompts, the gate (case-check), the grading harness, and the held-outs. Three things are machine-local and must be rebuilt/regenerated locally: the verus checkout+build, the absolute paths baked into the prompt/scripts, and case-check's calibration (keyed to *your* base binary).

## 0. Prerequisites
- A Unix box with the verus build toolchain deps (rustup, the verus-pinned channel — `source/rust-toolchain.toml`, currently `1.93.1`), Python 3.11+.
- Claude Code (to run the Fable agent), or any way to drive a `model: fable` agent.

## 1. verus at the base commit
```
git clone https://github.com/verus-lang/verus
cd verus && git checkout --detach 23dc6e754fef0d238db808dad02cbe8e3d72f2b3   # base (pre-fix), 2026-03-08
# bootstrap the verus toolchain + build (creates the rustup shims + vargo):
source tools/activate            # or follow verus' README; this puts `vargo` on PATH
( cd source && vargo build --release )
```
Note your two env facts for later:
- `VERUS_WT` = the absolute path of this checkout (e.g. `/home/you/verus`).
- the run env verus uses — `vargo`'s dir (`$VERUS_WT/tools/vargo/target/release`) and the rustup-shims dir the build set up (on the dev box this was `/tmp/rustup-shims`; yours may differ — find it from `tools/activate`).

Confirm base reproduces the bug: it should VERIFY `oracle/t1_issue2219.rs` (i.e. wrongly accept it).

## 2. This repo
```
git clone https://github.com/kimjune01/hygraph-mechanism
cd hygraph-mechanism/pilots/11-verus-2219
```

## 3. Recalibrate case-check against YOUR base binary
`tools/calibration.json` was built on the dev machine; case behavior can shift with toolchain/build, so regenerate it:
```
python3 tools/case-check.py --calibrate --base-verus "$VERUS_WT/source/target-verus/release/verus" -o tools/calibration.json
```
Expect `valid-bug=269 valid-preserve=1794` (numbers may differ slightly on a different build — that's fine, the harness uses your calibration).

## 4. Generate machine-local prompt + scripts (path substitution)
```
./setup.sh "$VERUS_WT"
```
This writes `local/` copies of the Fable prompt and the grading harness with your paths substituted. Edit the rustup-shims path in `local/` if yours isn't `/tmp/rustup-shims`.

## 5. Run the Fable arm
Hand `local/<prompt>.txt` to a Claude Code agent with `model: fable`. Two prompts ship:
- `prompts/self_verifier.txt` — strong (tells it to build its own combinatorial gate). Result on dev box: built a 6684-case gate, WIDE-BUT-BROKEN.
- `prompts/minimal_v3_fable.txt` — weak (generality + adversarial self-attack, no "build a generator"). The open ablation.

Keepalive matters: verus rebuilds are slow and silent; the Claude Code Agent watchdog kills on ~10 min of no stream output. The `minimal_v3_fable.txt` prompt already bakes in the background-build-and-poll protocol — keep it.

For a clean run, pull any answer-bearing notes out of the agent's reachable memory/CLAUDE.md first (the dev box temporarily removed a memory file that named the fix mechanism). The fixes (#2230, #2501) post-date Fable's Jan-2026 cutoff, so the model can't have memorized them, but local notes can leak.

### 5b. The gate2 corrected-gate arm, across four model+harness workflows
The corrected gate (`gate2/gate.sh`, which adds the `p1`/`p2` divergence goldens) was run on four workflows with the shared prompt `prompts/gate2_arm.txt`. Each launcher is committed under `logs/<arm>/run.sh` and is the exact command used:
- **codex** (`gpt-5.5`, codex-CLI): original `gate2_codex_terminated.patch`; protocol-matched rerun `logs/codex2/run.sh` (4h + pass-snapshot + keepalive). Outcome: no pass in either (`crash`/oscillation on `p1`).
- **Fable** (`model: fable`, claude-headless): `fable_gate2.patch`. near-A.
- **Composer 2.5** (cursor-agent, `logs/composer/run.sh`): `composer_gate2.patch`. near-A.
- **Sonnet 4.6** (claude-headless, `logs/sonnet/run2.sh`): `sonnet_gate2_run2.patch` (the verified PASS-0 snapshot). near-A.

Grade these with the portable single-build evaluator `logs/composer/eval_full.sh <abs-path-to.patch>` (it pins `python3.13` + `/usr/bin/stat` + explicit `--calibration`, and probes battery + `p1`/`p2` + `gate2/sealed/` in one rebuild). **Contamination differs per model** — Fable and Sonnet 4.6 predate the fix (clean); Composer 2.5 ships 2026-05-18 with no attested cutoff (recall not excluded). See `logs/composer/NOTES.md` (date sources) and `RESULTS.md` for the four-workflow result.

## 6. Grade
After the agent leaves its patch in `$VERUS_WT`:
```
( cd "$VERUS_WT" && git diff > /tmp/fable_arm.patch )
cp /tmp/fable_arm.patch patches/
./local/clean_regrade.sh /tmp/fable-grade.jsonl patches/fable_arm.patch
python3 tools/render_dataset.py /tmp/fable-grade.jsonl
```
The harness does a forced-fresh rebuild (the vendored `rustc_mir_build` crate does NOT rebuild on plain incremental vargo — this is the stale-binary trap; the harness defeats it by touching sources) and grades the battery + case-check. Read the result against the buckets in `RESULT-corrected.md`:
- GENERAL: changed=269, h2 rejected, t3/ho5 verify.
- WIDE-BUT-BROKEN: changed=269 but t3/ho5 over-rejected.
- NARROW: changed<269.
- Also grade the sealed divergence held-outs in `gate2/sealed/` (the model never saw them).

## Grading #2501 (the human general fix) at its own toolchain — cross-toolchain

`#2501` (commit `455695049`) is built at **1.95.0**, not the base `1.93.1`. The base grading harness pins a custom `/tmp/rustup-shims` to 1.93.1, which mis-builds #2501's 1.95.0 source (105 rustc-internal errors). To grade it, **drop the custom shims and let rustup's proxies honor #2501's `rust-toolchain.toml`**. The reference script is [`logs/gold2501/build_grade.sh`](logs/gold2501/build_grade.sh); the recipe:
```
git -C "$VERUS_WT" checkout --detach 455695049            # #2501; brings rust-toolchain.toml=1.95.0
# build WITHOUT /tmp/rustup-shims on PATH; include ~/.cargo/bin (rustup proxies) so rustc resolves to 1.95.0:
( cd source && env -u RUSTC -u RUSTUP_TOOLCHAIN \
    PATH="$VERUS_WT/tools/vargo/target/release:$HOME/.cargo/bin:/usr/bin:/bin" \
    vargo build --release )
# grade each probe with the SAME clean PATH (not the 1.93.1 shims)
git -C "$VERUS_WT" checkout --detach 23dc6e75             # restore base when done
```
Result on the dev box (`logs/gold2501/build_grade.log`, `bin_fp=a12508cc`): t1/t2 REJECT, t3 VERIFY, h2×2 REJECT, **ho5 REJECT**, p1/seal_proofdiv VERIFY — identical 8-probe battery to the near-A fixes. **Caveat:** this is cross-toolchain, so only the 8-probe battery is comparable; #2501's full 269-case `case-check` is *not* co-gradeable against the 1.93.1 calibration. `ho5`'s ideal label is VERIFY, but every fix (incl. #2501) over-rejects it by design — it is out of the maintainer's bar and not scored (see `RESULTS.md`).

## Gotchas
- Vendored-crate staleness: always force-fresh (the harness does; manual builds must `touch source/rustc_mir_build/src/**`).
- Toolchain pinning: the fixes #2230/#2501 are at different toolchains (1.93.1 / 1.95.0); grade only same-toolchain artifacts together (see the #2501 cross-toolchain recipe above for the one exception, and its caveat).
- The box gets CPU-saturated: one arm at a time per machine; verus rebuild loops thrash if doubled up.
