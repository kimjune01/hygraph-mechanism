## H0: The reported symptom is emitted by the fold-checking path in `flux-refineck`
- null: Grepping the repository would show the message is emitted by unrelated code or many independent paths.
- perturbation: `pwd && rg --files | head -100 && rg -n "type invariant may not hold|when place is folded|place is folded|E0999" .`
- observed: command ran in `/home/ec2-user/flux`. The exact message text appears in `crates/flux-refineck/locales/en-US.ftl:34:    type invariant may not hold (when place is folded)`. The corresponding diagnostic type is `FoldError` in `crates/flux-refineck/src/lib.rs:345`. A nearby manually constructed `E0999` diagnostic appears in `crates/flux-refineck/src/checker.rs:2407` and `2429`. Existing negative tests reference similar invariant failures in `tests/tests/neg/structs/struct-fold-00.rs`, `tests/tests/neg/surface/impl03.rs`, `tests/tests/neg/structs/field-00.rs`, and `tests/tests/neg/error_messages/localize04.rs`.
- trajectory: divergent
- kill/confirm: confirmed enough to reduce the suspect surface to `flux-refineck` fold/invariant checking. Edge: reproduce the exact program and inspect the call sites that create `FoldError`.
- mode: abduction (75%)

## H1: The exact source can be run directly with `flux repro.rs`
- null: `flux repro.rs` would reach refinement checking and produce the reported `FoldError`.
- perturbation: `flux repro.rs`
- observed: `error[E0636]: the feature `register_tool` has already been enabled` at generated `<crate attribute>:1:12`, followed by `error: aborting due to 1 previous error` and `Error: process exited unsuccessfully: exit status: 1`.
- trajectory: divergent
- kill/confirm: killed as an invocation/source-shape issue, not a refinement-checking result. Edge: the `flux` wrapper injects crate attributes, so remove explicit `#![feature(register_tool)]` and `#![register_tool(flux_rs)]` from the standalone reproducer.
- mode: deduction (95%)

## H2: The wrapper-compatible reproducer reaches the reported fold invariant failure
- null: Running `flux repro.rs` after removing crate-level tool registration would verify or fail for an unrelated reason.
- perturbation: `flux repro.rs`
- observed: emitted four dead-code warnings, then `error[E0999]: type invariant may not hold (when place is folded)` at `repro.rs:23:9`, labeling `self.slot.set(0);`, followed by `error: aborting due to 1 previous error` and `Error: process exited unsuccessfully: exit status: 1`.
- trajectory: divergent
- kill/confirm: confirmed exact red baseline. Edge: inspect `FoldError` construction and the fold path around it.
- mode: deduction (99%)

## H3: The failing path is ADT fold reconstruction via `check_constructor`, not direct local-pointer folding
- null: Inspecting the narrowed source would show the failure comes only from `fold_local_ptrs` or unrelated call checking.
- perturbation: `sed -n '320,370p' crates/flux-refineck/src/lib.rs`; `sed -n '2320,2465p' crates/flux-refineck/src/checker.rs`; `sed -n '1,430p' crates/flux-refineck/src/type_env.rs`; `sed -n '420,485p' crates/flux-refineck/src/checker.rs`; `rg -n "struct FoldError|FoldError|check_invariant|fold|unfold|invariant" crates/flux-refineck/src/checker.rs crates/flux-refineck/src/*.rs`; `rg -n "struct InferCtxtAt|fn check_pred|fn subtyping|fn sub_|dst_span|ConstrReason|Fold" crates/flux-infer crates/flux-refineck/src crates/flux-middle/src | head -200`
- observed: `FoldError` is emitted for `ConstrReason::Fold | ConstrReason::FoldLocal` in `crates/flux-refineck/src/lib.rs:227-230`. `TypeEnv::fold_local_ptrs` checks `infcx.subtyping(&ty, &bound, ConstrReason::FoldLocal)` in `crates/flux-refineck/src/type_env.rs:232-237`. `TypeEnv::fold` calls `self.bindings.lookup(place, span).fold(infcx)?` in `crates/flux-refineck/src/type_env.rs:317-321`. Grep shows `crates/flux-refineck/src/type_env/place_ty.rs:907` calls `.check_constructor(variant_sig, args, &fields, ConstrReason::Fold)`. Existing negative tests show ordinary invariant failures for direct bad field writes and for stale coupled fields.
- trajectory: convergent
- kill/confirm: refined. The symptom could be either local-pointer folding after the setter call or ADT field folding before/after the call; the exact source span alone is insufficient. Edge: run program perturbations that isolate composite sort, setter call, and invariant preservation.
- mode: abduction (70%)

