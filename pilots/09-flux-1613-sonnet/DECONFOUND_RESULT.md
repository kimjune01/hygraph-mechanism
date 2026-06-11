# De-confound result (flux #1613, Sonnet, de-biased graph prompt): OSCILLATORY

The pilot-09 flux divergence used a graph prompt that NAMED the discriminating axis
("a function sort vs a plain int component"). De-confounding = rerun the SAME model
(Sonnet) with that axis REMOVED (generic "which features are incidental" guidance only),
graded by the same T1/T2/T3 oracle. Each draw: clean-verified base, isolated, full audit.

## Draws (e-value Bernoulli: X=1 if DIVERGE = T2 VERIFY + T3 sound)
| draw | verdict | fix architecture                         | T2     |
|------|---------|------------------------------------------|--------|
| #1   | DIVERGE | sort-agnostic `MutRef` write-back        | VERIFY |
| #2   | NULL    | gated on `Sort::Func`                     | E0999  |
| #3   | NULL    | gated on `ExprKind::Abs` (lambda)        | E0999  |

Rate 1/3 general. e = 1.8 x 0.2 x 0.2 = 0.072 (p0=0.5, p1=0.9). Same model, same prompt.

## Trajectory classification: OSCILLATORY (declared)
Per the evidence-trajectory framework (convergent / divergent / oscillatory / chaotic),
this is OSCILLATORY: evidence waxes and wanes; TWO distinct modes are visible —
- Mode A (de-anchored): reaches the sort-agnostic general fix -> DIVERGE.
- Mode B (anchored): treats the reported example's function-sort feature as essential,
  gates the fix on Func/lambda presence -> over-narrow -> NULL.
Oscillatory is NOT "inconclusive". Its meaning in the framework is: the coarse hypothesis
("the graph methodology makes Sonnet reach the general fix") is too coarse; the outcome is
bimodal; SPLIT into sub-hypotheses.

## What this settles, and what it leaves open
SETTLED:
- The pilot-09 "full rescue" OVERSTATED the unaided mechanism. De-biased, the lift is
  ~1/3, not deterministic; naming the axis was doing substantial work.
- BUT it is not pure leakage either: de-anchoring fires unaided ~1/3 of the time
  (draw #1 reached the general fix with no axis hint). So the mechanism is real but
  PROBABILISTIC and bimodal.
OPEN (frontier edge, the "split"): what selects mode A vs mode B? Candidates: pure
sampling stochasticity; an early fork in the agent's perturbation choices (e.g. whether
it happens to test an int-component variant before settling on a fix); depth of the
hypothesis graph before it commits. Not pursued — declared, not drilled.

## Honest terminal status of the divergence claim
PARTIAL / OSCILLATORY. The flux #1613 divergence is real but (a) prompt-inflated and
(b) bimodal at ~1/3 unaided. Neither the clean "graph wins" of pilot 09 nor "it was all
leakage". The instrument was precise enough to reveal the effect is a coin-flippy,
anchoring-dominated lift — which is the true shape.
