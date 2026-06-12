#!/usr/bin/env python3
"""
Generate and run Verus coverage cases for ghost/spec uninhabited values that can
make rustc prune the post-call CFG edge before Verus checks tracked linearity.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


DEFAULT_VERUS = "/Users/junekim/Documents/verus-p11/source/target-verus/release/verus"
DEFAULT_WRITE_DIR = "/tmp/case-check/generated"
DEFAULT_CALIBRATION = "/tmp/case-check/calibration.json"


@dataclasses.dataclass(frozen=True)
class TypeCase:
    id: str
    ty: str
    uninhabited: bool
    family: str
    depth: int
    native_recursive_uninhabited: bool = False
    array_zero: bool = False
    definitions: tuple[str, ...] = ()


@dataclasses.dataclass(frozen=True)
class Producer:
    id: str
    statement_template: str
    erasure: str
    harness: str

    def statement(self, ty: str) -> str:
        return self.statement_template.format(ty=ty)


@dataclasses.dataclass(frozen=True)
class Pattern:
    id: str
    proof_template: str
    exec_template: str

    def body(self, producer: Producer, producer_stmt: str) -> str:
        template = self.exec_template if producer.harness == "exec" else self.proof_template
        return template.format(producer=producer_stmt)

    def label_expected(self, producer: Producer) -> tuple[str, str]:
        if self.id == "double_after" and producer.erasure == "ghost-erased":
            return ("UNSOUND", "REJECTED")
        return ("SOUND", "ACCEPTED")


@dataclasses.dataclass(frozen=True)
class Case:
    id: str
    label: str
    expected: str
    type_case: TypeCase
    producer: Producer
    pattern: Pattern
    path: Path
    source: str

    @property
    def inhab(self) -> str:
        return "uninhabited" if self.type_case.uninhabited else "inhabited"

    @property
    def cell(self) -> tuple[str, str]:
        return (self.inhab, self.producer.erasure)


@dataclasses.dataclass(frozen=True)
class Result:
    case: Case
    actual: str
    rc: int | None
    timed_out: bool
    stdout: str
    stderr: str

    @property
    def output(self) -> str:
        return f"{self.stdout}\n{self.stderr}"


def slug(s: str) -> str:
    s = s.replace("!", "never")
    s = re.sub(r"[^A-Za-z0-9]+", "_", s)
    return s.strip("_").lower()


@dataclasses.dataclass(frozen=True)
class TypeUniverse:
    cases: list[TypeCase]


def merge_definitions(*items: TypeCase, extra: str | None = None) -> tuple[str, ...]:
    merged: list[str] = []
    seen: set[str] = set()
    for item in items:
        for definition in item.definitions:
            if definition not in seen:
                seen.add(definition)
                merged.append(definition)
    if extra is not None and extra not in seen:
        merged.append(extra)
    return tuple(merged)


def pick_by_status(nodes: list[TypeCase], per_status: int) -> list[TypeCase]:
    picked: list[TypeCase] = []
    for status in (True, False):
        seen = 0
        for node in nodes:
            if node.uninhabited == status:
                picked.append(node)
                seen += 1
                if seen >= per_status:
                    break
    return picked


def generate_type_universe(max_depth: int = 2) -> TypeUniverse:
    # Original fixpoint-style inhabitation over Rust type formers.
    all_types: list[TypeCase] = [
        TypeCase("never", "!", True, "atom-never", 0),
        TypeCase("void_enum", "Void", True, "atom-empty-enum", 0),
        TypeCase("bool", "bool", False, "atom-inhabited", 0),
    ]
    by_ty = {tc.ty for tc in all_types}
    native_index = 0

    def add_type(tc: TypeCase) -> None:
        if tc.ty in by_ty:
            return
        by_ty.add(tc.ty)
        all_types.append(tc)

    def native_name(kind: str, depth: int) -> str:
        nonlocal native_index
        native_index += 1
        return f"Gen{kind}D{depth}_{native_index}"

    for depth in range(1, max_depth + 1):
        previous = [tc for tc in all_types if tc.depth == depth - 1]
        unary_inputs = previous if depth == 1 else pick_by_status(previous, 4)
        for child in unary_inputs:
            add_type(
                TypeCase(
                    f"tuple1_{depth}_{child.id}",
                    f"({child.ty},)",
                    child.uninhabited,
                    "tuple",
                    depth,
                    definitions=child.definitions,
                )
            )

            struct_name = native_name("Struct", depth)
            struct_def = f"struct {struct_name} {{\n    f: {child.ty},\n}}\n"
            add_type(
                TypeCase(
                    f"native_struct_{slug(struct_name)}",
                    struct_name,
                    child.uninhabited,
                    "native-struct",
                    depth,
                    native_recursive_uninhabited=child.uninhabited,
                    definitions=merge_definitions(child, extra=struct_def),
                )
            )

            enum_name = native_name("Enum", depth)
            enum_def = f"enum {enum_name} {{\n    A({child.ty}),\n}}\n"
            add_type(
                TypeCase(
                    f"native_enum_{slug(enum_name)}",
                    enum_name,
                    child.uninhabited,
                    "native-enum",
                    depth,
                    native_recursive_uninhabited=child.uninhabited,
                    definitions=merge_definitions(child, extra=enum_def),
                )
            )

            add_type(
                TypeCase(
                    f"option_{depth}_{child.id}",
                    f"Option<{child.ty}>",
                    False,
                    "option",
                    depth,
                    definitions=child.definitions,
                )
            )
            add_type(
                TypeCase(
                    f"box_{depth}_{child.id}",
                    f"Box<{child.ty}>",
                    False,
                    "box",
                    depth,
                    definitions=child.definitions,
                )
            )
            add_type(
                TypeCase(
                    f"array0_{depth}_{child.id}",
                    f"[{child.ty}; 0]",
                    False,
                    "array-zero",
                    depth,
                    array_zero=True,
                    definitions=child.definitions,
                )
            )
            add_type(
                TypeCase(
                    f"array1_{depth}_{child.id}",
                    f"[{child.ty}; 1]",
                    child.uninhabited,
                    "array-nonzero",
                    depth,
                    definitions=child.definitions,
                )
            )

        binary_inputs = pick_by_status(previous, 2 if depth == 1 else 1)
        for left in binary_inputs:
            for right in binary_inputs:
                add_type(
                    TypeCase(
                        f"tuple2_{depth}_{left.id}_{right.id}",
                        f"({left.ty}, {right.ty})",
                        left.uninhabited or right.uninhabited,
                        "tuple",
                        depth,
                        definitions=merge_definitions(left, right),
                    )
                )

                enum_name = native_name("Enum", depth)
                enum_def = f"enum {enum_name} {{\n    A({left.ty}),\n    B({right.ty}),\n}}\n"
                add_type(
                    TypeCase(
                        f"native_enum_{slug(enum_name)}",
                        enum_name,
                        left.uninhabited and right.uninhabited,
                        "native-enum",
                        depth,
                        native_recursive_uninhabited=left.uninhabited and right.uninhabited,
                        definitions=merge_definitions(left, right, extra=enum_def),
                    )
                )

                add_type(
                    TypeCase(
                        f"result_{depth}_{left.id}_{right.id}",
                        f"Result<{left.ty}, {right.ty}>",
                        left.uninhabited and right.uninhabited,
                        "result",
                        depth,
                        definitions=merge_definitions(left, right),
                    )
                )

    return TypeUniverse(all_types)


def producers() -> list[Producer]:
    return [
        Producer("spec_arg", "sink::<{ty}>(arbitrary::<{ty}>());", "ghost-erased", "proof"),
        Producer("spec_let", "let _x: {ty} = arbitrary::<{ty}>();", "ghost-erased", "proof"),
        Producer("spec_match", "match arbitrary::<{ty}>() {{ _ => {{ }} }}", "ghost-erased", "proof"),
        Producer("proof_stmt_tracked", "make_tracked::<{ty}>();", "ghost-erased", "proof"),
        Producer("proof_let_tracked", "let tracked _x: {ty} = make_tracked::<{ty}>();", "ghost-erased", "proof"),
        Producer("proof_stmt_ghost", "make_ghost::<{ty}>();", "ghost-erased", "proof"),
        Producer("proof_let_ghost", "let _x: {ty} = make_ghost::<{ty}>();", "ghost-erased", "proof"),
        Producer("runtime_stmt", "runtime_diverge();", "runtime-real", "exec"),
    ]


def patterns() -> list[Pattern]:
    return [
        Pattern(
            "double_after",
            """
    consume(t);
    {producer}
    consume(t);
