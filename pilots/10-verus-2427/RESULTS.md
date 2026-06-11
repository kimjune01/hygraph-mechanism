# Pilot 10 — Verus #2427: NULL for codex (graph did NOT beat minimal)

| program     | base  | narrow #2446 | general #2474 | codex minimal | codex graph |
|-------------|-------|--------------|---------------|---------------|-------------|
| T1 closure  | FAIL  | VERIFY       | VERIFY        | VERIFY        | VERIFY      |
| T2 toplevel | FAIL  | FAIL         | VERIFY        | **FAIL**      | **FAIL**    |
| T3 unsound  | FAIL  | FAIL         | FAIL          | FAIL          | FAIL        |

**Verdict: NO DIVERGENCE.** Both codex arms produced the NARROW fix (T1 pass, T2 fail, T3 sound),
both editing `ast_simplify.rs` closure lowering — i.e. both reproduced the maintainers' OWN
first attempt (#2446), neither reached the general fix (#2474).

## Why it nulled (this is the value, not the null itself)
The graph arm did RIGOROUS, CORRECT diagnosis — a real hypothesis graph (H0..F1):
- killed: concrete `Seq<u32>` verifies (assoc-type return needed), `type Item = u32` verifies
  (closure-output projection needed), less-generic wrapper verifies;
- localized via AIR dump to the missing closure `FnOnce::Output` equality;
- found the literal `TODO: include Output associated type` in closure datatype synthesis;
- fixed exactly that: synthesize the closure `FnOnce::Output` AssocTypeImpl.
Its 5 generalization probes (closure_bool, generic_param, concrete_seq, no_closure_assoc,
non_generic_w) all varied dimensions DOWNSTREAM of the closure — but EVERY probe kept the
function value a CLOSURE. It never varied the function-value KIND (closure -> top-level `fn` ->
generic `fn`), which is the EXACT axis that separates narrow (#2446) from general (#2474).
So it root-caused correctly, generalized within "closures", and missed the FnDef case — the
same narrow-first error the maintainers made.

## Lesson: the methodology is not a guarantee
Graph-style diagnosis helps ONLY when the agent's perturbation set includes the discriminating
dimension. Here it didn't, so graph == minimal. This bounds the existence claim and matches
codex's own critique ("not reliable / not robust").

## CONFOUND this exposes in pilot 09 (flux) — must disclose
The flux graph PROMPT listed "the sort of the refinement component (a function sort vs a plain
int component)" as a perturbation dimension — which IS the flux T2 discriminator axis. The Verus
graph prompt was kept GENERIC and did NOT name the closure-vs-FnDef axis. So the two graph prompts
were NOT symmetric in leakage:
  - flux (axis NAMED in prompt) -> diverged (graph reached T2-general).
  - verus (axis NOT named)      -> nulled (graph stayed narrow).
This raises a live alternative explanation: part of the flux divergence may be PROMPT-LEAKAGE
(the prompt pointed the agent at the discriminating dimension), not the hypothesis-graph mechanism
per se. NOT proven, but it is now the most important confound to rule out.

## Next experiment (decisive): de-confound flux
Rerun the flux graph arms with the GENERIC (non-leaking) prompt — dimensions described abstractly,
the function-vs-int sort axis NOT named. If they still reach T2-general -> the mechanism is real.
If they null like Verus -> the flux divergence was substantially prompt-leakage.
