# codex (gpt-5.5) adversarial re-analysis — gate2 multi-model, 2026-06-13

Read-only review of the Composer 2.5 + Sonnet 4.6 results. Prompt: `/tmp/codex-reanalyze.txt` (archived in commit msg). Verdict below; "disposition" = what was changed in response.

## Weakest point (codex): the skeptic destroys Sonnet first.
Sonnet run 1 (matched 3h) did NOT clear. Run 2 got 4h + pass-snapshot + an appended operational keepalive that codex/Fable/Composer lacked; codex was terminated at 2.5h with no rerun. So Sonnet's run-2 win is "clears under a more forgiving rerun protocol," not "clears where codex walls under equal conditions." Putting it beside codex's single terminated loss is selection-biased.
DISPOSITION: ACCEPTED. RESULTS + LESSONS 7 now state the asymmetry explicitly and retract "efficiency, not endpoint." Added stop-rule column to the RESULTS table. Missing control named: protocol-matched codex rerun (4h + keepalive).

## Overclaims (codex):
1. "It is not recall" does not follow — clean models prove recall isn't *required*, not that Composer didn't memorize.
   DISPOSITION: ACCEPTED. Changed to "capability OR fine-tune-recall; recall not excluded" (matches the NOTES). Added the separate, stronger anti-recall signal: gold #2501 clears ho5, Composer misses it → Composer landed on the attractor, not the gold.
2. "Three of four families" is model+harness confounded → "workflows," scoped per LESSONS 14.
   DISPOSITION: ACCEPTED. Reworded to "workflows" throughout the section.
3. "Efficiency, not endpoint" unsupported (endpoint set by stop rules).
   DISPOSITION: ACCEPTED. Retracted.
4. "Same mechanism" overstates Composer (different impl path: THIR erasure, skip_remove, def-id collection).
   DISPOSITION: ACCEPTED. Changed to "same behavioral carve-out / same failure surface."

## What does not follow (codex): convergence may be the gate, not the models.
Gate calibrates p1/p2 but not ho5 → may funnel every model to one attractor (satisfy p1/p2, miss ho5). So shared carve-out + shared ho5 residual is possibly gate-shaping, not independent rediscovery; this WEAKENS the convergence-as-capability reading.
DISPOSITION: ACCEPTED as a caveat in both RESULTS and LESSONS. PARTIAL PUSHBACK: the attractor framing also strengthens the anti-recall point — the gold is finer than the attractor (clears ho5), so Composer's ho5 miss is positive evidence it did not recall the gold.

## Factual error (codex): RESULTS said "only Fable-with-calibration clears t3" — stale; Composer + Sonnet also clear t3.
DISPOSITION: FIXED.

## To strengthen (codex) — open follow-ups, NOT yet done:
- [ ] Protocol-matched codex gate2 rerun (4h + pass-snapshot + keepalive). The key control for the fairness critique.
- [ ] Report Sonnet run 1 and run 2 as separate cells (run 1 = walled). Done in RESULTS stop-rule column; could be a full row.
- [ ] >=3 seeds per workflow (currently n=1).
- [ ] Source the cutoff/release dates (Sonnet, Composer/Kimi) — added to NOTES refs.
- [ ] Add ho5-like preserve cases to the gate, re-run, see if the carve-out changes. Directly tests attractor vs capability.
- [ ] Force-grade gold #2501 on ho5 to nail "gold clears ho5, automated arms don't."
