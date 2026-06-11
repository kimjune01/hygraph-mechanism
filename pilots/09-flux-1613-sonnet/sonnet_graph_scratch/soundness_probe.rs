// Soundness probe: should still be rejected.
// Container's invariant requires slot.len > 0.
// If set() were called on an empty Slot (len == 0), the Container fold
// should fail to verify slot.len > 0.  We can't force len == 0 here
// (the Container invariant blocks it), but we can test that a manual
// wrong ensures annotation IS rejected.

#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n}) ensures self: Slot[n, |j| j == i || f(j)])]
    fn set(&mut self, i: usize) { self.0[i] = true; }
}

// A version where update() claims the slot still has the OLD abstract
// state after calling set().  This should FAIL because the Container
// fold must now verify the invariant against the NEW state returned by
// replace_mut_ref; the only claim it can make is `Container` (any
// valid container) so the following overly-precise ensures is wrong.
#[flux_rs::refined_by(slot: Slot)]
struct Container2<'a> {
    #[flux_rs::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}

impl<'a> Container2<'a> {
    // Claims s is unchanged after set(0) – this SHOULD be rejected.
    #[flux_rs::sig(fn(self: &strg Container2[@s]) ensures self: Container2[s])]
    fn update_bad(&mut self) {
        self.slot.set(0); // error expected: the fold can't re-prove self: Container2[s]
    }
}
