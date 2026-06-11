#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T>(tracked t: T, b: bool) {
    test(if b { arbitrary() } else { arbitrary() });

    consume(t);
    consume(t);
}
}

fn main() {}
