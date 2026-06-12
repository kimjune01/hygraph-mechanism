# Pilot 11 (Verus #2219) — resolved result & decision doc

*Status: exploratory, n=1. This supersedes two earlier headlines ("tabulated", then "general-with-gap") that were **stale-binary artifacts** — the vendored `rustc_mir_build` crate does not rebuild on plain incremental `vargo build`, so the pilot harness graded a partial binary on the held-out step. All numbers below are from **forced-fresh, identity-verified** rebuilds (touch sources → rebuild; VDBG instrumentation confirms binary identity).*

## The trustworthy table (forced-fresh base + patched builds)

| probe | base | model fix | #2501 | #2230 | correct | note |
|---|---|---|---|---|---|---|
| t1 (`!` bug) | VERIFY | REJECT | REJECT | REJECT | REJECT | ✓ |
| t2 (empty-enum bug) | VERIFY | REJECT | REJECT | VERIFY | REJECT | ✓ beats #2230 |
| h2_assoc_proj (`<u8 as Tr>::A`=Void) | VERIFY | REJECT | REJECT | — | REJECT | ✓ **out-of-grammar**, via real query |
| h2_generic_nested (`G<G<Void>>`) | VERIFY | REJECT | REJECT | — | REJECT | ✓ **out-of-grammar**, via real query |
| t3 (legit divergence) | VERIFY | **REJECT** | VERIFY | VERIFY | VERIFY | ✗ **over-rejects** |
| ho5 (sound divergence) | VERIFY | **REJECT** | — | — | VERIFY | ✗ **over-rejects** |

case-check on the forced-fresh patched binary: `pass=true, changed=269 exactly, valid-preserve-rejected=0, crash=0`.

## What's established (reproducible)
1. **The tool lifted codex to a GENERAL fix on the bug axis.** Six prompt-encoded methods stayed on the narrow `!`-slice (0/12). The case-check-driven fix flips exactly the 269-case bug-set AND catches both **out-of-grammar** held-outs (projection, nested-generic) — same bug coverage as the maintainer's general fix `#2501`.
2. **It is induction of the represented predicate, not tabulation.** Proven from source, not from the metric: the discriminator is `ty_is_visibly_uninhabited(ty) = !ty.is_inhabited_from(tcx, parent_module, typing_env)` — rustc's real inhabitedness query. VDBG shows the projection `<u8 as Tr>::A` arrives **already normalized to `Void`** (`uninhab=true`), and `G<G<Void>>` → `uninhab=true`. The grammar cases pass because the real oracle handles them.
3. **One real residual flaw: over-conservatism on genuine runtime divergence.** The fix over-rejects `t3` and `ho5` — both base-VERIFY (sound), and `#2501` verifies `t3`. It synthesizes a non-diverging placeholder for *any* visibly-uninhabited erased result, so it keeps the return edge even for a function that genuinely diverges, making post-divergence code wrongly reachable → it flags the later linear use.
4. **case-check has a preserve-side blind spot.** Its 2856-case grammar has no "legit divergence with post-divergence linear use" preserve shape, so it certifies `pass=true` on a fix that over-rejects that shape. The hand-written held-outs `t3`/`ho5` caught exactly this — held-out methodology working as designed.

## XOR adjudication (your framing)
The target is a "fancy XOR": `{rustc-uninhabited & ghost-erased ⇒ keep edge}` vs `{genuine runtime divergence ⇒ prune edge}`. The model **solved the first arm in full generality** (the inhabitedness query) but **failed the second** — it keeps the edge for runtime-real divergence too, collapsing that arm to an OR. So the XOR is **half-solved**: general on the inhabitedness side, over-conservative on the divergence side — and **the tool's gate never even tested the second arm.** This refines "the model can't do reliable XOR": with the prosthesis it got one arm completely; the other arm it missed, and the gate didn't demand it.

## Highest-leverage next perturbation (supersedes the 6-draw rate prereg)
**Close case-check's preserve blind spot** — add the runtime-real-divergence-preserve shape to the grammar — and re-run the loop. This tests the *mechanism*, not just a rate:
- **(a)** The model now carves out divergence → solves the full XOR with the prosthesis → strong positive ("the gate, once complete, induces the full predicate").
- **(b)** The model thrashes / can't satisfy both arms (oscillatory trajectory) → the divergence-discrimination is beyond reach even with the gate → the XOR-incapacity is real and localized to that one arm.

Either outcome is publishable, and it's cheaper and more diagnostic than 6 blind draws.

## Still-open validity threats (Fable's gate — unchanged, gate any publication)
1. **Hint-leak control C1** — static labeled cases, no execution loop, one shot. Tells whether the *loop* or the *labeled corpus* did the work.
2. **Sealed battery on all 13 patches** (12 prompt + 1 tool) — the fair head-to-head; current "0/12 vs pass=true" is across different success criteria.
3. **#2501 gate-validity (K3)** — rebuild #2501 at the calibration toolchain and confirm it passes the gate; if the true general fix fails our gate, gate-based claims are void.
4. **n=1.** One draw can't separate "reliably produces such a fix" from "lucky."

## Decision for you
Recommended order when you're back: **(1)** the blind-spot perturbation above (cheap, mechanism-level, directly tests your XOR claim); **(2)** then C1 + sealed battery + #2501 gate-validity before treating any of this as a result. The 6-draw rate prereg is worth running only after (1) tells us whether the full XOR is even reachable with the prosthesis.
