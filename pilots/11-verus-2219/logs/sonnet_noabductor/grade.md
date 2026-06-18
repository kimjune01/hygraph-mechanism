# Clean verifiable dataset — verus #2219 (forced-fresh, identity-verified builds)

_1 artifacts. Bug probes (t1,t2,h2_assoc,h2_nested) correct=REJECT; sound probes (t3,ho5) correct=VERIFY._

| artifact | tc | applied | rebuilt | t1 | t2 | h2a | h2n | t3 | ho5 | cc.pass | cc.changed | cc.preserve_rej | class |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| patches/sonnet_noabductor.patch | 1.93.1 | ok | True | REJECT | VERIFY ⚠ | VERIFY ⚠ | VERIFY ⚠ | VERIFY | VERIFY | false | 114 | 0 | NARROW (! only / partial) |

## Integrity checks
- artifacts not confirmed-rebuilt: none ✓
- apply failures: none ✓
