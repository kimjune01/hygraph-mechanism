#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
struct R { i: int }
proof fn test(nvr: !) { }
proof fn consume(tracked t: R) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2(tracked t: R) {
    test(arbitrary());

    consume(t);
    consume(t);
}
}

fn main() {}
