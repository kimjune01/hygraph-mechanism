#!/usr/bin/env python3
import itertools
import json
import os
import subprocess
from pathlib import Path

ROOT = Path("/Users/junekim/Documents/verus-p11")
SOURCE = ROOT / "source"
OUT = Path("/tmp/p11sv-scratch/generated")
REPORT = Path("/tmp/p11sv-scratch/generator_report.json")
COUNTEREXAMPLES = Path("/tmp/p11sv-scratch/counterexamples.md")

ENV = os.environ.copy()
ENV.pop("RUSTC", None)
ENV.pop("RUSTUP_TOOLCHAIN", None)
ENV["PATH"] = "/tmp/rustup-shims:" + ENV.get("PATH", "")


UNINHABITED_TYPES = [
    ("never", "!"),
    ("tuple_never", "(u8, !)"),
    ("nested_never", "Wrap<!>"),
    ("result_never", "Result<!, !>"),
    ("deep_result_never", "Result<(u8, !), Wrap<!>>"),
]

INHABITED_TYPES = [
    ("unit", "()"),
    ("bool", "bool"),
    ("tuple_unit", "(u8, ())"),
    ("tracked_res", "Res"),
]

PRODUCERS = [
    ("arbitrary", "arbitrary::<{ty}>()"),
    ("spec_id_arbitrary", "spec_id::<{ty}>(arbitrary::<{ty}>())"),
    ("assoc_wrap", "Wrap::<{ty}>(arbitrary::<{ty}>()).0"),
    ("block_arbitrary", "({{ arbitrary::<{ty}>() }})"),
    ("if_arbitrary", "(if true {{ arbitrary::<{ty}>() }} else {{ arbitrary::<{ty}>() }})"),
]

SITES = [
    ("direct_arg", "sink::<{ty}>({expr});"),
    ("let_wild", "let _ = {expr};"),
    ("block_stmt", "{{ {expr}; }}"),
    ("if_then", "if true {{ sink::<{ty}>({expr}); }}"),
    ("match_bool", "match true {{ true => sink::<{ty}>({expr}), false => () }}"),
    ("nested_block", "{{ {{ sink::<{ty}>({expr}); }} }}"),
    ("let_unit_block", "let _u: () = {{ sink::<{ty}>({expr}); }};"),
]

RESOURCE_DECLS = [
    ("generic", "proof fn victim<T>(tracked t: T) {", "consume(t);\n    consume(t);"),
    ("concrete", "proof fn victim(tracked t: Res) {", "consume(t);\n    consume(t);"),
    ("tuple", "proof fn victim<T>(tracked t: (T, Res)) {", "consume(t);\n    consume(t);"),
]

VALID_AFTER = [
    ("single_consume", "proof fn victim<T>(tracked t: T) {", "consume(t);"),
    ("real_return", "proof fn victim<T>(tracked t: T) {", "return;\n    consume(t);\n    consume(t);"),
]


def prelude() -> str:
    return """#![allow(internal_features)]
#![feature(never_type)]

use vstd::prelude::*;

verus! {

struct Wrap<T>(T);
struct Res { i: int }

proof fn sink<T>(x: T) { }
proof fn consume<T>(tracked t: T) { }
uninterp spec fn arbitrary<T>() -> T;
spec fn spec_id<T>(x: T) -> T { x }

"""


def render_case(name, ty, producer, site, fn_decl, after, extra_prefix="") -> str:
    expr = producer.format(ty=ty)
    trigger = site.format(ty=ty, expr=expr)
    return prelude() + f"""{extra_prefix}
{fn_decl}
    {trigger}

    {after}
}}

}}

fn main() {{}}
"""


def expected_for(case_kind: str) -> str:
    return "accept" if case_kind == "valid" else "reject"


def classify(stdout: str, stderr: str, code: int) -> str:
    out = stdout + stderr
    if "verification results::" in out and "0 errors" in out and "error[" not in out and code == 0:
        return "accept"
    return "reject"


def run_verus(path: Path):
    cmd = ["./target-verus/release/verus", "--crate-type=lib", str(path)]
    p = subprocess.run(cmd, cwd=SOURCE, env=ENV, text=True, capture_output=True, timeout=60)
    return classify(p.stdout, p.stderr, p.returncode), p.stdout + p.stderr


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    build = subprocess.run(
        ["bash", "-c", "vargo build --release >/tmp/p11sv-scratch/generator_build.log 2>&1"],
        cwd=SOURCE,
        env=ENV,
        text=True,
        capture_output=True,
        timeout=300,
    )
    if build.returncode != 0:
        raise SystemExit("build failed; see /tmp/p11sv-scratch/generator_build.log")

    cases = []
    for (ty_name, ty), (prod_name, prod), (site_name, site), (res_name, fn_decl, after) in itertools.product(
        UNINHABITED_TYPES, PRODUCERS, SITES, RESOURCE_DECLS
    ):
        cases.append(("unsound", f"unsound_{ty_name}_{prod_name}_{site_name}_{res_name}", ty, prod, site, fn_decl, after))

    for (ty_name, ty), (prod_name, prod), (site_name, site) in itertools.product(
        UNINHABITED_TYPES, PRODUCERS, SITES
    ):
        if ty_name == "never":
            continue
        for valid_name, fn_decl, after in VALID_AFTER:
            cases.append(("valid", f"valid_{valid_name}_{ty_name}_{prod_name}_{site_name}", ty, prod, site, fn_decl, after))

    for (ty_name, ty), (prod_name, prod), (site_name, site), (res_name, fn_decl, after) in itertools.product(
        INHABITED_TYPES, PRODUCERS, SITES, RESOURCE_DECLS[:1]
    ):
        cases.append(("unsound", f"inhabited_double_{ty_name}_{prod_name}_{site_name}_{res_name}", ty, prod, site, fn_decl, after))

    results = []
    counterexamples = []
    for idx, (kind, name, ty, prod, site, fn_decl, after) in enumerate(cases):
        path = OUT / f"{idx:04d}_{name}.rs"
        path.write_text(render_case(name, ty, prod, site, fn_decl, after))
        verdict, output = run_verus(path)
        expected = expected_for(kind)
        ok = verdict == expected
        row = {
            "name": name,
            "kind": kind,
            "type": ty,
            "producer": prod,
            "site": site,
            "expected": expected,
            "verdict": verdict,
            "ok": ok,
            "path": str(path),
            "output_tail": output[-2000:],
        }
        results.append(row)
        if not ok:
            counterexamples.append(row)

    REPORT.write_text(json.dumps({"total": len(results), "counterexamples": counterexamples, "results": results}, indent=2))
    with COUNTEREXAMPLES.open("w") as f:
        f.write("# Counterexamples\n\n")
        if not counterexamples:
            f.write("No mishandled generated cases after the final fix.\n")
        else:
            for c in counterexamples:
                f.write(f"## {c['name']}\n\n")
                f.write(f"- expected: {c['expected']}\n- verdict: {c['verdict']}\n- path: {c['path']}\n\n")
                f.write("```text\n" + c["output_tail"] + "\n```\n\n")
    bad = len(counterexamples)
    print(f"generated={len(results)} counterexamples={bad}")
    for c in counterexamples[:20]:
        print(f"BAD {c['name']} expected={c['expected']} verdict={c['verdict']} path={c['path']}")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
