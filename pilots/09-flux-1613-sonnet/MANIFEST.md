# Pilot 09 artifact manifest — flux #1613 divergence, multi-model

Base commit 68d61714. Oracle in oracle/ (t1_issue1613.rs, t2_receipt_int.rs, t3_unsound_twin.rs, grade.sh).
Each arm captured as a source-only patch (git diff) taken BEFORE reset, graded on a fresh base.

| model        | arm     | patch                      | scratch / trail              | T1 | T2 | T3 |
|--------------|---------|----------------------------|------------------------------|----|----|----|
| GPT-5.5      | minimal | ../08-flux-1613/minimal_solution.patch          | (pilot 08)              | V  | E  | E  |
| GPT-5.5      | graph   | ../08-flux-1613/graph_arm/graph_arm_src.patch   | ../08-flux-1613/graph_arm/   | V  | V  | E  |
| Sonnet 4.6   | minimal | sonnet_minimal.patch       | (scratch lost to rm -rf)     | V  | E  | V! |
| Sonnet 4.6   | graph   | sonnet_graph.patch         | sonnet_graph_scratch/        | V  | V  | E  |
| Composer 2.5 | minimal | composer_minimal.patch     | composer_minimal_scratch/    | V  | E  | V! |
| Composer 2.5 | graph   | composer_graph.patch       | composer_graph_scratch/      | V  | E  | E  |
| Fable 5      | minimal | fable_minimal.patch        | fable_minimal_scratch/       | .. | .. | .. |
| Fable 5      | graph   | fable_graph.patch          | fable_graph_scratch/         | .. | .. | .. |

V = VERIFY, E = E0999 (rejected), V! = unsound (accepted the invalid twin). Fable pending.
Run logs: /tmp/{cursor,fable}-{min,graph}-run.log (transient; key reports quoted in pilot notes).
