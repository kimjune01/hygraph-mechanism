#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
#[verifier::external] enum Void {}
#[verifier::external_type_specification] #[verifier::external_body] struct ExVoid(Void);
tracked struct Token {}
proof fn consume(tracked t: Token) {}
uninterp spec fn arbitrary<T>() -> T;
#[verifier::external_body] proof fn mk<T>() -> (tracked v: T) { loop {} }
proof fn test(tracked t: Token) { consume(t); let v: Void = mk::<Void>(); match v {} consume(t); }
}
fn main(){}
