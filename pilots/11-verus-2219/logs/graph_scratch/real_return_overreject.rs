use vstd::prelude::*;

verus! {
proof fn consume<T>(tracked t: T) { }

proof fn test2<T>(tracked t: T) {
    return;
    consume(t);
    consume(t);
}
}

fn main() {}
