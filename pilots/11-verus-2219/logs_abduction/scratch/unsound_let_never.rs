#![allow(internal_features)]
#![feature(rustc_attrs)]
#![feature(never_type)]
use vstd::prelude::*;

verus! {
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2<T>(tracked t: T) {
    let _x: ! = arbitrary();
    consume(t);
    consume(t);
}
}
fn main() {}
