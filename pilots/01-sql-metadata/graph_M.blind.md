# Hypothesis Graph — sql-metadata #401: Aliases with UNION

## Bug Statement

```sql
select a.A as M from tab1 a
union all
select b.B as M from tab2 b
```

```python
Parser(SQL).columns_aliases
# Actual:   {'M': 'tab2.B'}          (one branch; issue reports 'tab1.A' but both are wrong)
# Expected: {'M': ['tab1.A', 'tab2.B']}
```

---

## Candidate Root Causes (abduced from issue)

Three plausible explanations for why only one source column survives:

| # | Hypothesis | Predicted mechanism |
|---|---|---|
| H1 | **Alias map overwrites on collision** — `alias_map[name] = target` is a plain dict assignment; second UNION branch clobbers first | `_Collector.add_alias` line 203 |
| H2 | **UniqueList dedup swallows duplicate alias name** — `alias_names` deduplicates `'M'`, preventing the second `add_alias` call | `_Collector.alias_names.append` line 199 |
| H3 | **UNION walk visits only first SELECT branch** — the AST walk doesn't recurse into the second UNION arm | `ColumnExtractor._walk` / `_walk_children` |

---

## Evidence Traces

### H3: Does the walk visit both UNION branches?

**Perturbation:** traced `add_alias` calls.

```
add_alias(name='M', target='tab1.A', clause='select')   ← first branch visited
add_alias(name='M', target='tab2.B', clause='select')   ← second branch visited
```

**Verdict: H3 killed.** Both branches are walked. The walk is correct; both `add_alias` calls fire.

---

### H2: Does UniqueList suppress the second `add_alias` call?

**Perturbation:** direct UniqueList test.

```python
ul = UniqueList(); ul.append('M'); ul.append('M')
# → ['M']  (deduplicates)
```

`alias_names.append('M')` on the second branch silently no-ops. This means `alias_names` only records `'M'` once — consistent with correct behavior (you only want the alias name listed once). But the dedup is on `alias_names`, not on `alias_map`. The `add_alias` method still runs to completion on both calls; the dedup does not gate the second call.

**Verdict: H2 not the cause.** Dedup on `alias_names` is harmless and correct; it does not prevent the `alias_map` assignment.

---

### H1: Does the alias map overwrite on the second call?

**Perturbation:** traced `alias_map` state before and after each `add_alias` call.

```
add_alias(name='M', target='tab1.A', clause='select')
  alias_map before: {}
  alias_map after:  {'M': 'tab1.A'}

add_alias(name='M', target='tab2.B', clause='select')
  alias_map before: {'M': 'tab1.A'}
  alias_map after:  {'M': 'tab2.B'}
```

**Verdict: H1 confirmed.** The second assignment overwrites the first. The final map contains only `'tab2.B'`. (The issue text reports `'tab1.A'` — that is the opposite of what HEAD produces; the overwrite race is non-deterministic with respect to which branch wins, or the issue was filed against a slightly different version. The bug class is identical: plain-overwrite keeps exactly one source column.)

---

## Code Localization

### Primary suspect

**File:** `sql_metadata/column_extractor.py`  
**Class:** `_Collector`  
**Method:** `add_alias`  
**Lines:** 188–203

```python
def add_alias(self, name: str, target: Any, clause: str) -> None:
    self.alias_names.append(name)                                    # 199
    if clause:                                                       # 200
        self.alias_dict.setdefault(clause, UniqueList()).append(name)# 201
    if target is not None:                                           # 202
        self.alias_map[name] = target                               # 203  ← BUG
```

Line 203 is a plain dict assignment. When the same alias name appears in two UNION branches, the second call clobbers the first. No aggregation, no list promotion.

### Why the resolver doesn't rescue it

`NestedResolver.resolve` receives the already-clobbered `alias_map` (traced: enters with `{'M': 'tab2.B'}`, exits unchanged). The resolver is downstream and cannot reconstruct the discarded first mapping.

---

## Simulation of Fix (read-only verification)

Replaced `add_alias` with an aggregating version:

```python
if target is not None:
    if name in self.alias_map:
        existing = self.alias_map[name]
        if isinstance(existing, list):
            if target not in existing:
                existing.append(target)
        else:
            if existing != target:
                self.alias_map[name] = [existing, target]
    else:
        self.alias_map[name] = target
```

Result:

```
columns_aliases: {'M': ['tab1.A', 'tab2.B']}
columns_dict:    {'select': ['tab1.A', 'tab2.B']}
```

Matches the expected output from the issue exactly.

---

## Surviving Hypothesis

**H1 is the root cause.**

A UNION query produces one `exp.Select` node per branch. The AST walk visits both. Each branch has `SELECT ... AS M`, so `_handle_alias` → `_Collector.add_alias` is called twice with the same alias name `'M'` but different targets. The assignment `self.alias_map[name] = target` (line 203) has no collision-handling logic, so the second write destroys the first.

---

## Predicted Fix

**Where:** `sql_metadata/column_extractor.py`, `_Collector.add_alias`, line 203.

**Shape:** Replace the plain `dict.__setitem__` assignment with aggregation logic:
- If the alias name is not yet in `alias_map`, assign normally (preserves all current single-branch behavior).
- If it is already present and the new target differs, promote the value to a list (or extend an existing list).

The `alias_names` UniqueList dedup is correct and should not change — an alias name appearing in multiple UNION branches is still a single logical alias.

No changes are needed in `NestedResolver`, `Parser`, or the AST walk — the bug is entirely in the one-liner at `_Collector.add_alias:203`.
