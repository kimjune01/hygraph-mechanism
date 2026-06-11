#![allow(internal_features)]
#![feature(never_type)]
use vstd::prelude::*;
verus! {
proof fn test(_nvr: !) { }
proof fn consume<T>(tracked t: T) { }
proof fn diverge() -> ! { loop { } }
proof fn test2<T>(tracked t: T) {
    test(diverge());
    consume(t);
    consume(t);
}
}
fn main() {}
