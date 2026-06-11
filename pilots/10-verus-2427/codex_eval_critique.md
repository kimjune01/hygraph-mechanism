- Automated T1/T2/T3 tests wherever possible.
- Pre-registered oracle construction rules.
- Report `P(minimal T2)`, `P(graph T2)`, lift, and uncertainty intervals, not just regime labels.
- Separate analysis for above-band, in-band, and below-band behavior.
- Sequential testing allowed, but with fixed stopping rules and full accounting of cost.
- Public artifacts: prompts, bugs, tests, patches, seeds/settings, harness versions.
The defensible claim would be:
> Hygraph can be evaluated as an intervention that sometimes increases probability of general fixes on selected debugging instances, and models can be compared by estimated intervention response under controlled conditions.
The current claim, “hygraph debugging is a differential capability eval that ranks LLMs,” is not supported. It collapses under variance, confounding, and non-monotonicity.
19,419
The most damaging objection: **you do not have an eval; you have an anecdotal interaction effect with uncontrolled variance and uncontrolled scaffolding.** The current evidence cannot rank models because the observed “lift” is not yet separable from prompt leakage, bug idiosyncrasy, harness effects, and sampling noise.
The Sonnet de-biased rerun is the killer result: same model, same bug, same non-leaky graph prompt, different outcome. One general, one narrow. That means the measured cell is currently behaving like a coin flip. With one or two samples per model-bug cell, any regime label is mostly noise.
**1. Signal vs Noise**
If graph-T2 success is roughly Bernoulli, then distinguishing two models’ lift rates requires many repeated runs.
For a two-proportion comparison, rough per-arm sample sizes are:
- Detect 50% vs 80% success: ~40 runs per condition.
- Detect 50% vs 70%: ~90 runs per condition.
- Detect 50% vs 60%: ~390 runs per condition.
That is per model, per bug, per prompt arm if you want defensible separation. Since lift requires both minimal and graph arms, multiply again. At 30-60 minutes per agent run, this is impractical unless heavily automated and parallelized.
Right now, the evidence supports only: “sometimes the graph prompt helps on flux #1613.” It does not support: “hygraph ranks models.”
**2. Non-Monotonic Lift Breaks Scalar Ranking**
The proposed lift metric is explicitly non-monotonic:
- Low lift can mean below band: model cannot use graph.
- Low lift can mean above band: model did not need graph.
- Positive lift means in band.
So lift is not a ranking scalar. It is at best a detector for an interaction regime.
The regime classifier also becomes unstable under 50% outcome noise. A model can move from “in band” to “below band” across draws without any real capability change. Near boundaries, the classifier is not well-defined unless you estimate probabilities with confidence intervals:
- `P(minimal general)`
- `P(graph general)`
- `P(graph general) - P(minimal general)`
The actual object is not a label. It is a noisy two-arm response curve.
**3. Instance-Difficulty Confound**
Capability is completely entangled with the bug. Flux #1613 may sit in one model’s “hygraph helps” band; Verus #2427 may not. That says as much about those two bugs as about the models.
Without a calibrated bank of instances spanning difficulty, ambiguity, locality, abstraction depth, test-oracle quality, and required generalization type, cross-model ranking is not meaningful. You are measuring `model x bug x prompt x harness x sample` behavior.
A single fixed bug cannot define a capability band. It can only define a case study.
**4. Harness Confound**
Different models ran under different agent scaffolds. That is fatal for ranking.
Sonnet/Fable, Composer, and codex were not just different models; they were different model-plus-tooling systems. Cursor-agent versus codex CLI versus another agent harness can change:
- file search behavior
- edit strategy
- test execution
- context packing
- retry policy
- implicit planning
- patch style
- stopping behavior
Any apparent ranking could be harness ranking. Until the same model is run through multiple harnesses, or all models through one standardized harness, model-level conclusions are not licensed.
**5. Construct Validity**
“Reaches the general fix via perturbation” is not obviously a stable model capability. It may measure an idiosyncratic prompt-instance-sampling interaction.
The strongest valid construct name would be something narrower:
> Conditional responsiveness to diagnosis-by-perturbation prompting on a particular bug class, under a specified agent harness and oracle.
That is not the same as “debugging capability” or even “generalization capability.” It is a situated intervention effect.
The leaky graph prompt makes this worse. If the prompt names the discriminating axis, success may reflect uptake of a hint, not independent diagnostic abstraction.
**6. Practicality**
Compared with established evals, this is slow, hand-graded, high-variance, expensive, and currently single-instance. That is a hard sell.
Its possible niche is not as a leaderboard benchmark. It is as a microscope: a research probe for whether a prompting methodology can move a model from local patching to more general causal debugging on selected hard bugs.
Calling it a “differential capability eval that ranks LLMs” overclaims. Calling it an “interactive intervention probe” is much more defensible.
**On Static, Repeatable, Convergent Evals**
(a) Static/repeatable/convergent are not logically necessary for a valid eval. They are conventions of the benchmark paradigm, but useful ones: they make results comparable across labs, time, and models.
A sequential, anytime-valid, rate-estimating probe can be legitimate. It is not a category error by itself. Many real evaluations estimate stochastic rates rather than deterministic scores.
But it must be described honestly. It yields decisions like:
> Under this bug distribution, harness, prompt pair, oracle, and sampling policy, model M shows positive graph lift at alpha.
That is not the same species as a static benchmark score. It is closer to an experimental assay.
(b) The e-value framing helps only one objection: sampling variance. It gives you a principled way to stop once evidence is strong enough.
It does not fix:
- construct validity
- prompt leakage
- harness confounding
- instance-difficulty confounding
- non-monotonic interpretability
- cross-model comparability
- hand-built oracle bias
It may actually worsen cross-comparability if the “band” intentionally slides. A sliding probe can avoid saturation, but then the quoted result is conditional on the chosen instance difficulty. You no longer have a stable number; you have an adaptive measurement procedure. That can be valid research methodology, but it is weak as a public ranking eval.
**What Would Make It Defensible**
Salvageable, yes, but only with a much narrower claim.
Minimum viable design:
- A bank of at least dozens of bugs, not one or two.
- Bugs stratified by difficulty and generalization type.
- Fixed minimal and graph prompts, with no discriminating-axis leakage.
- Same harness for all models, or a crossed design: every model under every harness.
- Repeated stochastic samples per model-bug-arm cell.
- Automated T1/T2/T3 tests wherever possible.
- Pre-registered oracle construction rules.
- Report `P(minimal T2)`, `P(graph T2)`, lift, and uncertainty intervals, not just regime labels.
- Separate analysis for above-band, in-band, and below-band behavior.
- Sequential testing allowed, but with fixed stopping rules and full accounting of cost.
- Public artifacts: prompts, bugs, tests, patches, seeds/settings, harness versions.
The defensible claim would be:
> Hygraph can be evaluated as an intervention that sometimes increases probability of general fixes on selected debugging instances, and models can be compared by estimated intervention response under controlled conditions.
The current claim, “hygraph debugging is a differential capability eval that ranks LLMs,” is not supported. It collapses under variance, confounding, and non-monotonicity.
