# PR-ready: fjall-rs/fjall #287 (open when a build box is up)

The graph-arm fix (`graph_src.patch`) is validated (6x70s rigorous grade, no race crash;
lock always acquired outermost, so no deadlock). Open next time there's a Rust box.

## Steps
1. Box: clone fjall, `git apply graph_src.patch`, `cargo build --release`, run
   `reproducer.rs` + `gap_exposer.rs` a few 70s windows to re-confirm clean.
2. Add `reproducer.rs` as an `#[ignore]`d stress test (race tests are flaky; let the
   maintainer run it) or as `examples/race_clear_ingest.rs`, referenced in the body.
3. Fork to kimjune01/fjall, branch `fix-287-clear-ingest-race`, commit, open PR.
4. If we ever file the HG into sweep/repo-hypotheses/fjall-rs__fjall__287.md (from
   `graph_M.blind.md`), add the `[HG]` link; otherwise omit it (don't fake it).

## Draft PR body (sweep receipt prose; tone-match fjall's recent PRs before posting)

> Serialize `Keyspace::clear()` against ingestion, flush, and compaction so it can't
> publish an empty version out from under an in-flight table move.
>
> - The unused `SupervisorInner::backpressure_lock` looks like the intended guard, but
>   it's supervisor-global and never acquired, so wiring it up wouldn't protect the
>   per-tree `version_history` invariant that's actually being violated.
> - Serializing only `clear()` against `start_ingestion()` passes the reported reproducer
>   (it ingests continuously, so clear is almost always blocked), but leaves `clear()`
>   racing the background compaction worker, which selects `Choice::Move` table IDs under
>   a read lock and applies them after `clear()` has already published an empty version.
> - A per-keyspace `tree_operation_lock` held by `clear()`, `Ingestion::finish()`, the
>   flush worker, the compaction worker, and `major_compact()` makes clear mutually
>   exclusive with every path that snapshots one version and publishes another, which is
>   exactly what the `with_moved()` "invalid table IDs" assertion was catching.
>
> Fixes #287.

Note the perf tradeoff honestly if asked: the lock is coarse (a full compaction run blocks
clear/ingest on that keyspace). Correctness first; the maintainer can narrow the critical
section. The diagnosis (above) is the part worth their attention.