## H4: Any setter call through the field triggers the fold error
- null: A structurally identical setter call that preserves the exact abstract refinement would verify.
- perturbation: Added `repro_same_hdl.rs` with `Slot` still refined by `(len: int, hdl: int -> bool)`, but the trusted method has `ensures self: Slot[n, f]`. Ran `flux repro_same_hdl.rs`.
- observed: command exited 0. Output included four dead-code warnings and `summary. 3 functions processed: 2 checked; 1 trusted; 0 ignored. 1 constraints solved. Finished in 35.25ms`.
- trajectory: divergent
- kill/confirm: killed. A mutable call through the field and local pointer folding are not sufficient to fail. Edge: the failure requires a changed composite refinement where the invariant mentions only a preserved projection (`len`).
- mode: induction (90%)

## H5: The bug affects scalar abstract refinements as well as composite-sort refinements
- null: A scalar-sort version with the same field invariant and setter shape would verify.
- perturbation: Added `repro_scalar.rs` where `Slot` is refined by `len: int`, `Container` is refined by `slot: int`, the field is `{&mut Slot[slot] | slot > 0}`, and the setter preserves `Slot[n]`. Ran `flux repro_scalar.rs`.
- observed: command exited 0. Output included four dead-code warnings and `summary. 3 functions processed: 2 checked; 1 trusted; 0 ignored. 1 constraints solved. Finished in 34.57ms`.
- trajectory: divergent
- kill/confirm: killed. Scalar abstract field invariants survive this pattern. Edge: inspect composite-sort ADT construction/projection handling during fold.
- mode: induction (92%)

## H6: Any call-site local-pointer fold requires the full old composite refinement after the setter
- null: A direct `&strg Slot[@n, @f]` wrapper around `slot.set(i)` with an output `Slot[n, |j| j == i || f(j)]` would verify.
- perturbation: Added `repro_direct_strg.rs` with only `Slot` and a function `#[flux_rs::sig(fn(slot: &strg Slot[@n, @f], i: usize{i < n}) ensures slot: Slot[n, |j| j == i || f(j)])] fn update(slot: &mut Slot, i: usize) { slot.set(i); }`. Ran `flux repro_direct_strg.rs`.
- observed: command exited 0. Output included three dead-code warnings and `summary. 3 functions processed: 2 checked; 1 trusted; 0 ignored. 0 constraints solved. Finished in 14.99ms`.
- trajectory: divergent
- kill/confirm: killed as a broad local-pointer explanation. Edge: the remaining difference is folding an enclosing ADT field whose abstract index is a composite `Slot` value.
- mode: induction (90%)

## H7: The failed obligation is the final `Container` fold invariant `s.slot.len > 0`
- null: Dumped constraints would show the failing simplified obligation is `Fold` at the final `fold(*_1)` and not `FoldLocal` at the setter call.
- perturbation: `rm -rf log && flux -Fdump-checker-trace=info repro.rs`; `find log -maxdepth 2 -type f -print | sort`; `sed -n '19,35p' log/checker`; `rm -rf log && flux -Fdump-constraint=true repro.rs`; `find log -maxdepth 2 -type f -print | sort`; `sed -n '1,200p' 'log/repro.{impl#1}-update.fluxc'`; `sed -n '1,200p' 'log/repro.{impl#1}-update.simp.fluxc'`; `sed -n '1,220p' 'log/repro.{impl#1}-update.smt2'`
- observed: checker trace shows `unfold((*_1).0)` assumes `s.slot.len > 0` and final `fold(*_1)` reconstructs `Container<'?1>[s.slot]`. Raw constraints include `(s.0.0 > 0) ~ Fold at 24:6: 24:6`, but the simplified constraints are only `(0 < s.0.0) ~ Call at 23:9: 23:25` and `∀ a1: int. ((a1 = 0 ∨ s.0.1(a1)) = s.0.1(a1)) ~ FoldLocal at 23:9: 23:25`. The SMT dump tags the second as `Tag 1: FoldLocal at 23:9: 23:25`.
- trajectory: divergent
- kill/confirm: killed. The final `Container` invariant is not the unsolved obligation; it is simplified away as valid. Edge: root is `FoldLocal` requiring the callee's post-state for the temporary strong pointer to be a subtype of the original full `Slot[s.slot]` bound.
- mode: deduction (99%)

