#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
struct R {}
fn use_r(r: R) {}
#[verifier::external_body] fn never_returns() -> ! { loop {} }
#[allow(unreachable_code)]
fn f(r: R) { never_returns(); use_r(r); use_r(r); }
}
fn main(){}
