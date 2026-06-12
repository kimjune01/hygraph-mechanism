#![allow(internal_features)]
#![feature(rust_verify_internal)]

use vstd::prelude::*;

enum Void { }

verus! {
proof fn test(nvr: Void) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T>(tracked t: T) {
    test(arbitrary());

    consume(t);
    consume(t);
}
}

fn main() {}