## H8: Provenance of the suspect rule shows an inherited coarse local-fold design
- null: Blame would show the failing `FoldLocal` check came from a recent targeted issue fix or a flagged FIXME about composite sorts.
- perturbation: `git blame -L 426,472 -- crates/flux-refineck/src/checker.rs`; `git blame -L 220,238 -- crates/flux-refineck/src/type_env.rs`; `git blame -L 670,700 -- crates/flux-infer/src/infer.rs`; `git log --oneline --decorate -n 12`
- observed: `checker.rs` lines 430-467 document `[local-unfold] Γ ; &mut T => Γ, l:[<: T] T' ; ptr(l)` and `[local-fold] Γ, l:[<: T2] T1 => Γ` with `T1 <: T2`; these lines trace mainly to `0ba5db1eaf1` (Ranjit Jhala, 2024-11-14) and `f3d79e74b17`/`94e25b85295` (Nico Lehmann, 2024-11-27). `type_env.rs:232-238` contains `infcx.subtyping(&ty, &bound, ConstrReason::FoldLocal)?`, tracing the exact check to `27f7e7c3e19`/`0ba5db1eaf1`. The current checkout is `68d61714d2 (HEAD -> main, tag: base1613, origin/main, origin/HEAD) Lean directory hassles (#1647)`.
- trajectory: convergent
- kill/confirm: confirmed provenance. The rule is a deliberate coarse approximation for temporary strong calls, not a composite-sort-specific FIXME. Edge: fix must relax or reshape local folding without suppressing negative fold obligations.
- mode: abduction (80%)

## H9: Removing the `FoldLocal` subtype check makes the target pass and preserves existing negatives
- null: Running after that edit through the edited source would either still fail the target or make existing negative fold tests pass.
- perturbation: Temporarily edited `TypeEnv::fold_local_ptrs` to remove `infcx.subtyping(&ty, &bound, ConstrReason::FoldLocal)?`, then ran `flux repro.rs`, `flux tests/tests/neg/structs/field-00.rs`, `flux tests/tests/neg/structs/struct-fold-00.rs`, and checked `which flux && flux --version`.
- observed: `flux repro.rs` still emitted the original `error[E0999]: type invariant may not hold (when place is folded)`. The direct negative-file invocations failed before Flux checking with `error[E0601]: main function not found`. `which flux` reported `/home/ec2-user/.cargo/bin/flux` and `flux --version` reported `flux 68d61714d2 (2026-06-09)`, proving the command used the installed binary, not the edited workspace source.
- trajectory: chaotic
- kill/confirm: killed as non-evidence. Edge: use the repo build/test command (`cargo x ...` or a freshly built driver) for source perturbations.
- mode: deduction (95%)

## H10: Removing `FoldLocal` is a sound fix once tested through `cargo x`
- null: An invalid variant that changes `slot.len` to `0` while the enclosing invariant requires `slot.len > 0` would still be rejected.
- perturbation: With the temporary no-check edit still applied, ran `cargo x run repro.rs -- --crate-type=lib`; `cargo x run repro_same_hdl.rs -- --crate-type=lib`; `cargo x run repro_scalar.rs -- --crate-type=lib`; `cargo x test field-00 --suite basic`; added `repro_bad_len.rs` with `clear_len` specified as `ensures self: Slot[0, f]` and ran `cargo x run repro_bad_len.rs -- --crate-type=lib`.
- observed: edited-source `cargo x run repro.rs -- --crate-type=lib` exited 0 and reported `summary. 3 functions processed: 2 checked; 1 trusted; 0 ignored. 1 constraints solved`. Existing `field-00` tests still passed: `test [compile-fail] neg/structs/field-00.rs ... ok`. But `cargo x run repro_bad_len.rs -- --crate-type=lib` also exited 0 with `summary. 2 functions processed: 1 checked; 1 trusted; 0 ignored. 0 constraints solved`, even though the setter changes the field length to `0` and should violate `{ slot.len > 0 }`.
- trajectory: oscillatory
- kill/confirm: killed as unsound over-suppression. Edge: final fix must propagate the callee post-type back to the borrowed place and then let ordinary final folding check the enclosing invariant.
- mode: deduction (99%)

