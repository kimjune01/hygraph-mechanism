#![allow(internal_features)]
#![feature(rust_verify_internal)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T>(tracked t: T) {
    let x: ! = arbitrary();
    test(x);

    consume(t);
    consume(t);
}
}

fn main() {}
