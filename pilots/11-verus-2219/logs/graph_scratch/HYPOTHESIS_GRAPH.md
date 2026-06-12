# Hypothesis Graph: issue 2219

## H0 Observation
- reported.rs: REJECTED before patch with Rust E0382 "use of moved value: `t`".
- reasoning mode: induction (ran verifier).
- trajectory: divergent from issue text as written in this checkout; Rust borrowck catches the generic non-Copy double move.
- next edge: test whether Rust E0382 is incidental by varying the underlying tracked type/resource copyability and never-expression shape.

## H1: The erased `!` expression is still load-bearing, but plain Rust catches non-Copy double moves
- abduction: if the root problem is erased ghost `!` creating unreachable/broken MIR, then variants with Copy underlying values may avoid E0382 and expose acceptance or MIR breakage.
- perturbation copy_int_no_never.rs: remove `!`, use tracked int twice.
  - observed: VERIFIED, 0 errors.
  - verdict: double use of Copy proof value is not a tracked-linearity counterexample by itself.
  - trajectory: kill for "all tracked values are affine regardless of type".
- perturbation copy_int_never.rs: add `test(arbitrary())` with erased `!` before tracked int double use.
  - observed before patch: "verification results:: 3 verified, 0 errors" followed by rustc internal compiler error "bad arg #0 (! <- ())".
  - verdict: confirms erased `!` can corrupt MIR/control-flow even when E0382 is not available.
  - trajectory: convergent toward erased ghost never value as root.
- perturbation generic_copy_never.rs: generic `T: Copy` with same erased `!`.
  - observed before patch: same verified-then-ICE behavior.
  - verdict: concrete `int` is incidental; Copy generic follows same path.
  - trajectory: convergent.

## H2: The particular source expression producing `!` may be incidental
- perturbation never_let_binding.rs: bind `let x: ! = arbitrary(); test(x);`.
  - observed before patch: REJECTED, "never-to-any coercion is not allowed in spec mode".
  - verdict: explicit NeverToAny adjustment already rejected; direct erased call in argument position is the uncovered path.
  - trajectory: kill for "all never coercions are uncovered".
- perturbation never_if_arg.rs: `test(if b { arbitrary() } else { arbitrary() });`.
  - observed before patch: REJECTED, "never-to-any coercion is not allowed in spec mode".
  - verdict: branch coercion path already rejected.
  - trajectory: kill for "if shape is essential"; uncovered direct call remains.
- perturbation tracked_wrapper.rs / concrete_tracked.rs: vary resource shape while keeping non-Copy.
  - observed before patch: REJECTED with E0382.
  - verdict: non-Copy resource shape is incidental because Rust borrowck already rejects it in this checkout.
  - trajectory: divergent from unsound acceptance but compatible with root condition being masked.

## H3 Root Cause
- deduction: static spec calls are recorded as ResolvedCall::Call and later mapped in erase.rs to CallErasure::Call(NodeErase::Erase) when the callee mode is spec, or exec-in-ghost autospec. The MIR-builder erasure hook replaces such calls with `erased_ghost_value` using the original Rust type. If that type is `!`, the injected verifier-only value has Rust never type and can terminate or break the MIR path.
- deduction: dynamic spec function calls use ResolvedCall::SpecPure and follow the same erased-call principle.
- confidence: high for direct static spec calls, medium for dynamic spec calls by code inspection.

## H4 Fix
- implementation: reject erased ghost calls whose adjusted Rust type is `!` during VIR call translation, before erasure hints reach MIR construction.
- files: source/rust_verify/src/fn_call_to_vir.rs and source/rust_verify/src/rust_to_vir_expr.rs.
- expected: invalid direct erased-`!` variants now get a user-facing error; real proof/exec diverging calls are not rejected because they are not erased ghost calls.

## H5 Verification Status
- formatting: ran `cargo fmt --package rust_verify` successfully.
- attempted rebuild: `source ../tools/activate && vargo build --release`, and sanitized `env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH zsh -lc 'source ../tools/activate && vargo build --release'`.
- observed: both rebuilds fail in rustc_mir_build before reaching patched rust_verify, starting with E0463 "can't find crate for rustc_abi" and many missing rustc_private/diagnostic macro follow-on errors.
- blocker: this environment cannot rebuild the verifier despite rust-toolchain.toml listing rustc-dev. Therefore post-patch single-file verifier runs and `vargo test -p rust_verify_test --test lifetime` could not be executed against the patched binary.
- pre-patch over-rejection probes: legit_external_diverge.rs and real_return_overreject.rs both VERIFIED, 0 errors using the prebuilt verifier.