## H11: Propagating local-pointer post-types to tracked mutable-borrow origins fixes the target and rejects broken invariants
- null: With borrow-origin tracking, the target would still fail, or the `clear_len` invalid variant would verify.
- perturbation: Implemented borrow-origin tracking in `TypeEnv`: `Rvalue::Ref(..., Mut, place)` assignments record the borrowed place for the destination local; `unfold_local_ptrs` attaches that borrowed place to temporary local pointers; `fold_local_ptrs` updates the borrowed place with the callee post-type when an origin exists, and otherwise keeps the old subtype check. Ran `cargo x run repro.rs -- --crate-type=lib` and `cargo x run repro_bad_len.rs -- --crate-type=lib`.
- observed: `cargo x run repro.rs -- --crate-type=lib` exited 0 with `summary. 3 functions processed: 2 checked; 1 trusted; 0 ignored. 1 constraints solved. Finished in 83.13ms`. `cargo x run repro_bad_len.rs -- --crate-type=lib` exited 1 with `error[E0999]: type invariant may not hold (when place is folded)` at `repro_bad_len.rs:21:6` and a note pointing to `#[flux_rs::field({&mut Slot[slot] | slot.len > 0})]`.
- trajectory: divergent
- kill/confirm: confirmed. Edge: run a structurally different predicate-sensitive probe, then add permanent pos/neg tests.
- mode: deduction (98%)

## H12: The propagation fix generalizes to a two-field invariant relating `slot.len` to another field
- null: A `PairContainer` whose invariant is `slot.len == cap && cap > 0` would verify after `set(0)`.
- perturbation: Added `repro_pair_len.rs` with `PairContainer<'a>` refined by `(slot: Slot, cap: int)`, field `slot: {&mut Slot[slot] | slot.len == cap && cap > 0}`, field `cap: usize[cap]`, and `update` calling `self.slot.set(0)`. First ran `cargo x run repro_pair_len.rs -- --crate-type=lib` in parallel with `cargo x run repro_bad_len.rs -- --crate-type=lib`; then reran sequentially with `rm -rf log && cargo x run repro_pair_len.rs -- --crate-type=lib -Fdump-constraint=true -Fdump-checker-trace=info`; then reran sequentially with `cargo x run repro_pair_len.rs -- --crate-type=lib`.
- observed: The parallel run for `repro_pair_len.rs` ended with `Error: command was terminated by a signal: 11` after warnings, while `repro_bad_len.rs` still exited 1 with the expected field-invariant `FoldError`. The sequential dump run for `repro_pair_len.rs` exited 0 with `summary. 2 functions processed: 1 checked; 1 trusted; 0 ignored. 1 constraints solved. Finished in 94.61ms`. The sequential non-dump rerun also exited 0 with `summary. 2 functions processed: 1 checked; 1 trusted; 0 ignored. 1 constraints solved. Finished in 72.16ms`.
- trajectory: convergent
- kill/confirm: confirmed, with the earlier parallel SIGSEGV treated as chaotic non-reproduced evidence from concurrent `cargo x` runs. Edge: promote original and bad-length variants to permanent tests and run suites.
- mode: induction (90%)

## H13: Permanent regression tests capture the valid and invalid issue shapes
- null: The new compiletest filter would fail either the positive original pattern or the negative broken-length pattern.
- perturbation: Added `tests/tests/pos/abstract_refinements/issue-1613.rs` with the original valid setter shape, using `#[flux::...]` attributes. Added `tests/tests/neg/abstract_refinements/issue-1613.rs` where `clear_len` ensures `Slot[0, f]` under the same `slot.len > 0` field invariant. Ran `cargo x test issue-1613 --suite basic`.
- observed: compiletest output reported `test [ui] pos/abstract_refinements/issue-1613.rs ... ok` and `test [compile-fail] neg/abstract_refinements/issue-1613.rs ... ok`; overall `1 passed` in each filtered pos and neg run.
- trajectory: divergent
- kill/confirm: confirmed. Edge: run the required broader positive and negative suites.
- mode: deduction (99%)

