#![allow(internal_features)]

use vstd::prelude::*;

verus! {
enum Void {}

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
