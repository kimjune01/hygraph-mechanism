- `RESULTS.md:19` | `human maintainer [#2501] | 🟢 general + correct | 🟢 general + correct` | `{inferred, cross-toolchain}` | `{asserted-as-fact}` | Fix: add `†/contingent` or narrow to “general on measured bug/t3 probes; ho5 ungraded.”

- `RESULTS.md:61` | `the human gold (#2501) is finer ... it clears ho5 (inferred, see † in the battery; not yet force-graded)` | `{inferred, cross-toolchain}` | `{flagged}` | Fix: acceptable, but make the next sentence “would be evidence,” not “is evidence.”

- `RESULTS.md:61` | `Composer landed on the gate-rewarded attractor, not the gold, which is evidence against recall` | `{inferred}` | `{flagged, but still rhetorically too strong}` | Fix: change to “would be evidence if the † control passes.”

- `RESULTS.md:105` | `#2501 general (maintainer) ... ho5 | (V)† ... bucket | 🟢 general+correct` | `{inferred, cross-toolchain}` | `{flagged}` | Fix: bucket should be `🟢 general+correct†` or `provisionally general+correct`.

- `RESULTS.md:107` | `nothing automated clears ho5` | `{measured}` | `{asserted-as-fact}` | Fix: okay for automated arms only; add “in forced-fresh base-toolchain grades” to prevent accidental contrast with ungraded gold.

- `RESULTS.md:109` | `#2501-clears-ho5 is inferred, not forced-fresh graded here...` | `{inferred, cross-toolchain}` | `{flagged}` | Fix: good.

- `RESULTS.md:130` | `The divergence arm is cleared unaided only by the human maintainer.` | `{inferred, cross-toolchain}` | `{asserted-as-fact}` | Fix: change to “provisionally/by measured t3 plus inferred ho5.”

- `LESSONS.md:13` | `Only the human maintainer fix (#2501) clears it unaided.` | `{inferred, cross-toolchain}` | `{asserted-as-fact}` | Fix: qualify: “clears measured t3; ho5 remains inferred.”

- `LESSONS.md:31` | `approved ≠ perfect (#2501 over-rejects ho5)` | `{inferred}` | `{asserted-as-fact}` | Fix: this contradicts the current record; replace with “approved history can have blind spots; #2501-on-ho5 is ungraded here.”

- `LESSONS.md:33` | `the human gold (#2501) is finer ... it clears ho5; every automated arm ... misses ho5` | `{inferred, cross-toolchain}` | `{flagged-contingent}` | Fix: mostly fixed, but move “If the gold clears ho5” before the first “it clears ho5.”

- `LESSONS.md:39` | `#2501-clears-ho5 is inferred ... force-grading ... open control` | `{inferred, cross-toolchain}` | `{flagged}` | Fix: good.

- `pilots/11-verus-2219/RESULT-corrected.md:9` | `The finer human gold #2501 clears ho5; no automated arm does, evidence each landed on the gate-attractor, not the gold.` | `{inferred, cross-toolchain}` | `{asserted-as-fact}` | Fix: add the same † note from `RESULTS.md`; make the anti-recall conclusion conditional.

- `pilots/11-verus-2219/RESULT-corrected.md:15-22` | table gives `#2501` measured-looking `R/R/R/V` but `ho5` is `—` | `{cross-toolchain}` | `{partly asserted-as-fact}` | Fix: label the `#2501` column “1.95.0 / cross-toolchain” and keep `ho5` ungraded.

- `pilots/11-verus-2219/RESULT-corrected.md:27` | `same bug coverage as the maintainer's general fix #2501` | `{cross-toolchain}` | `{asserted-as-fact}` | Fix: change to “same observed bug coverage, cross-toolchain.”

- `pilots/11-verus-2219/MECHANISM-dissection.md:6` | `the model reaches the correct general predicate by discovering and reusing the verifier's own oracle` | `{stale}` | `{asserted-as-fact}` | Fix: replace with the later correction: “mode-gated approximation; inhabitedness query not load-bearing.”

- `worklog/WORK_LOG.md:574` | `LEAKAGE IS NOT THE EXPLANATION for Composer` | `{inferred, self-reported}` | `{asserted-as-fact}` | Fix: already retracted later; if this log is quoted, mark as superseded by lines 581-598.

- `worklog/WORK_LOG.md:582` | `gold #2501 is finer ... it clears ho5; every automated arm misses ho5` | `{inferred, cross-toolchain}` | `{asserted-as-fact}` | Fix: supersede inline or add “later corrected at line 598.”

- `worklog/WORK_LOG.md:592-593` | `crash=1250, mishandles=0... READING (corrected): ... BATTERY shows the truth` | `{measured}` | `{flagged}` | Fix: good; this correctly prevents `mishandles=0` from ruling out divergence failure.

- `RESULTS.md:49`, `worklog/WORK_LOG.md:561` | `sealed held-outs the model never saw` | `{self-reported/protocol-assumed}` | `{asserted-as-fact}` | Fix: cite the prompt/run isolation artifact, or phrase as “sealed by protocol.”

- `RESULTS.md:54-57`, `RESULTS.md:65`, `LESSONS.md:19`, `worklog/WORK_LOG.md:595` | `near-A`, `crash=1250`, `efficiency not endpoint retired`, `n=1/workflow` | `{measured, n=1}` | `{flagged}` | Fix: acceptable; the n=1 and protocol limits are carried.

- `RESULTS.md:56`, `LESSONS.md:33`, `worklog/WORK_LOG.md:570-571` | contamination dates/cutoffs such as `Composer ... ships May 2026`, `Sonnet ... Jan 2026 cutoff / Feb-2026 release` | `{self-reported}` | `{asserted-as-fact}` | Fix: add source links or say “per Cursor/Anthropic docs as logged.”

The corrected record is not fully honest yet: `RESULTS.md` mostly flags the inferred `#2501`-clears-`ho5` control, but `LESSONS.md`, `RESULT-corrected.md`, and `MECHANISM-dissection.md` still contain asserted-as-fact inferences or stale claims.