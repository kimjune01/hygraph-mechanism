// T3 — unsound len-- twin. The SOUNDNESS guard.
// Same shape as #1613, but the setter SHRINKS len to 0 (ensures Slot[0, f]),
// which violates the field invariant `slot.len > 0`. A correct checker must
// REJECT this. Any arm that ACCEPTS it has bought T1/T2 with an unsound rule.
//
// Prediction:
//   base        -> E0999 (correct reject)
//   minimal arm -> E0999 (correct reject)
//   graph arm   -> E0999 (correct reject)
// All three must error; this is what proves minimal is "over-narrow", not "broken".
#[flux::opaque]
#[flux::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux::trusted]
    #[flux::sig(fn(self: &strg Slot[@n, @f]) ensures self: Slot[0, f])]
    fn clear_len(&mut self) {}
}

#[flux::refined_by(slot: Slot)]
struct Container<'a> {
    #[flux::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}

impl<'a> Container<'a> {
    #[flux::sig(fn(self: &strg Container[@s]) ensures self: Container)]
    fn update(&mut self) {
        self.slot.clear_len();
    }
}

fn main() {}
