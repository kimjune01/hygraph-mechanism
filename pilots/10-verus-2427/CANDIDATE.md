# Pilot 10 candidate — Verus #2427 (cross-repo replication, strongest hedge)

**Why this instance.** Cross-repo (Verus, not flux) kills the "flux-specific quirk" objection.
And the over-narrow-vs-general axis is MAINTAINER-CERTIFIED, not reconstructed:

- #2446 (b9ad6cb058, merged 2026-05-15) "Add a missing axiom specifying the Output associated
  type for **a closure**" — *Fixes #2427.*  (the NARROW fix)
- #2474 (633baa8cb9, merged 2026-05-21) "Emit output type constraints for top-level functions
  **too**" — *Fixes #2427 **(again)**.*  (the GENERAL fix; "again" = first fix was over-narrow)

**Commits.**
- base  = 351dbddd4f (parent of #2446; bug present)
- narrow = b9ad6cb058 (#2446)
- general = 633baa8cb9 (#2474)

**Oracle (from the project's own test `fndef_output_through_assoc_type_gh_issue_2427`):**
- T1 = `use_closure` call site — base FAIL, narrow PASS, general PASS. (reported case)
- T2 = `use_top_level_fn` / `use_generic_fn` — base FAIL, narrow FAIL, general PASS. (DISCRIMINATOR)
- T3 = soundness twin (assert a postcondition that does NOT follow) — must FAIL in every arm.

**Predicted divergence (codex default, minimal vs graph, blind from base):**
- minimal -> closure-only axiom (like #2446): T1 pass, T2 FAIL (over-narrow).
- graph   -> general FnDef-Output constraints (like #2474): T1 pass, T2 PASS.

**Status:** Verus toolchain build in progress. Next: build oracle from the certified test,
validate against the three commits (base/narrow/general), then run codex arms.

## Oracle VALIDATED (built all three real commits)
| program     | base  | narrow #2446 | general #2474 |
|-------------|-------|--------------|---------------|
| T1 closure  | FAIL  | VERIFY       | VERIFY        |
| T2 toplevel | FAIL  | **FAIL**     | **VERIFY**    |
| T3 unsound  | FAIL  | FAIL         | FAIL          |
T2 separates narrow from general — maintainer-certified discriminator. Instrument is sound.
verus single-file grade: `verus <file.rs>` -> "N verified, M errors". grade.sh wraps it.

## Integrity / anti-cheat (git + network)
- Verus base does NOT contain the fix (commits #2446 b9ad6cb0 / #2474 633baa8c are not ancestors).
- BUT the cloned repo initially had them on `origin/main` -> reachable via `git log origin/main`,
  and codex runs with --dangerously-bypass-approvals-and-sandbox (full git + network). HOLE.
- SCRUBBED (post-hoc, mid minimal-run): removed `origin`, deleted all non-`verus-arm` refs,
  `reflog expire --all` + `gc --prune=now`. Verified `git log origin/main`, `git show <fixSHA>`
  all FAIL afterwards. Fix is now structurally unreachable, matching the flux setup.
- Minimal arm (launched pre-scrub): integrity established by FULL-LOG AUDIT (codex exec logs every
  shell command; any peek requires a logged git/curl/gh/http command). Audit at completion; rerun
  if any hit. Graph arm (launched post-scrub): clean by construction.
- Anti-cheat safeguards, layered: (1) structural unreachability [now], (2) prompt boundary,
  (3) symmetric-cheat cancels in the differential, (4) minimal-arm-as-memorization-probe.
- LESSON: scrub the repo BEFORE launching arms (done for flux via pr1651 deletion; missed for
  verus on first pass). Pre-flight checklist item for future cross-repo instances.

## Contamination (cutoff)
- GPT-5.5 published knowledge cutoff: 2025-12-01. Verus #2427 fixes merged 2026-05-15/21 ->
  ~5.5 months post-cutoff -> clean by the cutoff argument (in addition to the structural scrub).
