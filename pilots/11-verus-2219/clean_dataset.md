# Clean verifiable dataset — verus #2219 (forced-fresh, identity-verified builds)

_21 artifacts. Bug probes (t1,t2,h2_assoc,h2_nested) correct=REJECT; sound probes (t3,ho5) correct=VERIFY._

| artifact | tc | applied | rebuilt | t1 | t2 | h2a | h2n | t3 | ho5 | cc.pass | cc.changed | cc.preserve_rej | class |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BASE | 1.93.1 | ok | True | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 0 | 0 | NO-OP (bug intact) |
| casecheck_pilot.patch | 1.93.1 | ok | True | REJECT | REJECT | REJECT | REJECT | REJECT ⚠ | REJECT ⚠ | true | 269 | 0 | GENERAL bug-axis, OVER-REJECTS divergence |
| COMMIT:57212d95 | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_graph_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 0 | 0 | NARROW (! only / partial) |
| v3_graph_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_graph_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_minimal_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_minimal_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 0 | 0 | NARROW (! only / partial) |
| v3_minimal_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_neutral_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_neutral_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_neutral_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 3 | 2 | NARROW (! only / partial) |
| v3_siteenum_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_siteenum_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| v3_siteenum_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| abduction_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| abduction_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| abduction_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| selfverifier_draw1.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| selfverifier_draw2.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |
| selfverifier_draw3.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |

## Integrity checks
- artifacts not confirmed-rebuilt: none ✓
- apply failures: none ✓
- BASE sanity (all 6 must VERIFY = bug present + sound accepted): ✓
