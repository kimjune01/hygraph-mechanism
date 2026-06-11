# Bootstrap — run the minimal-vs-graph intervention probe on a NEW instance

Paste into a fresh session. This reproduces the pilot-09/10 workflow (local, no EC2) on ONE new bug.
Sister doc: `BOOTSTRAP.md` is the older EC2/merge-test ladder design — this is the current method.

---

You are running a **single-instance intervention probe**, not a benchmark. The claim it can support
(per adversarial review) is **existence/mechanism, NOT a rate**: "on this bug, the hypothesis-graph
prompt sometimes lifts the SAME model from an over-narrow fix to a general+sound one." It is a
**within-model A/B**; the differential cancels model/contamination/harness confounds. Do not inflate
it into "graph ranks models" or "graph generally helps" — codex kills both (`pilots/10-verus-2427/
codex_eval_critique.md`, `codex_methodology_critique.md`). Read `pilots/09-flux-1613-sonnet/
README.md`, `RESULTS.md`, `DECONFOUND_RESULT.md`, and `pilots/10-verus-2427/CANDIDATE.md` first.

## 1. Find a candidate (this is why interesting examples keep appearing — the regime is a rich seam)
The divergence only shows in a specific regime. Hunt for ALL of:
- **Verifier / type-checker / compiler-internal bug** — soundness-vs-generality is cleanly separable
  there, which is what makes a *receipt* (T2 valid-discriminator + T3 unsound-twin) constructible.
- **Hidden, non-local cause** — NOT fix-ready. If the issue hands over the repro+fix, minimal nails
  it and you get a null (the fast-pathed regime).
