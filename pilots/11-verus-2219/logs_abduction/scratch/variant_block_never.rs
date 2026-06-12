#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T>(tracked t: T) {
    test({
        let ghost nvr: ! = arbitrary();
        nvr
    });

    consume(t);
    consume(t);
}
}

fn main() {}
