use vstd::prelude::*;
verus!{
pub trait HasItem { type Item; }
pub struct Ad<F>(pub F);
impl<F: FnOnce(u32) -> u32> HasItem for Ad<F> { type Item = F::Output; }
pub struct W<I: HasItem> { pub i: I }
impl<I: HasItem> W<I> {
    pub uninterp spec fn index(self) -> int;
    pub uninterp spec fn seq(self) -> Seq<I::Item>;
    fn touch(&mut self)
        ensures final(self).index() == final(self).seq().len(),
    { assume(false); }
}
fn foo(x: u32) -> u32 { x }
fn id<T>(x: T) -> T { x }
fn use_closure_unsound() {
    let f = |x: u32| -> u32 { x };
    let mut y = W { i: Ad(f) };
    y.touch();
    assert(y.index() == y.seq().len() + 1); // NOT implied by touch()'s ensures
}
fn main() {}
}