- **Terse report** — the issue does not spell out the general fix.
- **BEST: a maintainer-certified narrow->general trajectory** — two merged PRs, a narrow fix then a
  general one whose body says "fixes #X again" / "...too" / "more general". Then T2 is external and
  certified (cf. Verus #2427: #2446 closure-only -> #2474 "top-level functions too"). Second-best: an
  *unmerged* fix (un-memorizable, contamination-proof; cf. flux #1613).
- **Post-cutoff** — the fix postdates the craft model's training cutoff (web-check the cutoff; e.g.
  GPT-5.5 = 2025-12-01). Or unmerged.
- **Builds locally** (or on a box).

Hunt: `gh issue list -R <repo> --state all --search "..."` over flux-rs/flux, verus-lang/verus,
creusot-rs/creusot, viperproject/prusti-dev, model-checking/kani. Grep titles/bodies for: unsound,
"should verify", "false positive", "fixes #N again", narrow, over-narrow, only-handles, completeness,
soundness. For each promising issue, find the closing PR(s); a narrow-then-general pair is gold.

## 2. Build the toolchain locally (per-repo recipe; the one bespoke cost)
Clone the repo, checkout the **base = parent of the (first) fix commit** (bug present). Install its
pinned toolchain + SMT backend. Confirm the base reproduces the bug on the reported program.
- **PATH gotcha (frozen):** if `~/.cargo/bin/cargo` is a stale standalone (not a rustup proxy) and
  `/opt/homebrew/bin/cargo` is stable, the repo's `cargo +nightly`/`+1.xx` directives won't resolve.
  Build a rustup-proxy shim dir and prepend it, RUSTC/RUSTUP_TOOLCHAIN unset:
  `mkdir -p /tmp/rustup-shims; for p in cargo rustc cargo-flux rustfmt; do ln -sf "$(command -v rustup)" /tmp/rustup-shims/$p; done`
  then prefix every build/grade: `env -u RUSTC -u RUSTUP_TOOLCHAIN PATH=/tmp/rustup-shims:$PATH <cmd>`.
- Find the single-file verify command (flux: `cargo xtask run <f.rs>`; verus: `target-verus/release/verus <f.rs>`).
- Verus builds are small (~1GB), self-contained (vargo + vendored z3). flux target BLOATS across
  branch rebuilds (saw 50GB) — `cargo clean` between draws to reclaim.

## 3. Build + VALIDATE the oracle (T1/T2/T3) BEFORE running any arm
- **T1** = the reported program. Base FAIL; any real fix -> PASS. Cannot separate the arms alone.
- **T2** = a VALID program that triggers the same bug but that the OVER-NARROW fix misses. If a
  maintainer general fix exists, derive T2 from the tests IT added (disclose this dependency!). Else
  construct it and prove it valid. T2 is the discriminator.
- **T3** = an INVALID soundness twin (e.g. a setter that violates the invariant). Must FAIL under any
  correct fix; catches a fix that bought T1/T2 with unsoundness.
- **VALIDATE by building the real fixes** (you have them — base + narrow + general commits, or the
  one fix): base FAIL/FAIL/FAIL; narrow VERIFY/**FAIL**/FAIL; general VERIFY/**VERIFY**/FAIL.
  If T2 doesn't separate narrow from general against the REAL patches, the instrument is unproven —
  fix the oracle, don't run arms. Write a `grade.sh` wrapping the single-file verifier.

## 4. INTEGRITY — scrub BEFORE launch (do not skip; this bit us once)
Arms run with full file/command access, so the fix must be UNREACHABLE:
- Remove origin: `git remote remove origin`. Delete every ref except the base branch. `git reflog
  expire --expire=now --all && git gc --prune=now`. VERIFY `git log origin/main` AND
  `git show <fixSHA>` both FAIL afterward. (flux #1613 was clean because the fix was unmerged; Verus
  needed this scrub.)
- The minimal arm doubles as a memorization probe: if the model had the fix in weights, "just fix it"
  emits it. If minimal lands narrow, that's evidence against recall.

## 5. Run the two arms (the only thing that differs is the prompt)
Same model, same harness, same issue text, same boundaries; SEQUENTIAL in one dir.
- **minimal** prompt: mini-SWE-agent "analyze / reproduce / fix generally / verify / test edges". Adapt
  `pilots/09-flux-1613-sonnet/prompts/minimal.txt`.
- **graph** prompt: the hypothesis-graph methodology — observe, **differential narrowing** (perturb one
  feature at a time, classify trajectory, kill-condition generates the next edge), root-cause via
  constraint/trace dump, fix at the root, **soundness probe**, regression. Adapt `prompts/graph.txt`.
- **LEAKAGE GUARD (critical):** do NOT name the discriminating axis in the graph prompt. Pilot-09's
  graph prompt named "function-sort vs int" (the flux T2 axis) and that inflated the divergence from
  ~1/3 to ~deterministic. Use generic de-anchoring guidance only: "a bug report shows ONE example;
  ask for each surface feature whether it's incidental or load-bearing, and vary the incidental ones."
- Boundaries: edit only non-test source under `crates/`/`source/`; NO git history/branches/web; scratch
  in a /tmp dir. Drive via a subagent (model fixed) or codex/cursor headless — but keep the harness
  FIXED across the arms you compare (cross-harness comparison is a confound codex calls fatal).
- **PROCESS DISCIPLINE (we broke this once):** gate on the COMPLETION NOTIFICATION, never on a pgrep /
  diff snapshot. Never reset or launch a second arm in a dir where one may still be live. Verify clean
  base (grep for the fix's introduced symbols) before EACH draw.

## 6. Grade + classify (e-value / evidence-trajectory)
Capture each arm's `git diff` BEFORE reset (the patch is the durable artifact). Build + `grade.sh`.
Score each draw: **DIVERGE** (T1 VERIFY ∧ T2 VERIFY ∧ T3 reject) / **NULL** (T1 VERIFY ∧ T2 FAIL) /
**INVALID** (no working fix / T3 accepted / crash — rerun, don't count).
- One run is noise. Accumulate draws of the SAME arm; classify the trajectory: **convergent**
  (all agree), **divergent** (monotone), **oscillatory** (split — two modes; declare it, don't force a
  binary), **chaotic** (redesign). Optional stopping is licensed (anytime-valid). Expect oscillation
  if the bug sits at the model's capability edge (variance peaks there).
- To claim a LIFT, run the de-biased MINIMAL arm too (baseline general-rate). graph-rate vs
  minimal-rate. Pinning a rate precisely is ~40+ draws/cell (impractical) — the qualitative shape
  (converge / diverge / oscillatory, and the failure mode) is the load-bearing finding.

## 7. Disclose (keep the claim honest — codex's checklist)
Report: instance + denominator (how many candidates tried), whether T2 was derived from the golden,
the harness, seeds/draw-count + variance, prompt-leakage status, before/after oracle design, and that
the within-model differential is the clean signal while cross-model/cross-harness is confounded. Frame
as an intervention probe / case study, never a rate or a model ranking.

## 8. Log + commit
`worklog/WORK_LOG.md`: `### HH:MM — summary` per milestone (get time from `date`). Commit on a BRANCH
(not master). End commit messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
Send the design/claim to codex (`codex exec -s read-only --skip-git-repo-check`, no roleplay) and bank
the critique in the pilot dir. The number is the artifact; keep it small and load-bearing.
