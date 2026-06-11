// V6: int component changed via field (not abstract fn)
#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, tag: int)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @t], i: usize{i < n}) ensures self: Slot[n, t + 1])]
    fn inc(&mut self, i: usize) { self.0[i] = true; }
}

#[flux_rs::refined_by(slot: Slot)]
struct Container<'a> {
    #[flux_rs::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}

impl<'a> Container<'a> {
    #[flux_rs::sig(fn(self: &strg Container[@s]) ensures self: Container)]
    fn update(&mut self) {
        self.slot.inc(0);
    }
}

fn main() {}
