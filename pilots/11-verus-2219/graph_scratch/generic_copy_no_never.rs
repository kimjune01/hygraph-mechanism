use vstd::prelude::*;

verus! {
proof fn test(_x: int) { }
proof fn consume<T: Copy>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T: Copy>(tracked t: T) {
    test(arbitrary());

    consume(t);
    consume(t);
}
}

fn main() {}
