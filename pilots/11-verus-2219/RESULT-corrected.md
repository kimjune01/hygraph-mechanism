# Pilot 11 (Verus #2219) — resolved result & decision doc

*Status: exploratory, n=1. This supersedes two earlier headlines ("tabulated", then "general-with-gap") that were **stale-binary artifacts** — the vendored `rustc_mir_build` crate does not rebuild on plain incremental `vargo build`, so the pilot harness graded a partial binary on the held-out step. All numbers below are from **forced-fresh, identity-verified** rebuilds (touch sources → rebuild; VDBG instrumentation confirms binary identity).*

> **Update (2026-06-13) — the predicted perturbation was run, then extended to four workflows.** The "highest-leverage next perturbation" below (close case-check's preserve blind spot by adding a divergence-preserve golden) became the **gate2 corrected gate** (`gate2/` adds `p1`/`p2`, human-approved divergence goldens). Result, graded forced-fresh and cross-checked against the goldens:
> - **Mode-gate mechanism confirmed across families.** Three model+harness workflows reach **near-A** with the *same behavioral carve-out* (keep the CFG edge for ghost/proof calls, prune only genuine divergence): Fable (clean), Composer 2.5 (dirty), Sonnet 4.6 (clean). Composer's *implementation* differs (THIR-erasure `!`→`()`), but the behavior is the same carve-out. This corroborates point 2 (mode gate, not the inhabitedness query) on three independent fixes.
> - **The XOR's second arm is now partly cleared, but coverage-bounded.** Given the `p1` divergence golden, the near-A fixes carve out the *calibrated* divergence shape (declared-`!`/`requires_false`) and verify the sealed twins — but all three still over-reject the *un-calibrated* `ho5` (generic-instantiation `mk::<!>()`). So outcome (a) below holds within the gate's coverage; the gate lifts the model exactly as far as it calibrates.
> - **codex still walls — fairness-controlled.** codex (codex-CLI) does not pass under either the original 2.5h run *or* a protocol-matched 4h rerun (pass-snapshot + keepalive). It fails the divergence golden `p1` in both; the matched run reaches `mishandles=0` on the bug arm but over-rejects `p1` as `crash=1250`. So the failure *mode* was budget-dependent (oscillation → crash) but the divergence wall is robust.
> - **Contamination (scoped).** Recall is *not required* for this fix-class (two clean models reach it); it is *not excluded* for Composer (ships 2026-05-18, no attested cutoff). The finer human gold `#2501` clears `ho5`; no automated arm does, evidence each landed on the gate-attractor, not the gold.
>
> Full result + adversarial (codex) review + corrections: [`../../RESULTS.md`](../../RESULTS.md) (four-workflow table), [`../../LESSONS.md`](../../LESSONS.md) (7, 13), [`logs/codex-review-2026-06-13.md`](logs/codex-review-2026-06-13.md), and the [`WORK_LOG`](../../worklog/WORK_LOG.md) entries dated 2026-06-13. Per-arm runs: [`logs/composer/`](logs/composer/), [`logs/sonnet/`](logs/sonnet/), [`logs/codex2/`](logs/codex2/).

## The trustworthy table (forced-fresh base + patched builds)

| probe | base | model fix | #2501 | #2230 | correct | note |
|---|---|---|---|---|---|---|
| t1 (`!` bug) | VERIFY | REJECT | REJECT | REJECT | REJECT | ✓ |
| t2 (empty-enum bug) | VERIFY | REJECT | REJECT | VERIFY | REJECT | ✓ beats #2230 |
| h2_assoc_proj (`<u8 as Tr>::A`=Void) | VERIFY | REJECT | REJECT | — | REJECT | ✓ **out-of-grammar** (mode gate) |
| h2_generic_nested (`G<G<Void>>`) | VERIFY | REJECT | REJECT | — | REJECT | ✓ **out-of-grammar** (mode gate) |
| t3 (legit divergence) | VERIFY | **REJECT** | VERIFY | VERIFY | VERIFY | ✗ **over-rejects** |
| ho5 (sound divergence) | VERIFY | **REJECT** | — | — | VERIFY | ✗ **over-rejects** |

case-check on the forced-fresh patched binary: `pass=true, changed=269 exactly, valid-preserve-rejected=0, crash=0`.

## What's established (reproducible)
1. **The tool lifted codex to a GENERAL fix on the bug axis.** Six prompt-encoded methods stayed on the narrow `!`-slice (0/12). The case-check-driven fix flips exactly the 269-case bug-set AND catches both **out-of-grammar** held-outs (projection, nested-generic) — same bug coverage as the maintainer's general fix `#2501`.
2. **It generalizes by a mode gate, not by enumeration — and (corrected) the inhabitedness query is *not* load-bearing.** This codex fix's discriminator reads `ty_is_visibly_uninhabited(ty) = !ty.is_inhabited_from(tcx, parent_module, typing_env)`, and VDBG confirms it fires (the projection `<u8 as Tr>::A` arrives normalized to `Void`). **Correction (2026-06-12, cross-model):** the inhabitedness query is *behaviorally redundant*. Fable's independent fix keeps the edge for **all** ghost-mode calls with **no inhabitedness query at all** and grades identically on every probe — including the out-of-grammar held-outs. Since only an uninhabited return prunes the CFG, the load-bearing mechanism in both fixes is the **mode gate** ("in ghost mode, keep the CFG edge so borrowck sees the following code"); the query adds nothing on these cases. So the earlier framing — "induction of the *represented predicate* / reached for the verifier's own oracle" — **overstates it**: the model reached a *mode-gated approximation*, not the inhabitedness oracle as the operative predicate. `#2501` is the genuinely finer method (separating erased-ghost artifact from real divergence), which neither automated fix captured.
3. **One real residual flaw: over-conservatism on genuine runtime divergence.** The fix over-rejects `t3` and `ho5` — both base-VERIFY (sound), and `#2501` verifies `t3`. It synthesizes a non-diverging placeholder for *any* visibly-uninhabited erased result, so it keeps the return edge even for a function that genuinely diverges, making post-divergence code wrongly reachable → it flags the later linear use.
4. **case-check has a preserve-side blind spot.** Its 2856-case grammar has no "legit divergence with post-divergence linear use" preserve shape, so it certifies `pass=true` on a fix that over-rejects that shape. The hand-written held-outs `t3`/`ho5` caught exactly this — held-out methodology working as designed.

## XOR adjudication (your framing)
The target is a "fancy XOR": `{rustc-uninhabited & ghost-erased ⇒ keep edge}` vs `{genuine runtime divergence ⇒ prune edge}`. The model **solved the first arm in full generality** (the uninhabited/ghost side, via the mode gate — *not* the inhabitedness query; see the correction above) but **failed the second** — it keeps the edge for runtime-real divergence too, collapsing that arm to an OR. So the XOR is **half-solved**: general on the inhabitedness side, over-conservative on the divergence side — and **the tool's gate never even tested the second arm.** This refines "the model can't do reliable XOR": with the prosthesis it got one arm completely; the other arm it missed, and the gate didn't demand it.

## Highest-leverage next perturbation (supersedes the 6-draw rate prereg) — ✅ RUN (gate2), result mixed by family
**Close case-check's preserve blind spot** — add the runtime-real-divergence-preserve shape to the grammar — and re-run the loop. This tests the *mechanism*, not just a rate:
- **(a)** The model now carves out divergence → solves the full XOR with the prosthesis → strong positive ("the gate, once complete, induces the full predicate").
- **(b)** The model thrashes / can't satisfy both arms (oscillatory trajectory) → the divergence-discrimination is beyond reach even with the gate → the XOR-incapacity is real and localized to that one arm.

**Outcome (2026-06-13):** both happened, split by workflow. With the `p1` divergence golden added (gate2), **Fable / Composer 2.5 / Sonnet 4.6 hit (a)** — they carve out divergence and pass the gate (near-A), *bounded by the gate's coverage* (they clear the calibrated declared-`!` shape + sealed twins, miss the un-calibrated `ho5`). **codex hits (b)** — no pass under either the original or a protocol-matched 4h rerun; it over-rejects `p1` (oscillation originally, `crash=1250` in the rerun). So "the gate, once more complete, induces the carve-out" is true for three workflows and false for the codex-CLI workflow. A *further* perturbation — adding an `ho5`-like generic-instantiation golden — remains the open test of whether the carve-out is gate-shaped (attractor) or genuine capability (see [`logs/codex-review-2026-06-13.md`](logs/codex-review-2026-06-13.md)).

## Still-open validity threats (Fable's gate — unchanged, gate any publication)
1. **Hint-leak control C1** — static labeled cases, no execution loop, one shot. Tells whether the *loop* or the *labeled corpus* did the work.
2. **Sealed battery on all 13 patches** (12 prompt + 1 tool) — the fair head-to-head; current "0/12 vs pass=true" is across different success criteria.
3. **#2501 gate-validity (K3)** — rebuild #2501 at the calibration toolchain and confirm it passes the gate; if the true general fix fails our gate, gate-based claims are void.
4. **n=1.** One draw can't separate "reliably produces such a fix" from "lucky."

## Decision for you
Recommended order when you're back: **(1)** the blind-spot perturbation above (cheap, mechanism-level, directly tests your XOR claim); **(2)** then C1 + sealed battery + #2501 gate-validity before treating any of this as a result. The 6-draw rate prereg is worth running only after (1) tells us whether the full XOR is even reachable with the prosthesis.
