# Hypothesis Graph: Issue #1613

## H0: Observation (induction)
**Program:** issue1613_repro.rs  
**Result:** FAIL - `error[E0999]: type invariant may not hold (when place is folded)` at `self.slot.set(0)`  
**Confidence:** high

## H1: Bug requires abstract function sort in composite (abduction)
**Perturbation:** variant_int_only.rs (replace `hdl get: int -> bool` with `val: int`)  
**Result:** PASS  
**Verdict:** CONFIRMS function-sort component matters (or any non-identity index change path)

## H2: Bug requires field-borrow path, not direct &strg (abduction)
**Perturbation:** variant_direct_strg.rs  
**Result:** FAIL with different error (`refinement type error`) - separate path  
**Verdict:** Container field-borrow is the reported failure mode

## H3: Bug fires when ensures changes index, not when identity (abduction)
**Perturbations:**
- variant_identity_setter.rs (ensures `Slot[n, f]`) → PASS
- variant_changed_via_field.rs (ensures `Slot[n, t+1]`) → FAIL (after fix)

**Verdict:** CONFIRMS failure tied to post-call index differing from pre-call bound

## H4: Root cause is stale LocalPtr bound in fold_local_ptrs (deduction)
**Trace:** `check_call` → `assume_ensures` → `update_path` updates `ty` but not `LocKind::LocalPtr(bound)` → `fold_local_ptrs` checks `ty <: bound` with pre-call `Slot[s.slot]` vs post-call `Slot[n, |j| j==0||f(j)]` → `idxs_eq` fails on function component  
**Confidence:** high

## H5: Fix merges bound: invariant fields from pre-call, function fields from post-call (abduction → induction)
**Change:** `merge_local_ptr_bound` + `update_local_ptr_bound` in `assume_ensures`  
**Results:**
- issue1613_repro.rs → PASS
- variant_int_only, variant_two_ints, variant_identity_setter → PASS
- variant_unsound_shrink_len (ensures `Slot[0, f]`) → FAIL E0999 fold (sound)
- variant_changed_via_field (int tag change) → FAIL (int not merged from post-call)

## H6: Soundness probe (induction)
**Program:** variant_unsound_shrink_len.rs  
**Result:** REJECTED with fold error  
**Verdict:** fix is sound for len violation

## H7: Regression (induction)
**Command:** `cargo xtask test --suite basic abstract`  
**Result:** 12/12 pass