## H14: Propagating every tracked mutable-borrow origin preserves existing negative local-pointer tests
- null: The full basic suite would keep rejecting `neg/surface/local_ptr00.rs`, where a plain `&mut i32{v <= 10}` is passed to a strong incrementer.
- perturbation: Ran `cargo x test --suite basic`, then inspected `tests/tests/neg/surface/local_ptr00.rs` and reran `cargo x test local_ptr00 --suite basic`.
- observed: The full basic suite failed only `neg/surface/local_ptr00.rs` with `error: compile-fail test compiled successfully!`. The test is `#[flux::sig(fn (x: &mut i32{v: v<=10}))] fn client_unsafe(z: &mut i32) { incr(z); //~ ERROR type invariant }`, where `incr` ensures `x: i32[n+1]`. The filtered rerun reproduced the same failure.
- trajectory: divergent
- kill/confirm: killed as over-broad propagation. Edge: only use post-type write-back for borrowed places with field projections, where an enclosing place fold can recheck the updated field; keep the old subtype check for plain `&mut` parameters.
- mode: deduction (99%)

## H15: Field-origin-only propagation preserves `local_ptr00` while keeping issue tests green
- null: After narrowing write-back to borrowed places with field projections, either `local_ptr00` would still compile or `issue-1613` would fail again.
- perturbation: Changed `fold_local_ptrs` to update `borrowed_place` only when it has a `PlaceElem::Field(_)`; otherwise it runs the original `infcx.subtyping(&ty, &bound, ConstrReason::FoldLocal)?`. Ran `cargo x test local_ptr00 --suite basic` and `cargo x test issue-1613 --suite basic`.
- observed: `local_ptr00` filtered run reported `test [ui] pos/surface/local_ptr00.rs ... ok` and `test [compile-fail] neg/surface/local_ptr00.rs ... ok`. `issue-1613` filtered run reported `test [ui] pos/abstract_refinements/issue-1613.rs ... ok` and `test [compile-fail] neg/abstract_refinements/issue-1613.rs ... ok`.
- trajectory: divergent
- kill/confirm: confirmed. Edge: rerun full basic and with-deps suites.
- mode: deduction (99%)

## H16: Full basic positive and negative suites pass after the narrowed fix
- null: `cargo x test --suite basic` would fail any existing positive or negative test.
- perturbation: `cargo x test --suite basic`
- observed: command exited 0. Positive run reported `running 436 tests` and completed with all non-ignored tests ok. Negative run reported `test result: ok. 394 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 11.77s`.
- trajectory: divergent
- kill/confirm: confirmed for the basic suite. Edge: run `with-deps` suite.
- mode: deduction (99%)

## H17: Full with-deps positive and negative suites pass after the narrowed fix
- null: `cargo x test --suite with-deps` would fail any existing positive or negative test.
- perturbation: `cargo x test --suite with-deps`
- observed: command exited 0. Positive run reported `running 88 tests` and `test result: ok. 87 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 6.02s`. Negative run reported `running 52 tests` and `test result: ok. 52 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 3.58s`.
- trajectory: divergent
- kill/confirm: confirmed. Edge: format and inspect final diff.
- mode: deduction (99%)

## H18: Formatting preserves the focused regression and safety checks
- null: Running `cargo fmt` would introduce formatting-only breakage or focused tests would fail afterward.
- perturbation: `cargo fmt`; `cargo x test issue-1613 --suite basic`; `cargo x test local_ptr00 --suite basic`
- observed: `cargo fmt` exited 0. The issue filter reported `test [ui] pos/abstract_refinements/issue-1613.rs ... ok` and `test [compile-fail] neg/abstract_refinements/issue-1613.rs ... ok`. The local-pointer filter reported `test [ui] pos/surface/local_ptr00.rs ... ok` and `test [compile-fail] neg/surface/local_ptr00.rs ... ok`.
- trajectory: divergent
- kill/confirm: confirmed. Edge: inspect final diff and report.
- mode: deduction (99%)

# Merge-readiness extension (operator-run probes, 2026-06-10)

