#!/usr/bin/env python3
"""Render the clean re-grade JSONL into a verifiable markdown table.
Correct verdicts (the oracle): bugs must REJECT, sound/divergence must VERIFY.
  t1,t2,h2_assoc,h2_nested = BUG  -> correct = REJECT
  t3,ho5                    = SOUND-> correct = VERIFY
A fix is GENERAL on the bug axis iff it REJECTs all 4 bug probes AND case-check pass=true.
It is SOUND-PRESERVING iff it VERIFYs t3 and ho5.
Usage: render_dataset.py data.jsonl
"""
import json, sys

CORRECT = {"t1":"REJECT","t2":"REJECT","h2_assoc":"REJECT","h2_nested":"REJECT","t3":"VERIFY","ho5":"VERIFY"}
BUGS = ["t1","t2","h2_assoc","h2_nested"]; SOUND=["t3","ho5"]

rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]

def cls(r):
    b=r.get("battery")
    if not b: return "BUILD/APPLY FAIL"
    cc=r.get("casecheck") or {}
    bugs_rej=all(b.get(k)=="REJECT" for k in BUGS)
    sound_ok=all(b.get(k)=="VERIFY" for k in SOUND)
    ccpass=cc.get("pass")=="true"
    if bugs_rej and ccpass and sound_ok: return "GENERAL+SOUND (matches #2501 target)"
    if bugs_rej and ccpass and not sound_ok: return "GENERAL bug-axis, OVER-REJECTS divergence"
    if b.get("t1")=="REJECT" and not bugs_rej: return "NARROW (! only / partial)"
    if all(b.get(k)=="VERIFY" for k in BUGS): return "NO-OP (bug intact)"
    return "OTHER"

print("# Clean verifiable dataset — verus #2219 (forced-fresh, identity-verified builds)\n")
print(f"_{len(rows)} artifacts. Bug probes (t1,t2,h2_assoc,h2_nested) correct=REJECT; sound probes (t3,ho5) correct=VERIFY._\n")
hdr=["artifact","tc","applied","rebuilt","t1","t2","h2a","h2n","t3","ho5","cc.pass","cc.changed","cc.preserve_rej","class"]
print("| "+" | ".join(hdr)+" |"); print("|"+"|".join("---" for _ in hdr)+"|")
def mark(k,v): return v+("" if v==CORRECT.get(k,v) else " ⚠")
for r in rows:
    b=r.get("battery") or {}; cc=r.get("casecheck") or {}
    cells=[r["artifact"], r.get("toolchain","?"), r.get("applied","?"), str(r.get("rebuilt","?")),
           mark("t1",b.get("t1","-")),mark("t2",b.get("t2","-")),mark("h2_assoc",b.get("h2_assoc","-")),
           mark("h2_nested",b.get("h2_nested","-")),mark("t3",b.get("t3","-")),mark("ho5",b.get("ho5","-")),
           str(cc.get("pass","-")),str(cc.get("changed","-")),str(cc.get("valid_preserve_rejected","-")), cls(r)]
    print("| "+" | ".join(cells)+" |")

# integrity checks
print("\n## Integrity checks")
notreb=[r["artifact"] for r in rows if r.get("rebuilt") not in (True,"true")]
print(f"- artifacts not confirmed-rebuilt: {notreb or 'none ✓'}")
af=[r["artifact"] for r in rows if r.get("applied") not in ("ok","empty-patch") and r["artifact"]!="BASE" and not str(r['artifact']).startswith('COMMIT')]
print(f"- apply failures: {af or 'none ✓'}")
base=[r for r in rows if r["artifact"]=="BASE"]
if base:
    b=base[0].get("battery") or {}
    ok=all(v=="VERIFY" for v in b.values()) if b else False
    print(f"- BASE sanity (all 6 must VERIFY = bug present + sound accepted): {'✓' if ok else '✗ '+str(b)}")
