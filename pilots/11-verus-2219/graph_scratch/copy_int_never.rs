#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume(tracked t: int) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2(tracked t: int) {
    test(arbitrary());

    consume(t);
    consume(t);
}
}

fn main() {}
