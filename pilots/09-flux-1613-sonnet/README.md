# Pilot 09 — flux #1613 divergence, multi-model replication

**Question.** Pilot 08's one existence case was a divergence between the *minimal* arm
and the *graph/investigate* arm on flux #1613, run with **codex GPT-5.5** on both arms.
Does it reproduce on other models? If the minimal arm keeps failing and the graph arm
keeps winning across model families, the effect is a property of the *methodology*, not
of one model.

**Design.** Same base commit (`68d61714`), same blind issue text (#1613 body only), same
toolchain, same three-way oracle. Per model, two arms differing ONLY in the prompt:
minimal (mini-SWE-agent) vs graph (hypothesis-graph / investigate). The model is held
fixed within a pair, so any craft-side contamination cancels and only the methodology
varies.

**Models run:** GPT-5.5 (pilot 08, codex CLI), Sonnet 4.6 (Claude subagent harness),
Composer 2.5 + Fable 5 (cursor-agent headless). Harness differs by model, so the clean
signal is the *within-model* min-vs-graph differential, not cross-model absolutes.

**Result + contamination analysis: see [`RESULTS.md`](RESULTS.md). Artifact map: see
[`MANIFEST.md`](MANIFEST.md).** Headline: every minimal arm reaches the same over-narrow
Func-gated fix (T2 fail); the graph arm's rescue toward general+sound scales with model
capability.

---

## How to reproduce (local, no EC2)

### 0. Prereqs
- macOS arm64 (recipe is for Darwin-arm64; swap the prebuilt URLs for Linux).
- `rustup`, `z3` (`brew install z3`), and a GitHub-reachable network.

### 1. flux toolchain
```bash
git clone https://github.com/flux-rs/flux.git ~/Documents/flux
cd ~/Documents/flux && git checkout 68d61714
# prebuilt SMT helper (z3 already on PATH):
curl -fsSL https://github.com/ucsd-progsys/liquid-fixpoint/releases/download/nightly/fixpoint-aarch64-apple-darwin.tar.gz \
  | tar xz -C ~/.cargo/bin && chmod +x ~/.cargo/bin/fixpoint
```
The repo pins `nightly-2025-11-25` + rustc-dev via `rust-toolchain.toml`.

### 2. PATH gotcha (the one non-obvious step)
On this machine `~/.cargo/bin/cargo` is a stale standalone binary and `/opt/homebrew/bin/cargo`
is stable — neither understands `cargo xtask`'s internal `cargo +nightly-2025-11-25` directive.
Reconstruct a rustup-proxy shim dir and put it first on PATH, with `RUSTC`/`RUSTUP_TOOLCHAIN`
unset, for every build/grade command:
```bash
mkdir -p /tmp/rustup-shims
for p in cargo rustc cargo-flux rustfmt; do ln -sf "$(command -v rustup)" /tmp/rustup-shims/$p; done
# usage prefix for ALL cargo invocations below:
#   env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH cargo ...
```
(If your `~/.cargo/bin/cargo` is the normal rustup proxy, you can skip this.)

### 3. Build + sanity-check the base bug
```bash
cd ~/Documents/flux
env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH \
  cargo xtask run oracle/t1_issue1613.rs   # expect: error[E0999] (base reproduces the bug)
```
`cargo xtask run <file.rs>` is the single-file grader (verifies one program; prints
`error[E0999]` on failure, a clean `summary.` line on success).

### 4. The oracle (`oracle/`)
- **T1** `t1_issue1613.rs` — the reported program (function-sort composite). base E0999;
  any fix that addresses the reported case → VERIFY. Cannot separate the arms alone.
- **T2** `t2_receipt_int.rs` — the DISCRIMINATOR. A *valid* program that triggers the same
  fold bug with NO function sort: composite `(len:int, ctr:int)`, the setter updates a
  component (`ctr+1`) while preserving the field invariant `slot.len > 0`. base E0999,
  over-narrow fix E0999, general fix VERIFY. (Reconstructed and re-validated against the
  original GPT-5.5 patches — see "instrument check" below.)
- **T3** `t3_unsound_twin.rs` — the SOUNDNESS guard. A setter that shrinks `len` to 0,
  violating `slot.len > 0`. Must E0999 in every arm; an arm that VERIFIES it is unsound.

Grade any flux checkout against all three:
```bash
bash oracle/grade.sh ~/Documents/flux     # prints VERIFY / E0999 per test
```

### 5. Instrument check (do this before trusting any new arm)
Apply the two original GPT-5.5 patches to clean checkouts and grade — confirms the oracle
still registers the pilot-08 divergence (min: T2 E0999, graph: T2 VERIFY; both T3 E0999):
```bash
git apply ../08-flux-1613/minimal_solution.patch      && bash oracle/grade.sh .   # T2 E0999
git checkout -- . && git apply ../08-flux-1613/graph_arm/graph_arm_src.patch \
                                                       && bash oracle/grade.sh .   # T2 VERIFY
git checkout -- .
```

### 6. Run an arm (blind), capture the patch, grade, reset
Each arm gets ONLY the issue text + environment, never the fix. Drive any model/harness on a
clean base; the prompts are model-agnostic. Example with cursor-agent (Composer/Fable):
```bash
git checkout -B arm 68d61714
env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH \
  cursor-agent -p "$(cat /tmp/<arm>-prompt.txt)" --model <model-id> --force
git diff > <model>_<arm>.patch          # CAPTURE before reset — this is the load-bearing artifact
bash oracle/grade.sh ~/Documents/flux   # grade
git checkout -- . && git clean -fdq     # reset to clean base for the next arm
```
The two prompts (minimal, graph) are the only thing that differs between arms; keep the
issue text, environment instructions, boundaries, and model fixed. Boundaries forbid reading
git history/branches/the web, and confine edits to `crates/` (non-test). #1613 is unmerged
upstream, so no gold fix exists to leak; the minimal arm doubles as a memorization probe
(if the model had the real fix in weights it would emit it here — it doesn't).

### Re-grade a saved patch later
```bash
git checkout 68d61714 && git apply <model>_<arm>.patch && bash oracle/grade.sh .
```
Patches are the durable artifact; scratch trails are incidental. All saved patches are listed
in [`MANIFEST.md`](MANIFEST.md).
