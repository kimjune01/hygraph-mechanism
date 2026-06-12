#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
#[verifier::external] enum Void {}
#[verifier::external_type_specification] #[verifier::external_body] struct ExVoid(Void);
tracked struct Token {}
proof fn consume(tracked t: Token) {}
#[verifier::external_body] proof fn mk<T>() -> (tracked v: T) { loop {} }
trait Tr { type A; }
impl Tr for u8 { type A = Void; }
proof fn test(tracked t: Token) { consume(t); mk::<<u8 as Tr>::A>(); consume(t); }
}
fn main(){}
