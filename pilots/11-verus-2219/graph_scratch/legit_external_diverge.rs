#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus! {
#[verifier::external_body]
proof fn diverge() -> ! { unimplemented!() }
proof fn consume<T>(tracked t: T) { }
proof fn test2<T>(tracked t: T) {
    diverge();
    consume(t);
    consume(t);
}
}
fn main() {}
