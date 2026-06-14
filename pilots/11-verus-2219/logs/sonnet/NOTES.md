# Sonnet (claude-sonnet-4-6) gate2 arm

## RUN 1 — budget-truncated, did NOT clear. [2026-06-13]
claude-headless, 3h (20:19→23:19Z), rc=124 (TIMEOUT KILL, not natural finish). 9758 events.
Stream showed "GATE pass=true" — FALSE POSITIVE: it's the PROMPT TEXT ("...prints `GATE pass=true` only when...")
echoed inside `ps aux | grep gate` output (prompt is in the process args). ALL real gate.sh logs = pass=false.
Verified gate states (the ACTIONS): plateaued mishandles=230 (39/269 flipped) + p1 OVER-REJECTED across gate3/4/5.
Killed mid-pivot to an uncompiled "drop ghost Never statements" approach.
Forced-fresh grade of kill-time artifact (bin_fp 6b31585aead5b743): pass=false, mishandles=230;
  t1 REJECT, t2 VERIFY(miss), t3 REJECT(over-rej), h2_assoc/nested VERIFY(miss), ho5 VERIFY;
  p1 REJECT (impl wall NOT cleared), p2 VERIFY; seal_proofdiv REJECT, seal_exec VERIFY.
= NARROW bug arm + over-rejects p1/t3/seal_proofdiv. Worst quadrant, but TRUNCATED (only arm cut by my clock).
LESSON: nearly relayed the narration as result (caught by reading the actual gate.sh logs) — the worklog's
"actions don't lie, narration can" applies to MY monitoring too. Health-check grep on stream = unreliable.

## RUN 2 — fair re-run in progress: 4h budget + PASS-snapshot keepalive (capture passing state before any pivot/kill).

## CONTAMINATION — Sonnet 4.6 is CLEAN (checked 2026-06-13).
Released 2026-02-17; training-data cutoff Jan 2026; reliable-knowledge cutoff Aug 2025. ALL predate the verus
fix (base 2026-03-08, #2230/#2501 later). The fix did not exist when Sonnet finished training → contamination-clean.

## IMPLICATION for the leakage question (Composer):
Fable is ALSO contamination-clean (Jan-2026 cutoff) and ALREADY cleared the wall to near-A. So the existence proof
"a clean model clears this implementation wall" is established INDEPENDENT of Composer. Leakage is therefore NOT
NEEDED to explain Composer clearing it — a clean model (Fable) demonstrably clears the same wall with the same
gate. Composer's pass is unremarkable against that precedent; invoking fine-tune-recall is not the parsimonious
explanation. Clean-clears so far: Fable (near-A). Dirty-clear: Composer (near-A). Clean-NOT-clear (run1, truncated): Sonnet.
Sonnet run 2 (clean, fair budget) is the tie-breaker: clears → two clean models clear (robust capability);
doesn't-clear → capability BAND (Fable clears, Sonnet doesn't, both clean) — still a capability story, not leakage.