""",
            """
    proof {{ consume(t); }}
    {producer}
    proof {{ consume(t); }}
""",
        ),
        Pattern(
            "single_after",
            """
    {producer}
    consume(t);
""",
            """
    {producer}
    proof {{ consume(t); }}
""",
        ),
        Pattern(
            "double_after_return",
            """
    {producer}
    return;
    consume(t);
    consume(t);
""",
            """
    {producer}
    return;
    proof {{ consume(t); }}
    proof {{ consume(t); }}
""",
        ),
    ]


COMMON_PREFIX = """#![feature(rustc_attrs)]
#![feature(never_type)]
#![allow(unreachable_code)]
#![allow(unused_variables)]
#![allow(dead_code)]

use vstd::prelude::*;

verus! {

#[verifier::external]
enum Void { }

#[verifier::external_type_specification]
#[verifier::external_body]
struct ExVoid(Void);

#[verifier::external]
struct HasVoid {
    field: Void,
}

#[verifier::external_type_specification]
#[verifier::external_body]
struct ExHasVoid(HasVoid);

struct UnitStruct { }

enum OneEnum {
    A,
}

{type_definitions}

tracked struct Token { }

proof fn consume(tracked t: Token) { }

proof fn sink<T>(x: T) { }

uninterp spec fn arbitrary<T>() -> T;

#[verifier::external_body]
proof fn make_tracked<T>() -> (tracked v: T) {
    loop { }
}

#[verifier::external_body]
proof fn make_ghost<T>() -> T {
    loop { }
}

#[verifier::external_body]
fn runtime_diverge() -> ! {
    loop { }
}

"""


COMMON_SUFFIX = """
}

