// Differential narrowing: confirm that non-abstract-function mutations still work.

#[flux_rs::opaque]
#[flux_rs::refined_by(len: int)]
struct SimpleSlot([bool]);

impl SimpleSlot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg SimpleSlot[@n], i: usize{i < n}) ensures self: SimpleSlot[n])]
    fn set(&mut self, i: usize) { self.0[i] = true; }
}

#[flux_rs::refined_by(slot: SimpleSlot)]
struct SimpleContainer<'a> {
    #[flux_rs::field({&mut SimpleSlot[slot] | slot.len > 0})]
    slot: &'a mut SimpleSlot,
}

impl<'a> SimpleContainer<'a> {
    // Should still work: set() keeps the same len, non-abstract case
    #[flux_rs::sig(fn(self: &strg SimpleContainer[@s]) ensures self: SimpleContainer)]
    fn update(&mut self) {
        self.slot.set(0);
    }
}

// Also test: direct &mut ref (no container)
#[flux_rs::opaque]
#[flux_rs::refined_by(len: int, hdl get: int -> bool)]
struct Slot([bool]);

impl Slot {
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &strg Slot[@n, @f], i: usize{i < n}) ensures self: Slot[n, |j| j == i || f(j)])]
    fn set(&mut self, i: usize) { self.0[i] = true; }

    // A method that sets and returns: the return type should use the new state
    #[flux_rs::trusted]
    #[flux_rs::sig(fn(self: &Slot[@n, @f], i: usize) -> bool)]
    fn get(&self, i: usize) -> bool { self.0[i] }
}

// Multiple calls to set should all verify
#[flux_rs::refined_by(slot: Slot)]
struct MultiContainer<'a> {
    #[flux_rs::field({&mut Slot[slot] | slot.len > 1})]
    slot: &'a mut Slot,
}

impl<'a> MultiContainer<'a> {
    #[flux_rs::sig(fn(self: &strg MultiContainer[@s]) ensures self: MultiContainer)]
    fn update_twice(&mut self) {
        self.slot.set(0);
        self.slot.set(1);
    }
}
