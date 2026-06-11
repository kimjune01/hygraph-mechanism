#[flux::opaque]
#[flux::refined_by(len: int, ctr: int)]
struct Slot([bool]);
impl Slot {
    #[flux::trusted]
    #[flux::sig(fn(self: &strg Slot[@n, @c], i: usize{i < n}) ensures self: Slot[n, c + 1])]
    fn set(&mut self, i: usize) { self.0[i] = true; }
}
#[flux::refined_by(slot: Slot)]
struct Container<'a> {
    #[flux::field({&mut Slot[slot] | slot.len > 0})]
    slot: &'a mut Slot,
}
impl<'a> Container<'a> {
    #[flux::sig(fn(self: &strg Container[@s]) ensures self: Container)]
    fn update(&mut self) { self.slot.set(0); }
}
fn main() {}
