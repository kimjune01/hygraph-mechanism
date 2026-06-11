#[flux::refined_by(hdl get: int -> bool)]
struct Inner {
    #[flux::field(i32{v: get(v)})]
    witness: i32,
}
#[flux::opaque]
#[flux::refined_by(len: int, inner: Inner)]
struct Slot([bool]);
impl Slot {
    #[flux::trusted]
    #[flux::sig(fn(self: &strg Slot[@n, @inr], i: usize{i < n}) ensures self: Slot[n, inr])]
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
