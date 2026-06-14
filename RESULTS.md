# Results

Visual dashboard for the headline case (verus #2219). Argument → [README](README.md) · Lessons → [LESSONS.md](LESSONS.md) · Reproduce → [REPRODUCE.md](REPRODUCE.md) · Raw data → [`pilots/11-verus-2219/`](pilots/11-verus-2219/) ([manifest](pilots/11-verus-2219/MANIFEST.md)).

The bug: a verifier soundness hole whose correct fix is an **XOR-shaped predicate** — flip the *uninhabited-ghost* case (the bug) without touching *genuine divergence* (sound). Narrow fixes get the first arm; only the second arm separates a real fix from a plausible-but-wrong one.

---

## The arc, at a glance

What lifts a model from a narrow patch toward a general fix — and where each lever stops.

| stage | codex `gpt-5.5` (CLI) | Fable `claude-fable-5` (headless) |
|---|---|---|
| prompt methods — 6 × 3 draws | 🔴 narrow (`changed=114`, 0/18 general) | 🔴 narrow ≈ strong prompt (no lift from method) |
| model alone (`minimal_v3`, prompt held constant) | 🔴 narrow (114) | 🟠 **wide-but-broken** (269) — *model lift* |
| + `case-check` tool (execution-gated) | 🟠 wide-but-broken (269) | — |
| + corrected gate (**calibration handed**) | 🔴 **C — oscillates**, implementation wall | 🟢 **near-A — breaks through**, calibration was the wall |
| human maintainer [`#2501`] | 🟢 general + correct | 🟢 general + correct |

**Legend** 🔴 narrow / stalls · 🟠 general on the bug arm but **over-rejects divergence** · 🟢 clears the divergence arm (within coverage)

---

## The decisive cell: the families split

Same divergence diagnosis handed to both models. One can implement the discriminator, the other can't.

```mermaid
flowchart LR
  G["corrected gate<br/>(divergence diagnosis handed)"] --> C["codex"]
  G --> F["Fable"]
  C --> CW["oscillates 2.5h · never breaks p1<br/><b>IMPLEMENTATION WALL</b>"]
  F --> FW["breaks p1 after 5 runs · bug-arm general<br/>held-out twin verifies (generalized)<br/><b>CALIBRATION was the wall</b>"]
  FW --> CB["but misses ho5 (un-calibrated shape)<br/><b>COVERAGE bounds the lift</b>"]
  style CW fill:#fde,stroke:#c33
  style FW fill:#dfd,stroke:#3a3
  style CB fill:#ffd,stroke:#aa3
```

→ codex's wall is **implementation** (calibration doesn't remove it); Fable's was **calibration** (supply it and implementation follows). A genuine model-capability difference, isolated on the discriminator itself — not just the bug arm. Patches: [`gate2_codex_terminated`](pilots/11-verus-2219/patches/gate2_codex_terminated.patch) (C, [oscillation proof](worklog/WORK_LOG.md)) · [`fable_gate2`](pilots/11-verus-2219/patches/fable_gate2.patch) (near-A, [trace analysis](worklog/FABLE_WORKLOG.md)).

---

## Four workflows: the wall is not universal, and recall is not required

The corrected-gate arm, run on two more **model+harness workflows** (2026-06-13). Every verdict is a forced-fresh independent grade (calibrated case-check + `p1`/`p2` preserve + sealed held-outs the model never saw). These are *workflows*, not pure weights — the harness varies by row, so read the claim as scoped to the workflow (LESSONS 14).

| workflow | harness | contamination | impl wall (`p1`/`p2`) | sealed (`proofdiv`/`exec`) | `ho5` | stop rule | outcome |
|---|---|---|:--:|:--:|:--:|---|---|
| codex `gpt-5.5` | codex-CLI | clean | ❌ oscillates 2.5h | — | — | terminated @2.5h, no rerun | 🔴 **C** (impl wall) |
| Fable `claude-fable-5` | claude-headless | **clean** (Jan 2026) | ✅ / ✅ | V / V | ❌R | natural | 🟢 near-A |
| Composer 2.5 | cursor-agent | *not clean* (ships May 2026) | ✅ / ✅ | V / V | ❌R | natural @~1h | 🟢 near-A |
| Sonnet 4.6 | claude-headless | **clean** (Feb 2026) | ✅ / ✅ | V / V | ❌R | **run 1 truncated @3h (did NOT clear); run 2 @4h + snapshot + keepalive** | 🟢 near-A (run 2) |