These nodes are NOT the agent's. They are post-investigation hardening trials run by the operator
to pre-attach a receipt to every anticipated maintainer objection before shipping #1613. Same node
discipline; provenance explicitly labeled "(operator)". Every command is replayable on the fix.

## H19: The post-state write-back composes across sequential setters on the same field
- null: A second setter call on the already-updated field fails to fold, or spuriously verifies a call whose own precondition is unprovable.
- perturbation: (operator) `flux p1_seq.rs` (`self.slot.set(0); self.slot.set(1)`) and `flux p1b_seq.rs` (`self.slot.set(0); self.slot.set(0)`) on the rebuilt fix.
- observed: `p1_seq.rs` errors with `E0999: refinement type error ... a precondition cannot be proved`, pointing at the setter's own `i: usize{i < n}` (cannot prove `1 < n` from `n > 0`). `p1b_seq.rs` (both indices `0`, provable) VERIFIES.
- trajectory: divergent
- kill/confirm: confirmed. Write-back composes; the lone failure is a genuine unrelated precondition (`1 < n`), which is correct, not a fold limitation.
- mode: induction (92%)

## H20: Write-back generalizes to nested field projections (self.inner.slot)
- null: A two-level field path misses `has_field_projection` or fails to re-fold the outer struct.
- perturbation: (operator) `p2_nested.rs` = `Outer { inner: Container { slot: &mut Slot } }`, `update` calls `self.inner.slot.set(0)`; ran `flux p2_nested.rs`.
- observed: VERIFIES. The `Field(inner), Field(slot)` path satisfies `has_field_projection`; the post-state is written to the nested place and the enclosing `Container`/`Outer` folds re-check the invariant.
- trajectory: divergent
- kill/confirm: confirmed. The fix is not special-cased to single-level fields.
- mode: induction (90%)

## H21: The field-projection gate preserves plain &mut parameter checking (fresh program, not just local_ptr00)
- null: A fresh plain `&mut i32{v<=10}` passed to a strong incrementer now verifies (regression of the H14/H15 narrowing).
- perturbation: (operator) `p3_plain.rs` = `incr(x: &strg i32) ensures i32[n+1]` called from `client(z: &mut i32{v<=10})`; ran `flux p3_plain.rs`.
- observed: REJECTED (`E0999`). No enclosing field fold exists, the borrow carries no field projection, `fold_local_ptrs` keeps the original `FoldLocal` subtyping check, the bad update is caught.
- trajectory: divergent
- kill/confirm: confirmed. The H15 narrowing holds on a fresh program, not only the suite's `local_ptr00`.
- mode: deduction (98%)

## H22: The fix is sort-agnostic — the discriminating int-composite receipt verifies, the unsound twin is rejected
- null: An int-sort composite (`refined_by(len: int, val: int)`, setter `ensures Slot[n, v+1]`) is rejected, showing the fix is keyed to function sorts after all.
- perturbation: (operator) `receipt_int.rs` (same reborrow shape, plain int components) and `receipt_unsound.rs` (setter shrinks `len`, must fail `slot.len > 0`) on this fix and on a competing fix gated on a `Sort::Func` field.
- observed: this fix VERIFIES `receipt_int.rs` and REJECTS `receipt_unsound.rs` (E0999). The over-narrow fix REJECTS `receipt_int.rs`. The repair targets the root obligation (H11), so it is sort-agnostic by construction.
- trajectory: divergent
- kill/confirm: confirmed. This is the load-bearing generality receipt that separates a root-cause fix from a shape special-case.
- mode: deduction (97%)

## H23: Conforming the borrows map to the file convention (UnordMap) is behavior-neutral
- null: Replacing `FxHashMap<Local, Place>` with `UnordMap<Local, Place>` (matching the in-file `local_names: UnordMap<Local, Symbol>` precedent) changes verification or breaks the build.
- perturbation: (operator) `sed` FxHashMap -> UnordMap for the `borrows` field, its 4 default sites, and the import; rebuilt; re-ran all receipts + the full suite. (Also surfaced and corrected a `git stash` artifact: a partial 2-file tree had masked T2; recovered from the authoritative 3-file patch and re-verified.)
- observed: builds clean; T1 VERIFY, T2 VERIFY, T3 ERROR, P1b VERIFY, P2 VERIFY, P3 ERROR all unchanged. `borrows` is insert/point-lookup only (never iterated), so the map choice is behavior-neutral and UnordMap matches the codebase idiom.
- trajectory: convergent
- kill/confirm: confirmed. Style conforms to the file's own convention; no semantic change.
- mode: deduction (99%)

