// T2 = DISCRIMINATOR. Same double-consume, but the diverging ghost value is an empty enum X,
// not `!`. INVALID -> must be REJECTED by a GENERAL fix. base ACCEPTS; narrow #2230 ACCEPTS
// (over-narrow: only handles !); general #2501 REJECTS.
#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
#[verifier::external]
enum X { }
#[verifier::external_type_specification]
#[verifier::external_body]
struct ExX(X);
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;
proof fn proof_fn_returns_spec_never() -> X { arbitrary() }
proof fn test2<T>(tracked t: T) {
    proof_fn_returns_spec_never();
    consume(t);
    consume(t);
}
}
fn main() {}
