// V2: Direct &strg call, no Container field borrow
#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n}) ensures self: Slot[n, |j| j == i || f(j)])]
    fn set(&mut self, i: usize) { self.0[i] = true; }
}

#[flux_rs::sig(fn(s: &strg Slot[@n, @f]) ensures s: Slot[n, |j| j == 0 || f(j)])]
fn update(s: &mut Slot) {
    s.set(0);
}

fn main() {}
