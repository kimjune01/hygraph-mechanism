#![allow(internal_features)]
#![feature(rustc_attrs)]
#![feature(never_type)]
use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
uninterp spec fn arbitrary<T>() -> T;

proof fn test2() {
    test(arbitrary());
}
}
fn main() {}