Three of the four workflows clear the wall to **near-A**, with the *same behavioral carve-out* (clear `p1`/`p2`, miss `ho5`) — though Composer's *implementation* path differs (THIR-erasure `!`→`()` + `skip_remove`, vs Fable/Sonnet's `requires_false`/declared-`!` discriminator). Only codex oscillated. So Outcome C is **not a universal wall** across these workflows — **but the comparison is not protocol-symmetric** (see the caveat below).

**On leakage (scoped).** Composer 2.5 cleared the wall but isn't contamination-clean (it shipped *after* the fix; Cursor attests no cutoff), so its pass is **capability OR fine-tune-recall — recall is not excluded.** What the clean arms establish is narrower: **recall is not *required* for this fix-class**, since two contamination-clean models (Fable, Sonnet 4.6) reach it. The positive anti-recall signal is separate and stronger: the human gold (`#2501`) is *finer* than what any automated arm produced — it clears `ho5`; Composer (and Fable, and Sonnet) miss `ho5`. A model that had memorized the gold would clear `ho5`. Composer landed on the **gate-rewarded attractor, not the gold**, which is evidence against recall of the gold specifically.

**Caveat — convergence may be the gate, not the models.** The shared `ho5` miss is likely the gate *funneling* every successful model into one attractor (satisfy the calibrated `p1`/`p2`, miss the un-calibrated `ho5`), not three independent rediscoveries of the true predicate. So the convergence shows models can implement the gate-rewarded discriminator; it does **not** show independent arrival at the underlying fix. Testing attractor-vs-capability requires adding `ho5`-like preserve cases to the gate.

**Caveat — fairness.** codex was terminated at ~2.5h with no rerun; Sonnet's first run (matched 3h budget) did *not* clear, and it reached near-A only on a second run with a larger budget, a pass-snapshot rule, and an appended operational keepalive the other arms lacked. So Sonnet's win is **"clears under a more forgiving rerun protocol," not "clears where codex walls under equal conditions."** A protocol-matched codex rerun (4h + keepalive) is the missing control before any "efficiency, not endpoint" reading is licensed.

---

## The thesis in one diagram

```mermaid
flowchart TD
  E["enumeration"] -->|inducible| M["model builds a wide gate<br/>(Fable: 6684 cases, no tool)"]
  Cal["calibration / external label"] -->|NOT inducible| X["model mislabels its own hard case (v7)<br/>with the predicate under test"]
  X --> WB["wide-but-broken"]
  S["supply calibration<br/>(golden from approved history)"] --> U["unblocks implementation"]
  U -->|Fable| A["near-general"]
  U -->|codex| W["implementation wall"]
  A --> Cov["coverage bounds the lift"]
  style WB fill:#ffd,stroke:#aa3
  style A fill:#dfd,stroke:#3a3
  style W fill:#fde,stroke:#c33
```

**Enumeration is inducible; calibration is not.** A model can build itself a wide net but not an external oracle, because the correct label *is* the disputed predicate ([the `v7` self-mislabel](worklog/FABLE_WORKLOG.md)). Hand it the label and implementation unblocks — model-dependently — but only as far as the gate's coverage reaches.

---

## The verus #2219 battery

Forced-fresh, identity-verified builds ([why that matters](LESSONS.md)). **Bug** probes must REJECT; **divergence** probes must VERIFY.

