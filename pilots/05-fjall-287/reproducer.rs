use anyhow::Context;
fn main() -> anyhow::Result<()> {
    let dir = std::env::var("REPRO_DB").unwrap_or_else(|_| "/tmp/repro287_db".into());
    let _ = std::fs::remove_dir_all(&dir);
    let db = fjall::Database::builder(&dir)
        .max_journaling_size(67108864)
        .manual_journal_persist(true)
        .open().context("opening database")?;
    std::thread::scope(|spawner| {
        let keyspace = db.keyspace("keyspace1", fjall::KeyspaceCreateOptions::default).unwrap();
        spawner.spawn({ let keyspace = keyspace.clone(); move || -> anyhow::Result<()> {
            for _ in 0..100000 { keyspace.clear()?; std::thread::sleep(std::time::Duration::from_millis(1)); } Ok(()) }});
        spawner.spawn({ let keyspace = keyspace.clone(); move || -> anyhow::Result<()> {
            for _ in 0..100000 { let mut igst = keyspace.start_ingestion()?;
                for i in 0..=5120 { igst.write(format!("key{i:09}"), [(i % 256) as u8; 256])?; } igst.finish()?; } Ok(()) }});
    });
    println!("REPRO_COMPLETED_NO_CRASH");
    Ok(())
}
