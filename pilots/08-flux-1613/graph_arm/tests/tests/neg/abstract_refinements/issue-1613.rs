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
    } //~ ERROR type invariant may not hold
}