## H24: Final soundness gate on the complete, conformed fix
- null: The full `basic` + `with-deps` compiletest suites show any regression.
- perturbation: (operator) `cargo xtask test` on the rebuilt clean+conformed tree.
- observed: exit 0. basic pos 432/0 failed; basic neg 394/0; with-deps pos 87/0; with-deps neg 52/0. Authoritative patch: 3 files, 81+/19-.
- trajectory: divergent
- kill/confirm: confirmed merge-ready on the test axis. Edge (remaining commit hygiene): ship the source diff + the pos/neg `issue-1613` tests only; fold the int-sort variant into the pos test as a permanent generality fence; exclude the scratch `repro*.rs`.
- mode: deduction (99%)

# Dual-judge audit (two independent SOTA families, 2026-06-10)

The graph was audited node-by-node for INFERENTIAL soundness (does the observation license the
conclusion) by two independent frontier models in different families: Opus 4.8 and GPT-5.5 (codex),
each blind to the other. Replay already established that the trials reproduce; this layer checks the
reasoning. Recorded append-only; it does not retro-edit the agent's nodes.

## H25: Independent dual-family audit of every node
- null: A node's conclusion overreaches its evidence and at least one strong independent reviewer catches it.
- perturbation: (operator) sent H0-H24 + the final diff to Opus 4.8 and to GPT-5.5 separately, adversarial prompt ("default to CHALLENGED; name the gap or alternative"); merged for disagreements.
- observed: 21+/25 SOUND on both. Opus challenged H22 (narration only). Codex challenged H4, H8, H20, H15. The high-signal result is CONVERGENCE: both families independently flagged the SAME load-bearing risk from different angles. Codex: "CHAIN broken, weakest H15, threatens correctness -- field projection does not by itself prove safe enclosing invariant recheck." Opus SOUNDNESS RISK: "the enclosing place might escape folding, so the write-back lands without re-check." Same gap: `has_field_projection` is a SYNTACTIC proxy for the SEMANTIC property "an enclosing fold will re-verify the invariant," and neither the graph nor the operator probes PROVED the equivalence.
- trajectory: divergent (two blind families landing on one node = strongest possible merge signal)
- kill/confirm: confirmed gap. The fix's correctness on field-origin borrows rests on the unproven claim that a field projection implies a re-checking enclosing fold. Edge: adversarially test the escape shapes both judges named.
- mode: deduction (95%)

## H26: Escape-shape soundness probes discharge the gate empirically; residual is the unproven equivalence
- null: Some constructible program with a field-projection borrow whose enclosing place escapes folding lets an INVALID (invariant-violating) post-state verify.
- perturbation: (operator) ran the invalid `len`-shrinking setter under every escape shape the judges named: E1 (no `ensures` on the caller), E2 (plain `ensures Container`), N1 (nested `Outer.inner.slot`, the nested-NEGATIVE twin codex said was missing), N3 (plain free `fn(&mut Container)`), N2 (enum-variant field).
- observed: E1, E2, N1, N3 all REJECTED with E0999 (invalid post-state correctly caught by the enclosing fold). N2 is inexpressible: `error[E0433]: could not find 'field' in 'flux_rs'` -- field invariants on enum-variant fields are not in flux's surface syntax, so that escape is unreachable. The `&strg` discipline re-checks the field invariant even without an explicit `ensures` (E1).
- trajectory: convergent
- kill/confirm: the soundness risk is empirically discharged on every constructible shape; the gate is safe in practice because a field-projection borrow always has an enclosing owned (`&strg`/local) place that gets folded and re-verifies the invariant. RESIDUAL (honest, unkilled): this mechanism is well-motivated and tested, NOT formally proven. It is the one inference in the graph resting on a syntactic proxy, and it is exactly what to flag for the maintainers, who own the fold machinery. Also correct H22's narration: the fix is sort-agnostic because the gate is sort-blind (syntactic), established empirically here, not "by construction" from two receipts.
- mode: induction (90%) for the empirical discharge; the formal equivalence stays open

