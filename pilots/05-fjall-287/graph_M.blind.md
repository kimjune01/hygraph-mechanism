## Symptom

Concurrent `Keyspace::clear()` plus ingestion eventually panics in a background worker:

```text
assertion left == right failed: invalid table IDs
```

The assert is in `lsm-tree` version movement:

`lsm-tree-3.1.5/src/version/mod.rs:563-572`

```rust
pub fn with_moved(&self, ids: &[TableId], dest_level: usize) -> Self {
    let affected_tables = self
        .iter_tables()
        .filter(|x| ids.contains(&x.id()))
        .cloned()
        .collect::<Vec<_>>();

    assert_eq!(affected_tables.len(), ids.len(), "invalid table IDs");
```

That means a compaction task selected table IDs from one version, but by the time it tried to apply the move, those IDs were no longer present in the current version.

## Localization

`src/keyspace/mod.rs:236-264`

```rust
pub fn clear(&self) -> crate::Result<()> {
    let mut journal_writer = self.supervisor.journal.get_writer();
    ...
    let seqno = self.supervisor.seqno.next();
    journal_writer.write_clear(self.id, seqno)?;
    ...
    self.tree.clear()?;
    self.supervisor.snapshot_tracker.publish(seqno);
    drop(journal_writer);
```

`clear()` serializes with the journal writer, then calls into `lsm-tree`.

`lsm-tree-3.1.5/src/tree/mod.rs:264-279`

```rust
fn clear(&self) -> crate::Result<()> {
    let config = self.tree_config();
    let mut versions = self.get_version_history_lock();

    versions.upgrade_version(
        &config.path,
        |v| {
            let mut copy = v.clone();
            copy.active_memtable = Arc::new(Memtable::new(self.memtable_id_counter.next()));
            copy.sealed_memtables = Arc::default();
            copy.version = Version::new(v.version.id() + 1, self.tree_type());
            Ok(copy)
        },
```

This replaces the active memtable, drops all sealed memtables, and replaces the table version with an empty `Version`. It does not take the tree `flush_lock`, `compaction_state`, or `major_compaction_lock`.

Ingestion finish is only partly serialized by fjall’s journal lock:

`src/ingestion.rs:36-55`

```rust
pub fn finish(self) -> crate::Result<()> {
    let _journal_lock = self.keyspace.supervisor.journal.get_writer();

    self.inner.finish()
```

Inside `lsm-tree`, ingestion finish uses the tree flush lock and compaction/version locks:

`lsm-tree-3.1.5/src/tree/ingest.rs:257-263`

```rust
let flush_lock = self.tree.get_flush_lock();

self.tree.rotate_memtable();
self.tree.flush(&flush_lock, 0)?;
```

`lsm-tree-3.1.5/src/tree/ingest.rs:273-325`

```rust
let mut _compaction_state = self.tree.compaction_state.lock().expect("lock is poisoned");
let mut version_lock = self.tree.version_history.write().expect("lock is poisoned");
let global_seqno = self.tree.config.seqno.next();
...
copy.version = copy.version.with_new_l0_run(&created_tables, None, None);
```

Flush workers also rely on `flush_lock`, but `clear()` ignores it:

`src/flush/worker.rs:22-27`

```rust
let flush_lock = task.keyspace.tree.get_flush_lock();

task.keyspace.tree.flush(&flush_lock, gc_watermark)
```

`lsm-tree-3.1.5/src/abstract_tree.rs:81-115`

```rust
let version_history = self.get_version_history_lock();
let latest = version_history.latest_version();
let sealed_ids = latest.sealed_memtables.iter().map(|mt| mt.id).collect::<Vec<_>>();
...
drop(version_history);

if let Some((tables, blob_files)) = self.flush_to_tables(stream)? {
    self.register_tables(&tables, blob_files.as_deref(), None, &sealed_ids, seqno_threshold)?;
}
```

So a flush can snapshot sealed memtables, drop the version lock, write tables, then later register those old tables into whatever version is current after a concurrent clear.

The panic path is the compaction move path:

`lsm-tree-3.1.5/src/compaction/worker.rs:92-119`

```rust
let compaction_state = opts.compaction_state.lock().expect("lock is poisoned");
let version_history_lock = opts.version_history.read().expect("lock is poisoned");

let choice = opts.strategy.choose(
    &version_history_lock.latest_version().version,
    &opts.config,
    &compaction_state,
);

match choice {
    Choice::Move(payload) => {
        drop(version_history_lock);
        move_tables(&compaction_state, opts, &payload)
    }
```

