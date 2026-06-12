# Abduction log for issue #2219

## 1. Bi-abduction setup

Required obligation after a call/expression in proof code:

`REQUIRED = Verus/Rust borrowck and linearity obligations for all post-expression statements reachable in the source program, including moved-use checks for tracked resources.`

Current state at the bug:

`CURRENT = MIR/THIR state after an expression typed as ! is lowered as does-not-continue; the normal post-expression edge is deleted, so post-expression statements are unreachable to borrowck.`

The entailment fails:

`CURRENT |-/- REQUIRED`, because the tracked variable `t` can be consumed twice after a ghost `!`-typed expression and borrowck never visits the second consume.

Bi-abduction asks for weakest anti-frame `P`:

`CURRENT * P |- REQUIRED * frame`

A deleted continuation edge is sound only if every source-level execution that reaches the expression also cannot continue past it. Therefore:

`P0 = the expression that removed the edge is semantically non-returning in the source program.`

Weakening against incidental features of the report:

- `P` is not "argument to a proof fn": the same obligation can be lost for erased ghost calls appearing as standalone statements, in blocks, assignments, match scrutinees, or other contexts.
- `P` is not "the syntactic function is arbitrary": any erased ghost/spec/proof expression with erased type `!` can synthesize a `!` value.
- `P` is not "generic tracked variable T is later moved twice": any post-expression borrow/linearity/lifetime obligation can be dropped.
- `P` is not "call syntax": `NeverToAny` can be reached by a call or inline asm, but Verus erasure creates synthetic `erased_ghost_value` calls.
- Fixpoint: the load-bearing condition is semantic reachability, not syntax. Deleting a post-expression control-flow edge is sound exactly when the expression is a real diverging computation, not a ghost-erased witness of an uninhabited type.

Abduced predicate:

`P(e) = e is a real source-level computation that cannot return normally; in particular, e is not Verus's synthetic erased_ghost_value witness used to preserve ghost-side checks after erasure.`

## 2. Tri-abduction over branch reachings

The does-not-continue branch can be reached through multiple constructs:

- direct lowering of a `NeverToAny` expression whose source is a call or inline asm;
- lowering of call-like expressions whose result type is `!`;
- other uninhabited-pattern/empty-match constructs that create `Unreachable` terminators.

Tri-abduction requires one shared condition `M` for the does-not-continue branch rather than separate syntactic conditions:

`P1 * F1 |= M` and `M |= P2 * F2`

Shared `M`:

`M = the no-continuation branch corresponds to actual semantic non-returning behavior of the source program, not merely to a type-level ! introduced by verifier erasure.`

This preserves real divergence (`loop {}`, `panic!`, real functions returning `!`, empty matches on genuinely uninhabited values) while preventing Verus-erased ghost witnesses from pruning reachable source statements.

## 3. Enforcement site

Changed `source/rustc_mir_build/src/builder/mod.rs`, function `Builder::lint_and_remove_uninhabited`.

This is where rustc's MIR builder removes a call's normal return edge when the destination type is uninhabited. The fix leaves the existing behavior intact for real calls returning uninhabited types, but does not remove the return edge when the call target is Verus's synthetic `erased_ghost_value` witness. That witness is an erasure artifact used to keep ghost-side checks alive; it is not semantic evidence that the source program cannot continue.

Added `source/rustc_mir_build_additional_files/verus.rs::is_erased_ghost_value_fn` so MIR construction can identify the synthetic erasure function by `DefId`.

## 4. Validation programs and verdicts

- `/tmp/p11abd-scratch/reported.rs`: reported issue. REJECTED with `error[E0382]: use of moved value: t`.
- `/tmp/p11abd-scratch/direct_never_stmt.rs`: unsound variant with a direct erased `arbitrary::<!>();` statement before double consume. REJECTED with `error[E0382]: use of moved value: t` (rustc also emits an unreachable-code warning).
- `/tmp/p11abd-scratch/unsound_other_tracked_arg.rs`: unsound variant where the `!` ghost argument is incidental and another tracked argument is consumed by the same call, then reused. REJECTED with `error[E0382]: use of moved value: t`.
- `/tmp/p11abd-scratch/unsound_let_never.rs`: unsound variant binding `let _x: ! = arbitrary();` before double consume. REJECTED with `error[E0382]: use of moved value: t`.
- `/tmp/p11abd-scratch/valid_ghost_never_arg.rs`: valid ghost `!` argument with no subsequent linearity violation. VERIFIED with `verification results:: 2 verified, 0 errors`.
- `/tmp/p11abd-scratch/valid_real_diverge.rs`: valid variant with real external-body proof diverger before later double consume; the later code is genuinely unreachable. VERIFIED with `verification results:: 2 verified, 0 errors` (rustc emits the expected unreachable-code warning).

## 5. Regression

Ran `cd /Users/junekim/Documents/verus-p11/source && env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH vargo test -p rust_verify_test --test lifetime`.

Result: `test result: ok. 94 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 5.30s`.
