#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
struct X { }

proof fn takes_x(tracked x: X) { }

#[verifier::external_body]
proof fn never_returns() -> (tracked t: !) {
    loop { }
}

#[allow(unreachable_code)]
proof fn test() {
    takes_x(never_returns());
    assert(false);
}
}

fn main() {}
