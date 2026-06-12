#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {
proof fn test(nvr: !) { }
proof fn consume<T>(tracked t: T) { }

proof fn mk_never() -> ! { loop { } }

proof fn test2<T>(tracked t: T) {
    test(mk_never());

    consume(t);
    consume(t);
}
}

fn main() {}
