// T3 = OVER-REJECTION guard. A genuinely-diverging tracked ! return: the code after IS truly
// unreachable, so the double-consume is fine. VALID -> must still VERIFY (Ok) under any fix.
// Catches a fix that over-rejects by refusing to ever prune the CFG.
#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus!{
proof fn consume<T>(tracked t: T) { }
axiom fn proof_fn_returns_spec_never() -> (tracked x: !);
#[allow(unreachable_code)]
proof fn test2<T>(tracked t: T) {
    proof_fn_returns_spec_never();
    consume(t);
    consume(t);
}
}
fn main() {}
