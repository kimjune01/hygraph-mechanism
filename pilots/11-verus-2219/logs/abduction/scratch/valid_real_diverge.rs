#![allow(internal_features)]
#![feature(rustc_attrs)]
#![feature(never_type)]
use vstd::prelude::*;

verus! {
#[verifier::external_body]
proof fn real_diverge() -> ! { unimplemented!() }
proof fn consume<T>(tracked t: T) { }

proof fn test2<T>(tracked t: T) {
    real_diverge();
    consume(t);
    consume(t);
}
}
fn main() {}
