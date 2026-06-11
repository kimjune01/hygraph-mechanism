// T2 — int-composite receipt. The DISCRIMINATOR.
// Validated against the original GPT-5.5 patches: base E0999, minimal E0999, graph VERIFY.
//
// A VALID program that triggers the SAME fold bug as #1613 but with NO function-sort
// component: the composite sort is (len:int, ctr:int) and the setter UPDATES a
// component (ctr -> ctr+1) while preserving the field invariant `slot.len > 0`. After
// the setter, a correct checker must re-fold Container knowing slot.len is unchanged.
//
// Behavior:
//   base        -> E0999  (the #1613 fold bug is general, not Func-specific)
//   minimal arm -> E0999  (over-narrow: needs_tracked_reborrow gates on a DIRECT
//                          Sort::Func field, which this program lacks -> not tracked)
//   graph arm   -> VERIFY (tracks field-borrow post-state regardless of sort)
#[flux::opaque]
#[flux::refined_by(len: int, ctr: int)]
struct Slot([bool]);

impl Slot {
    #[flux::trusted]
    #[flux::sig(fn(self: &strg Slot[@n, @c], i: usize{i < n}) ensures self: Slot[n, c + 1])]
    fn set(&mut self, i: usize) {
        self.0[i] = true;
    }
}

#[flux::refined_by(slot: Slot)]
struct Container<'a> {
    #[flux::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}

impl<'a> Container<'a> {
    #[flux::sig(fn(self: &strg Container[@s]) ensures self: Container)]
    fn update(&mut self) {
        self.slot.set(0);
    }
}

fn main() {}
