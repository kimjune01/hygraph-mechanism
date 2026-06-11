#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus! {
proof fn test(_nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;
proof fn test2<T>(tracked t: Tracked<T>) {
    test(arbitrary());
    consume(t);
    consume(t);
}
}
fn main() {}