## State Table
- H0: confirmed
- H1: killed
- H2: confirmed
- H3: refined
- H4: killed
- H5: killed
- H6: killed
- H7: killed
- H8: confirmed
- H9: killed
- H10: killed
- H11: confirmed
- H12: confirmed
- H13: confirmed
- H14: killed
- H15: confirmed
- H16: confirmed
- H17: confirmed
- H18: confirmed
- H19: confirmed (operator: write-back composes across sequential setters)
- H20: confirmed (operator: generalizes to nested field projections)
- H21: confirmed (operator: plain &mut parameter checking preserved on a fresh program)
- H22: confirmed (operator: sort-agnostic; int-composite receipt verifies, unsound twin rejected)
- H23: confirmed (operator: UnordMap conformance is behavior-neutral)
- H24: confirmed (operator: full basic + with-deps suites pass; merge-ready on the test axis)
- H25: confirmed gap (dual-family audit: Opus 4.8 + GPT-5.5 converge on the H15 field-projection gate as the load-bearing, formally-unproven inference)
- H26: convergent (every constructible escape shape rejects the invalid program; gate safe in practice; residual = the unproven syntactic->semantic equivalence, flagged for maintainers)

## Causal Chain
- H0: Exact diagnostic text is owned by `flux-refineck` fold checking, so diagnosis starts from place folding and invariant verification.
- H1: Direct `flux` invocation injects Flux attributes; reproducer files in this repo should omit explicit `register_tool` boilerplate.
- H2: The adjusted reproducer reaches the exact `FoldError`, proving the target is the refinement fold path rather than parser/desugar setup.
- H3: Source inspection narrows the likely root to ADT fold reconstruction and/or the local-pointer fold generated around a mutable call.
- H4: Exact-refinement preservation verifies, so the bug is not generic mutation through a field; it is tied to proving an invariant over a projection of a changed composite sort.
- H5: Scalar sort version verifies, so the missing reasoning is specific to composite-sort values/projections, not abstract refinement fields in general.
- H6: Direct strong-reference mutation verifies, focusing the diagnosis on re-folding the enclosing `Container` field, not on the `Slot::set` call in isolation.
- H7: Constraint dumping reverses H6's edge: the actual unsoundly strong obligation is local-pointer folding, specifically equality of the changed function refinement with the old one, while the final container invariant is already provable.
- H8: The failing equality comes from an explicit inherited `[local-fold]` subtype rule for temporary `&mut` to `&strg` conversion.
- H9: The installed `flux` binary is useful for baseline reproduction but not for validating source edits.
- H10: Suppressing `FoldLocal` proves the root but is unsound because it loses post-state changes; the correct repair needs post-state propagation to the borrowed place.
- H11: Tracking mutable-borrow origins and writing back the callee post-type repairs the root cause: local strong-call folding now preserves mutation effects for the enclosing place, so valid len-preserving hdl updates verify and invalid len changes fail at the enclosing invariant.
- H12: The propagation fix generalizes beyond a direct `len > 0` invariant to an invariant tying the preserved projection to another field; a parallel-run SIGSEGV did not reproduce sequentially.
- H13: Permanent tests now lock both sides: the issue program verifies, while a setter that invalidates the preserved field invariant is rejected.
- H14: Existing negative tests show propagation cannot apply to plain `&mut` parameters; those still need the old local-fold subtype check.
- H15: Restricting propagation to field-origin borrows keeps the original local-pointer safety check for plain mutable parameters while fixing the field-mutation issue.
- H16: The narrowed fix passes the full basic compiletest suite, including existing positives and negatives.
- H17: The narrowed fix also passes the with-deps compiletest suite.
- H18: Formatting did not alter the verified behavior.
- H19-H24 (operator merge-readiness): the fix composes across sequential setters, generalizes to
  nested field projections, preserves plain `&mut` parameter checking, is sort-agnostic (the
  int-composite receipt that distinguishes it from a shape special-case verifies while the unsound
  twin is rejected), conforms to the file's `UnordMap` convention with no behavior change, and
  passes the full basic + with-deps suites. Every anticipated maintainer objection now has a
  replayable receipt attached as a node. Remaining step before push: fold the int-sort variant into
  the committed pos test as a permanent generality fence, and commit source + `issue-1613` tests
  only (exclude scratch `repro*.rs`).