`lsm-tree-3.1.5/src/compaction/worker.rs:184-219`

```rust
fn move_tables(...) -> crate::Result<()> {
    let mut version_history_lock = opts.version_history.write().expect("lock is poisoned");

    let table_ids = payload.table_ids.iter().copied().collect::<Vec<_>>();

    version_history_lock.upgrade_version(
        &opts.config.path,
        |current| {
            let mut copy = current.clone();
            copy.version = copy
                .version
                .with_moved(&table_ids, payload.dest_level as usize);
```

There is a gap between choosing table IDs under a read lock and applying the move under a write lock. `clear()` can enter that gap because it does not lock `compaction_state`. It empties the version, then `move_tables()` calls `with_moved()` with stale table IDs and hits `invalid table IDs`.

## Root-cause hypothesis

`Keyspace::clear()` is a destructive version rewrite, but it is synchronized only with the journal writer and the `version_history` write lock. It is not synchronized with the tree’s operation-level locks that protect multi-step flush, ingestion, and compaction transitions.

The failing interleaving is:

1. Ingestion finishes and registers new tables, then schedules compaction.
2. A compaction worker chooses `Choice::Move` from version `V`, collecting table IDs.
3. The worker drops the version read lock before acquiring the write lock.
4. Concurrent `clear()` takes the version write lock and publishes version `V+1` with no tables.
5. The compaction worker acquires the write lock and applies its stale move payload to the now-empty version.
6. `Version::with_moved()` cannot find the selected IDs and asserts `invalid table IDs`.

There is a second corruption path with the same missing synchronization: a flush or ingestion-triggered flush can capture sealed memtables, drop the version lock while writing table files, then `clear()` empties the version, and the later flush registration can add pre-clear data back into the post-clear version.

`manual_journal_persist(true)` likely makes the crash faster by shortening the journal critical section in `clear()` and normal writes. It changes timing, not the fundamental race. The live panic is in version/compaction state, not journal replay.

The unused `SupervisorInner::backpressure_lock: Mutex<()>` is not directly relevant. It is declared and initialized only:

`src/supervisor.rs:35`

```rust
pub(crate) backpressure_lock: Mutex<()>,
```

`src/db.rs:642`, `src/db.rs:883`

```rust
backpressure_lock: Mutex::default(),
```

No code acquires it, and it is supervisor-global rather than tied to the per-tree `flush_lock`, `compaction_state`, and `version_history` invariants being violated.

## Rivals considered and killed

1. Journal ordering or `manual_journal_persist(true)` corrupts recovery.

Killed: the observed panic occurs in a live worker inside `Version::with_moved()`, before recovery. `clear()` and `Ingestion::finish()` both take the fjall journal writer, so journal ordering serializes those two API endpoints. The crash comes from lsm-tree background version transitions that are not covered by the journal lock.

2. Table ID reuse after `clear()` creates duplicate or invalid table IDs.

Killed: `clear()` replaces memtables and `Version::new(...)`, but does not reset `table_id_counter`. Table IDs for ingestion and flush come from the shared monotonic counter. The assert is not caused by duplicate IDs; it is caused by a stale compaction payload whose IDs were valid in the version it inspected and absent in the version after `clear()`.

## Predicted fix shape

`clear()` must become mutually exclusive with all multi-step tree mutations that snapshot one version and later publish another version.

The likely shape is in `lsm-tree` around `Tree::clear()`:

- Take the tree `flush_lock` before clearing so no flush or ingestion-triggered flush can be between “snapshot sealed memtables” and “register flushed tables”.
- Take `compaction_state` or an equivalent compaction barrier before clearing so compaction cannot choose IDs from the old version and apply them after the clear.
- Possibly take the major-compaction/write side or stop/drain in-flight compactions, depending on intended semantics, because merge compactions also hide old tables, do CPU work, then publish a new version later.
- Keep the version rewrite itself under `version_history.write()` as it already does.
- In fjall, `Keyspace::clear()` should continue to serialize journal order, but the missing protection is inside the tree-level clear against flush/ingest/compaction, not in the unused `backpressure_lock`.

A defensive improvement would also make `move_tables()` revalidate like the merge/drop paths do instead of asserting, but that only prevents the panic. The correctness fix is that `clear()` must not race with in-flight flush/ingestion/compaction registration that can resurrect or move pre-clear tables.
