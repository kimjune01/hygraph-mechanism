#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
tracked struct Q {}
proof fn take(tracked q: Q) {}
#[verifier::external_body] fn exec_div() -> ! { panic!() }
#[allow(unreachable_code)]
fn g(tracked q: Q) { exec_div(); proof { take(q); take(q); } }
}
fn main(){}
