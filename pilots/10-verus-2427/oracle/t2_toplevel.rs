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
fn use_top_level_fn() {
    let mut y = W { i: Ad(foo) };
    y.touch();
    assert(y.index() == y.seq().len());
}
fn use_generic_fn() {
    let mut y = W { i: Ad(id::<u32>) };
    y.touch();
    assert(y.index() == y.seq().len());
}
fn main() {}
}
