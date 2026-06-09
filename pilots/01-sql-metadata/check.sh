#!/bin/bash
# run-handle: score agent's SOURCE (test dir excluded) against hidden F2P tests; PASS/FAIL only
F2P="test/test_unions.py::test_union_column_aliases test/test_unions.py::test_union_alias_with_expression_targets"
cd /tmp/sqlmeta_work && git diff HEAD -- . ':(exclude)test/' > /tmp/agent_src.patch 2>/dev/null
cd /tmp/sqlmeta_grade && git reset -q --hard gradebase
if [ -s /tmp/agent_src.patch ]; then
  git apply /tmp/agent_src.patch 2>/dev/null || { echo "CHECK: FAIL (patch did not apply)"; exit 1; }
fi
. .venv/bin/activate
if python -m pytest $F2P -q >/tmp/check_out.log 2>&1; then
  echo "CHECK: PASS ($(grep -oE '[0-9]+ passed' /tmp/check_out.log | head -1))"
else
  echo "CHECK: FAIL ($(grep -oE '[0-9]+ (failed|error)' /tmp/check_out.log | head -1))"
fi
