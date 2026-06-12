use vstd::prelude::*;

verus! {
proof fn consume(tracked t: int) { }

proof fn test2(tracked t: int) {
    consume(t);
    consume(t);
}
}

fn main() {}
