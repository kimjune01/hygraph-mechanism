// T1 — the reported bug (#1613). The function-sort composite case.
// This is the exact program the issue reports: updating a composite-sort abstract
// refinement (with a function component `hdl`) through a mutably reborrowed field.
//
// Prediction:
//   base        -> E0999 (the reported bug)
//   minimal arm -> VERIFY (it fixes the reported case)
//   graph arm   -> VERIFY (it fixes the reported case)
// Both arms pass T1; T1 alone cannot separate them — that is what T2 is for.
#[flux::opaque]
#[flux::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux::trusted]
    #[flux::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n})
                ensures self: Slot[n, |j| j == i || f(j)])]
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