| arm | t1 | t2 | h2 (×2) | t3 | ho5 | case-check | bucket | artifacts |
|---|:--:|:--:|:--:|:--:|:--:|---|---|---|
| base (buggy) | V | V | V · V | V | V | `pass=false` | bug present | — |
| #2230 narrow (maintainer) | R | V | — | V | V | `changed=114` | narrow | — |
| codex prompts (best) | R | V | V · V | V | V | `changed≤114` | 🔴 narrow | [patches](pilots/11-verus-2219/patches/) |
| Fable, model alone | R | R | R · R | ❌R | ❌R | `pass=true, 269` | 🟠 wide-but-broken | [`fable_arm`](pilots/11-verus-2219/patches/fable_arm.patch) |
| codex + case-check | R | R | R · R | ❌R | ❌R | `pass=true, 269` | 🟠 wide-but-broken | [`casecheck_pilot`](pilots/11-verus-2219/patches/casecheck_pilot.patch) |
| codex + corrected gate | — oscillates, never stable — | | | | | (C) | 🔴 impl wall | [`gate2_codex…`](pilots/11-verus-2219/patches/gate2_codex_terminated.patch) |
| **Fable + corrected gate** | R | R | R · R | ✅**V** | ❌R | `pass=true, 269` | 🟢 **near-A** | [`fable_gate2`](pilots/11-verus-2219/patches/fable_gate2.patch) |
| **Composer 2.5 + corrected gate** | R | R | R · R | ✅**V** | ❌R | `pass=true, 0 mis` | 🟢 **near-A** | [`composer_gate2`](pilots/11-verus-2219/patches/composer_gate2.patch) |
| **Sonnet 4.6 + corrected gate** | R | R | R · R | ✅**V** | ❌R | `pass=true, 0 mis` | 🟢 **near-A** | [`sonnet_gate2_run2`](pilots/11-verus-2219/patches/sonnet_gate2_run2.patch) |
| #2501 general (maintainer) | R | R | R · R | ✅V | (V) | `mishandles=0` | 🟢 general+correct | — |

`✅`/`❌` mark where the divergence arm is cleared vs over-rejected. The whole study turns on the `t3`/`ho5` columns: every automated arm gets the bug columns; the `t3` divergence arm is cleared only with the corrected gate (Fable, Composer 2.5, Sonnet 4.6 — never by the prompt/tool arms), and **nothing automated clears `ho5`** (only the human gold `#2501` does).

Full provenance-stamped rows: [`clean_dataset.md`](pilots/11-verus-2219/clean_dataset.md) · [`.jsonl`](pilots/11-verus-2219/clean_dataset.jsonl).

---

## Navigate (agents & humans)

| you want… | go to |
|---|---|
| the distilled findings + method lessons | [LESSONS.md](LESSONS.md) |
| to reproduce (with the 5 traps) | [REPRODUCE.md](REPRODUCE.md) · [pilot runbook](pilots/11-verus-2219/REPRODUCE.md) |
| every patch, by arm | [`patches/`](pilots/11-verus-2219/patches/) ([map](pilots/11-verus-2219/MANIFEST.md)) |
| the model session traces | [`logs/`](pilots/11-verus-2219/logs/) · [FABLE_WORKLOG](worklog/FABLE_WORKLOG.md) |
| the gate (enumeration + calibration) | [`tools/case-check.py`](pilots/11-verus-2219/tools/case-check.py) · [`gate2/`](pilots/11-verus-2219/gate2/) |
| the held-outs (outside the gate) | [`oracle/`](pilots/11-verus-2219/oracle/) · [`heldout2/`](pilots/11-verus-2219/heldout2/) · [`gate2/sealed/`](pilots/11-verus-2219/gate2/sealed/) |
| the mechanism dissection + corrections | [MECHANISM-dissection.md](pilots/11-verus-2219/MECHANISM-dissection.md) · [RESULT-corrected.md](pilots/11-verus-2219/RESULT-corrected.md) |
| the tool, generalized | [github.com/kimjune01/abductor](https://github.com/kimjune01/abductor) |

---

*Caveats carried throughout: n=1 per cell, model+harness (not pure weights), and "lift" means narrow→wider, not narrow→correct. The divergence arm is cleared unaided only by the human maintainer. See [LESSONS.md](LESSONS.md) for the full threat list.*
