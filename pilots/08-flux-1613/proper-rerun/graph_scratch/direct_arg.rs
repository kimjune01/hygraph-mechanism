#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n}) ensures self: Slot[n, |j| j == i || f(j)])]
    fn set(&mut self, i: usize) { self.0[i] = true; }
}

#[flux_rs::sig(fn(x: &mut {Slot[@n, @f] | n > 0}))]
fn update_direct(x: &mut Slot) {
    x.set(0);
}
