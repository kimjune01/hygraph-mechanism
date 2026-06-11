// T1 = the reported #2219 repro (INVALID: tracked t consumed twice, hidden behind ghost !).
// Must be REJECTED by any real fix. base ACCEPTS (the soundness bug).
#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;
proof fn test2<T>(tracked t: T) {
    test(arbitrary());
    consume(t);
    consume(t);
}
}
fn main() {}
