use vstd::prelude::*;
verus! {
proof fn test(_x: int) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;
proof fn test2<T>(tracked t: T) {
    test(arbitrary());
    consume(t);
    consume(t);
}
}
fn main() {}
