# Localization-hard candidate slate (prepared for the next A/B run)

Refined target after 5 nulls + fjall #287 (baseline solved a hard *implementation* race):
the graph's only mechanism is **diagnosis**, so its frontier band is bugs where the
bottleneck is **localization** (symptom far from cause, fix in a file the error never names),
NOT implementation difficulty. Selection criterion: reproducible + deterministic oracle +
single-repo fix + the reporter does NOT localize it.

Limit held in view: this is a narrow, model-specific, perishable band; even a win here refines
"narrow conditional value," it does not resurrect "super effective." "Go harder" is only honest
if bounded by a prediction (name where region-2 should be; an empty result there counts against).

## Ranked candidates (all warm Rust repos, CPU-gradeable)

### 1. sharkdp/bat #3724 - man pages display a stray `22m` bold-reset  [TOP localization-hard]
- Symptom: `MANPAGER="bat -pl man" man uname` leaks an unwanted ANSI reset (`22m`) into output.
  Reporter has NO idea where; `--strip-ansi` masks it but loses color.
- Why localization-hard: the cause is somewhere in the man overstrike-preprocess -> syntax
  highlight -> ANSI-writer chain; the error names nothing, and the natural place to look (the
  `man` syntax def) may not be where the fix goes.
- Repro: capture a man page's groff output once (deterministic input file), run `bat -pl man`,
  check output. Setup TODO: pin the exact wrong-output signature (literal `22m` vs malformed
  ESC) before authoring the oracle.
- Oracle (essence): output contains no spurious/bare reset artifact; valid ANSI preserved.
- Build: bat is a light Rust CLI (fast).

### 2. sharkdp/bat #3710 - `--decorations=auto` shows decorations when piped + `--color=always`  [clean-oracle first run]
- Symptom: `bat --color=always --decorations=auto foo | cat` emits decorations; should only colorize.
- Localization: moderate (cause is in the auto/piped/style/decorations precedence logic - a
  known area), so a weaker test of the graph, BUT a pristine deterministic oracle.
- Oracle: piped output has no decoration glyphs (line numbers, grid, header), color preserved.
- Use as the SAFE first run / harness shakeout for bat before #3724.

### 3. tuono-labs/tuono #779 - using `window` breaks SSR  [localization-hard, ugly repro]
- Symptom: a file referencing `window` silently disables SSR. Cause: a bundler heuristic far
  from the symptom. Genuinely localization-hard, but repro needs the full vite/node SSR stack
  (heavy). Defer unless bat candidates exhaust.

## Skip
- tuono #829 (panic names `vite_reverse_proxy.rs:60` todo - determined), diskus #27 (stack
  overflow -> recursion, determined), fjall #260 (reporter handed full diagnosis - determined;
  currently running only as a strong-baseline confirmation).

## Plan
Run order: #3710 (shakeout, clean oracle) -> #3724 (the real localization-hard test). bat builds
fast; one box. Same protocol: blind recon graph, minimal (mini-SWE-agent) vs +M, codex 5.5,
essence oracle, resume-loop (no turn budget), rigorous grade + diff inspection.
