#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
tracked struct S {}
proof fn eat(tracked s: S) {}
axiom fn diverge_proof() -> (tracked x: !);
#[allow(unreachable_code)]
proof fn h(tracked s: S) { diverge_proof(); eat(s); eat(s); }
}
fn main(){}
