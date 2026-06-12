#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn never_value() -> !;

proof fn test2<T>(tracked t: T) {
    test(never_value());

    consume(t);
    consume(t);
}
}

fn main() {}
