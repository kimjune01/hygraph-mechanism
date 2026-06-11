// Soundness probe: setter violates field invariant (shrinks len to 0)
#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize) ensures self: Slot[0, f])]
    fn bad_set(&mut self, _i: usize) {}
}

#[flux_rs::refined_by(slot: Slot)]
struct Container<'a> {
    #[flux_rs::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}

impl<'a> Container<'a> {
    #[flux_rs::sig(fn(self: &strg Container[@s]) ensures self: Container)]
    fn update(&mut self) {
        self.slot.bad_set(0);
    }
}

fn main() {}
