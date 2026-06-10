#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n})
                   ensures self: Slot[n, |j| j == i || f(j)])]
    fn set(&mut self, i: usize) {
        self.0[i] = true;
    }
}

#[flux_rs::refined_by(slot: Slot, cap: int)]
struct PairContainer<'a> {
    #[flux_rs::field({&mut Slot[slot] | slot.len == cap && cap > 0})]
    slot: &'a mut Slot,
    #[flux_rs::field(usize[cap])]
    cap: usize,
}

impl<'a> PairContainer<'a> {
    #[flux_rs::sig(fn(self: &strg PairContainer[@s]) ensures self: PairContainer)]
    fn update(&mut self) {
        self.slot.set(0);
    }
}