fn main() { }
"""


def render_case(case_id: str, body: str, harness: str, type_definitions: str) -> str:
    signature = f"fn {case_id}(tracked t: Token)" if harness == "exec" else f"proof fn {case_id}(tracked t: Token)"
    return (
        COMMON_PREFIX.replace("{type_definitions}", type_definitions)
        + f"{signature} {{\n"
        + body
        + "}\n"
        + COMMON_SUFFIX
    )


def generate_cases(write_dir: Path) -> list[Case]:
    cases: list[Case] = []
    write_dir.mkdir(parents=True, exist_ok=True)
    universe = generate_type_universe()
    pats = patterns()
    for tc in universe.cases:
        for prod in producers():
            for pat in pats:
                # Inhabited double-consume controls are still UNSOUND and should
                # reject, but they are not counted as the target uninhabited bug.
                case_id = slug(f"case_{tc.id}_{prod.id}_{pat.id}")
                path = write_dir / f"{case_id}.rs"
                label, expected = pat.label_expected(prod)
                source = render_case(
                    case_id,
                    pat.body(prod, prod.statement(tc.ty)),
                    prod.harness,
                    "\n".join(tc.definitions),
                )
                cases.append(
                    Case(
                        id=case_id,
                        label=label,
                        expected=expected,
                        type_case=tc,
                        producer=prod,
                        pattern=pat,
                        path=path,
                        source=source,
                    )
                )
    return cases


ACCEPT_RE = re.compile(r"verification results::\s+\d+\s+verified,\s+0\s+errors")
NONZERO_ERRORS_RE = re.compile(r"verification results::.*,\s*[1-9]\d*\s+errors")
VERIFICATION_RESULTS_RE = re.compile(r"verification results::")
COMPILE_DIAGNOSTIC_RE = re.compile(r"\berror\[E\d+\]")
CRASH_RE = re.compile(
    r"internal compiler error|thread '.*?' panicked|RUST_BACKTRACE|"
    r"\bAborted\b|\bSIGABRT\b|\bSIGSEGV\b|segmentation fault|"
    r"terminated by signal|\bsignal[: ]+(?:6|11|SIGABRT|SIGSEGV)\b",
    re.IGNORECASE,
)


def classify(output: str, rc: int | None, timed_out: bool) -> str:
    if timed_out:
        return "CRASH"
    has_verification_results = VERIFICATION_RESULTS_RE.search(output) is not None
    lower_output = output.lower()
    has_compile_diagnostic = (
        COMPILE_DIAGNOSTIC_RE.search(output) is not None
        or "cannot find" in lower_output
        or "expected" in lower_output
    )
    if CRASH_RE.search(output):
        return "CRASH"
    if ACCEPT_RE.search(output) and "error[" not in output and "\nerror:" not in output:
        return "ACCEPTED"
    rejection_needles = [
        "use of moved value",
        "value used here after move",
        "borrow of moved value",
        "verification error",
        "never-to-any coercion",
        "assertion failed",
        "precondition",
        "postcondition",
    ]
    if NONZERO_ERRORS_RE.search(output):
        return "REJECTED"
    if any(needle in output for needle in rejection_needles):
        return "REJECTED"
    if not has_verification_results and has_compile_diagnostic:
        return "FAILED-TO-COMPILE"
    if rc not in (None, 0) and not has_verification_results and not has_compile_diagnostic:
        return "CRASH"
    return "FAILED-TO-COMPILE"


def run_case(case: Case, verus: str, timeout: float) -> Result:
    env = os.environ.copy()
    env["PATH"] = f"/tmp/rustup-shims:{env.get('PATH', '')}"
    env.pop("RUSTC", None)
    env.pop("RUSTUP_TOOLCHAIN", None)
    cmd = [verus, "--crate-type=lib", str(case.path)]
    try:
        proc = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            env=env,
            timeout=timeout,
        )
        actual = classify(proc.stdout + "\n" + proc.stderr, proc.returncode, False)
        return Result(case, actual, proc.returncode, False, proc.stdout, proc.stderr)
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout if isinstance(exc.stdout, str) else ""
        stderr = exc.stderr if isinstance(exc.stderr, str) else ""
        return Result(case, "CRASH", None, True, stdout, stderr)


def run_cases(cases: list[Case], verus: str, timeout: float, jobs: int, verbose: bool, verb: str) -> list[Result]:
    results: list[Result] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as executor:
        futures = [executor.submit(run_case, case, verus, timeout) for case in cases]
        for i, future in enumerate(concurrent.futures.as_completed(futures), 1):
            result = future.result()
            results.append(result)
            if verbose:
                print(
                    f"[{i:03d}/{len(cases):03d}] {verb} {result.case.id} "
                    f"label={result.case.label} expected={result.case.expected} actual={result.actual}"
                )

    results.sort(key=lambda r: r.case.id)
    return results


def is_mishandle(result: Result) -> bool:
    if result.actual == "FAILED-TO-COMPILE":
        return False
    case = result.case
    return (case.label == "UNSOUND" and result.actual == "ACCEPTED") or (
        case.label == "SOUND" and result.actual == "REJECTED"
    )


def calibration_scope(result: Result) -> str:
    if result.actual == "FAILED-TO-COMPILE":
        return "excluded-compile"
    if result.actual == "CRASH":
        return "excluded-crash"
    if result.case.label == "UNSOUND":
        if result.actual == "ACCEPTED":
            return "valid-bug"
        return "excluded-unsoundrej"
    if result.case.label == "SOUND":
        if result.actual == "ACCEPTED":
            return "valid-preserve"
        return "excluded-soundrej"
    return "excluded-compile"


def type_stats_from_cases(cases: list[Case]) -> dict[str, int]:
    by_id: dict[str, TypeCase] = {}
    for case in cases:
        by_id[case.type_case.id] = case.type_case
    type_cases = list(by_id.values())
    return {
        "types": len(type_cases),
        "native_recursive_uninhabited_types": sum(1 for tc in type_cases if tc.native_recursive_uninhabited),
        "array_zero_types": sum(1 for tc in type_cases if tc.array_zero),
    }


def build_calibration(results: list[Result], base_verus: str) -> dict[str, object]:
    entries: dict[str, dict[str, str]] = {}
    for result in results:
        case = result.case
        entries[case.id] = {
            "base_verdict": result.actual,
            "scope": calibration_scope(result),
            "label": case.label,
            "expected": case.expected,
            "type": case.type_case.id,
            "type_family": case.type_case.family,
            "inhab": case.inhab,
            "producer": case.producer.id,
            "erasure": case.producer.erasure,
            "pattern": case.pattern.id,
        }
    return {
        "version": 2,
        "base_verus": base_verus,
        "type_stats": type_stats_from_cases([r.case for r in results]),
        "cases": entries,
    }


def save_calibration(calibration: dict[str, object], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(calibration, indent=2, sort_keys=True) + "\n")


def load_calibration(path: Path) -> dict[str, object]:
    with path.open() as f:
        calibration = json.load(f)
    if not isinstance(calibration, dict) or not isinstance(calibration.get("cases"), dict):
        raise ValueError(f"invalid calibration file: {path}")
    return calibration


def calibration_counts(calibration: dict[str, object]) -> dict[str, int]:
    counts = {
        "valid-bug": 0,
        "valid-preserve": 0,
        "excluded-soundrej": 0,
        "excluded-compile": 0,
        "excluded-unsoundrej": 0,
        "excluded-crash": 0,
    }
    cases = calibration["cases"]
    assert isinstance(cases, dict)
    for entry in cases.values():
        if not isinstance(entry, dict):
            continue
        scope = entry.get("scope")
        if isinstance(scope, str):
            counts[scope] = counts.get(scope, 0) + 1
    return counts


CELL_ORDER = [
    ("uninhabited", "ghost-erased"),
    ("uninhabited", "runtime-real"),
    ("inhabited", "ghost-erased"),
    ("inhabited", "runtime-real"),
]


def is_in_scope_entry(entry: dict[str, object]) -> bool:
    return entry.get("scope") not in ("excluded-compile", "excluded-crash")


def calibration_cell_counts(calibration: dict[str, object]) -> dict[tuple[str, str], int]:
    counts = {cell: 0 for cell in CELL_ORDER}
    cases = calibration["cases"]
    assert isinstance(cases, dict)
    for entry in cases.values():
        if not isinstance(entry, dict) or not is_in_scope_entry(entry):
            continue
        inhab = entry.get("inhab")
        erasure = entry.get("erasure")
        if isinstance(inhab, str) and isinstance(erasure, str) and (inhab, erasure) in counts:
            counts[(inhab, erasure)] += 1
    return counts


def offdiag_covered(cell_counts: dict[tuple[str, str], int]) -> bool:
    return all(cell_counts[cell] > 0 for cell in CELL_ORDER)


def format_cell_counts(cell_counts: dict[tuple[str, str], int]) -> str:
    return " ".join(f"{inhab}/{erasure}={cell_counts[(inhab, erasure)]}" for inhab, erasure in CELL_ORDER)


def print_calibration_stats(calibration: dict[str, object], path: Path) -> None:
    counts = calibration_counts(calibration)
    total = sum(counts.values())
    type_stats = calibration.get("type_stats")
    if not isinstance(type_stats, dict):
        type_stats = {}
    cell_counts = calibration_cell_counts(calibration)
    print(
        "calibration: "
        f"valid-bug={counts['valid-bug']} "
        f"valid-preserve={counts['valid-preserve']} "
        f"excluded-soundrej={counts['excluded-soundrej']} "
        f"excluded-compile={counts['excluded-compile']} "
        f"excluded-unsoundrej={counts['excluded-unsoundrej']} "
        f"excluded-crash={counts['excluded-crash']} "
        f"total={total} "
        f"types={type_stats.get('types', 0)} "
        f"native-rec-uninh-types={type_stats.get('native_recursive_uninhabited_types', 0)} "
        f"array-zero-types={type_stats.get('array_zero_types', 0)} "
        f"cells={format_cell_counts(cell_counts)} "
        f"offdiag-covered={str(offdiag_covered(cell_counts)).lower()} "
        f"saved={path}"
    )


def candidate_mishandle(result: Result, calibration_entry: dict[str, object]) -> bool:
    scope = calibration_entry.get("scope")
    if scope == "valid-bug":
        return result.actual == "ACCEPTED"
    if scope == "valid-preserve":
        return result.actual == "REJECTED"
    return False


def grade_candidate(results: list[Result], calibration: dict[str, object]) -> list[Result]:
    calibrated_cases = calibration["cases"]
    assert isinstance(calibrated_cases, dict)
    missing = [result.case.id for result in results if result.case.id not in calibrated_cases]
    if missing:
        shown = ", ".join(sorted(missing)[:5])
        raise ValueError(f"candidate generated cases missing from calibration: {shown}")
    return [
        result
        for result in results
        if candidate_mishandle(result, calibrated_cases[result.case.id])
    ]


def candidate_change_summary(results: list[Result], calibration: dict[str, object]) -> dict[str, object]:
    calibrated_cases = calibration["cases"]
    assert isinstance(calibrated_cases, dict)
    in_scope_results = [
        r
        for r in results
        if r.case.id in calibrated_cases
        and isinstance(calibrated_cases[r.case.id], dict)
        and is_in_scope_entry(calibrated_cases[r.case.id])
    ]
    valid_bug_ids = {
        case_id
        for case_id, entry in calibrated_cases.items()
        if isinstance(entry, dict) and entry.get("scope") == "valid-bug"
    }
    changed_ids = {
        r.case.id
        for r in in_scope_results
        if r.actual != calibrated_cases[r.case.id].get("base_verdict")
    }
    bug_rejected_ids = {
        r.case.id
        for r in in_scope_results
        if r.case.id in valid_bug_ids and r.actual == "REJECTED"
    }
    crash_ids = {r.case.id for r in in_scope_results if r.actual == "CRASH"}
    compile_ids = {r.case.id for r in in_scope_results if r.actual == "FAILED-TO-COMPILE"}
    unsoundrej_regression_ids = {
        r.case.id
        for r in in_scope_results
        if calibrated_cases[r.case.id].get("scope") == "excluded-unsoundrej" and r.actual == "ACCEPTED"
    }
    valid_preserve_changed_ids = {
        r.case.id
        for r in in_scope_results
        if calibrated_cases[r.case.id].get("scope") == "valid-preserve"
        and r.actual != calibrated_cases[r.case.id].get("base_verdict")
    }
    return {
        "in_scope": len(in_scope_results),
        "changed_ids": changed_ids,
        "valid_bug_ids": valid_bug_ids,
        "bug_rejected_ids": bug_rejected_ids,
        "changed_outside_bugset": changed_ids - valid_bug_ids,
        "crash_ids": crash_ids,
        "compile_ids": compile_ids,
        "unsoundrej_regression_ids": unsoundrej_regression_ids,
        "valid_preserve_changed_ids": valid_preserve_changed_ids,
        "exact_bug_change": changed_ids == valid_bug_ids and bug_rejected_ids == valid_bug_ids,
    }


def choose_next_failure(results: list[Result], calibration: dict[str, object]) -> Result | None:
    calibrated_cases = calibration["cases"]
    assert isinstance(calibrated_cases, dict)
    cell_counts = calibration_cell_counts(calibration)
    uncovered = [cell for cell in CELL_ORDER if cell_counts[cell] == 0]
    if uncovered:
        for cell in uncovered:
            for result in results:
                if result.case.cell == cell:
                    return result

    for result in results:
        entry = calibrated_cases.get(result.case.id)
        if isinstance(entry, dict) and entry.get("scope") == "valid-bug" and result.actual == "ACCEPTED":
            return result

    for result in results:
        entry = calibrated_cases.get(result.case.id)
        if isinstance(entry, dict) and is_in_scope_entry(entry) and result.actual != entry.get("base_verdict"):
            return result

    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Verus uninhabited CFG-pruning coverage cases.")
    parser.add_argument("--write-dir", default=DEFAULT_WRITE_DIR, help="directory for generated .rs files")
    parser.add_argument("--verus", default=DEFAULT_VERUS, help="path to prebuilt verus binary")
    parser.add_argument("--calibration", default=DEFAULT_CALIBRATION, help="path to saved calibration JSON")
    parser.add_argument("--calibrate", action="store_true", help="run base Verus once and save the calibration")
    parser.add_argument("--base-verus", help="path to base Verus binary for --calibrate")
    parser.add_argument("--candidate-verus", help="path to candidate Verus binary to grade against saved calibration")
    parser.add_argument("--timeout", type=float, default=10.0, help="timeout per case in seconds")
    parser.add_argument("--jobs", type=int, default=min(4, max(1, (os.cpu_count() or 2) // 2)))
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--keep-old", action="store_true", help="do not clear --write-dir before writing")
    args = parser.parse_args()

    if args.calibrate and not args.base_verus:
        parser.error("--calibrate requires --base-verus PATH")

    write_dir = Path(args.write_dir)
    if write_dir.exists() and not args.keep_old:
        shutil.rmtree(write_dir)
    write_dir.mkdir(parents=True, exist_ok=True)

    cases = generate_cases(write_dir)
    for case in cases:
        case.path.write_text(case.source)

    if args.verbose:
        print(f"generated {len(cases)} cases in {write_dir}")

    calibration_path = Path(args.calibration)
    if args.calibrate:
        if args.verbose:
            print(f"calibrating base {args.base_verus} with jobs={args.jobs}, timeout={args.timeout}s")
        base_results = run_cases(cases, args.base_verus, args.timeout, args.jobs, args.verbose, "base")
        calibration = build_calibration(base_results, args.base_verus)
        save_calibration(calibration, calibration_path)
        print_calibration_stats(calibration, calibration_path)

    if args.candidate_verus:
        calibration = load_calibration(calibration_path)
        counts = calibration_counts(calibration)
        if args.verbose:
            print(
                f"grading candidate {args.candidate_verus} against {calibration_path} "
                f"with jobs={args.jobs}, timeout={args.timeout}s"
            )
        candidate_results = run_cases(cases, args.candidate_verus, args.timeout, args.jobs, args.verbose, "candidate")
        calibrated_cases = calibration["cases"]
        assert isinstance(calibrated_cases, dict)
        mishandles = grade_candidate(candidate_results, calibration)
        change_summary = candidate_change_summary(candidate_results, calibration)
        unsoundrej_regressions = [
            r
            for r in candidate_results
            if r.case.id in change_summary["unsoundrej_regression_ids"]
        ]
        valid_bug_accepts = sum(
            1
            for r in candidate_results
            if calibrated_cases[r.case.id]["scope"] == "valid-bug" and r.actual == "ACCEPTED"
        )
        valid_preserve_rejects = sum(
            1
            for r in candidate_results
            if calibrated_cases[r.case.id]["scope"] == "valid-preserve" and r.actual == "REJECTED"
        )
        candidate_compile_failed = len(change_summary["compile_ids"])
        candidate_crashes = len(change_summary["crash_ids"])
        out_of_scope = len(candidate_results) - int(change_summary["in_scope"])
        changed = len(change_summary["changed_ids"])
        changed_outside_bugset = len(change_summary["changed_outside_bugset"])
        cell_counts = calibration_cell_counts(calibration)
        candidate_passes = (
            len(mishandles) == 0
            and candidate_compile_failed == 0
            and candidate_crashes == 0
            and len(unsoundrej_regressions) == 0
            and len(change_summary["valid_preserve_changed_ids"]) == 0
            and bool(change_summary["exact_bug_change"])
        )

        print(
            f"candidate summary: total={len(candidate_results)} "
            f"valid-bug={counts['valid-bug']} valid-preserve={counts['valid-preserve']} "
            f"in-scope={change_summary['in_scope']} out-of-scope={out_of_scope} "
            f"crash={candidate_crashes} "
            f"compile-excluded={candidate_compile_failed} "
            f"unsoundrej-regressions={len(unsoundrej_regressions)} "
            f"changed={changed} changed-outside-bugset={changed_outside_bugset} "
            f"cells={format_cell_counts(cell_counts)} "
            f"offdiag-covered={str(offdiag_covered(cell_counts)).lower()} "
            f"pass={str(candidate_passes).lower()} "
            f"mishandles={len(mishandles)} "
            f"valid-bug-still-accepted={valid_bug_accepts} "
            f"valid-preserve-rejected={valid_preserve_rejects}"
        )

        if mishandles:
            print("mishandles:")
            for r in mishandles:
                c = r.case
                entry = calibrated_cases[c.id]
                print(
                    f"  {c.id}: scope={entry['scope']} label={c.label} expected={c.expected} "
                    f"base={entry['base_verdict']} candidate={r.actual} "
                    f"type={c.type_case.id} producer={c.producer.id} pattern={c.pattern.id} path={c.path}"
                )

        if unsoundrej_regressions:
            print("unsoundrej-regressions:")
            for r in unsoundrej_regressions:
                c = r.case
                entry = calibrated_cases[c.id]
                print(
                    f"  {c.id}: scope={entry['scope']} label={c.label} expected={c.expected} "
                    f"base={entry['base_verdict']} candidate={r.actual} "
                    f"type={c.type_case.id} producer={c.producer.id} pattern={c.pattern.id} path={c.path}"
                )

        if not candidate_passes:
            next_result = choose_next_failure(candidate_results, calibration)
            if next_result is not None:
                c = next_result.case
                print(
                    f"NEXT: {c.id} family=({c.type_case.family},{c.producer.id}) "
                    f"cell=({c.inhab},{c.producer.erasure}) expected={c.expected} actual={next_result.actual}"
                )

        return 0 if candidate_passes else 1

    if args.calibrate:
        return 0

    if args.verbose:
        print(f"running {args.verus} with jobs={args.jobs}, timeout={args.timeout}s")

    results = run_cases(cases, args.verus, args.timeout, args.jobs, args.verbose, "case")
    total = len(results)
    sound = sum(1 for r in results if r.case.label == "SOUND")
    unsound = sum(1 for r in results if r.case.label == "UNSOUND")
    compile_excluded = sum(1 for r in results if r.actual == "FAILED-TO-COMPILE")
    mishandles = [r for r in results if is_mishandle(r)]

    print(
        f"summary: total={total} sound={sound} unsound={unsound} "
        f"compile-excluded={compile_excluded} mishandles={len(mishandles)}"
    )

    if mishandles:
        print("mishandles:")
        for r in mishandles:
            c = r.case
            print(
                f"  {c.id}: label={c.label} expected={c.expected} actual={r.actual} "
                f"type={c.type_case.id} producer={c.producer.id} pattern={c.pattern.id} path={c.path}"
            )

    return 1 if mishandles else 0


if __name__ == "__main__":
    sys.exit(main())
