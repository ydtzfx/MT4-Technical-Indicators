#!/usr/bin/env python3
"""Programmatic P0.5 verification for MT4-Technical-Indicators.

Commands:
  static       Scan repository invariants and P0 correctness rules.
  ci-gate      Validate locked MetaEditor production/probe reports + static report.
  runtime      Validate closed-bar persistence CSV and calculate a 95% upper bound.
  release-gate Combine CI and runtime evidence into the final >95% engineering gate.
  selftest     Run deterministic tests for the verifier itself.
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
import tempfile
from pathlib import Path
from statistics import NormalDist
from typing import Any

PRODUCTION_DIRS = ("BillWilliams", "Custom", "Oscillators", "Templates", "Trend", "Volume")
EXPECTED_PRODUCTION = 201
DEFAULT_CHANNELS = 23
DEFAULT_TRACKED_BARS = 8
DEFAULT_MIN_TRANSITIONS = 20
DEFAULT_MIN_CHECKS = DEFAULT_CHANNELS * DEFAULT_TRACKED_BARS * DEFAULT_MIN_TRANSITIONS
DEFAULT_CONFIDENCE = 0.95
DEFAULT_MAX_UPPER = 0.001

FUNC_RE = re.compile(r"\b(?:int|double|void|bool|string|datetime|long|color)\s+([A-Za-z_]\w*)\s*\([^;{}]*\)\s*\{")
LOOP_RE = re.compile(r"\bfor\s*\(\s*(?:(int)\s+)?([A-Za-z_]\w*)\s*=([^;]*);([^;]*);([^)]*)\)")
SIGNAL_BAR0_RE = re.compile(r"(?i)\b(?:signal|buy|sell|strong|arrow)\w*\s*\[\s*0\s*\]\s*=")


def scrub_source(text: str) -> str:
    """Replace comments and literals with spaces while preserving newlines/offsets."""
    pattern = re.compile(
        r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
        re.S,
    )

    def repl(match: re.Match[str]) -> str:
        s = match.group(0)
        return "".join("\n" if ch == "\n" else " " for ch in s)

    return pattern.sub(repl, text)


def find_matching_brace(text: str, open_pos: int) -> int:
    depth = 0
    for i in range(open_pos, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    return len(text)


def line_number(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def add_finding(findings: list[dict[str, Any]], path: Path, rule: str, line: int, detail: str) -> None:
    findings.append({"file": path.as_posix(), "rule": rule, "line": line, "detail": detail})


def scan_loops(path: Path, original: str, scrubbed: str, findings: list[dict[str, Any]]) -> None:
    for fm in FUNC_RE.finditer(scrubbed):
        name = fm.group(1)
        open_pos = scrubbed.find("{", fm.start())
        end = find_matching_brace(scrubbed, open_pos)
        body_start = open_pos + 1
        body = scrubbed[body_start:end - 1]

        for lm in LOOP_RE.finditer(body):
            declared = bool(lm.group(1))
            var = lm.group(2)
            cond = lm.group(4).strip()
            step = lm.group(5).strip()
            absolute = body_start + lm.start()
            line = line_number(original, absolute)

            if not re.search(rf"\b{re.escape(var)}\b", cond):
                add_finding(findings, path, "loop-control-mismatch", line, f"{name}(): {var} absent from condition: {cond}")
            if not re.search(rf"\b{re.escape(var)}\b", step):
                add_finding(findings, path, "loop-control-mismatch", line, f"{name}(): {var} absent from step: {step}")

            lead = re.match(rf"^{re.escape(var)}\s*(>=|<=|>|<)", cond)
            if lead:
                op = lead.group(1)
                if op == ">=" and ("++" in step):
                    add_finding(findings, path, "loop-direction", line, f"{name}(): descending condition with increment")
                if op == "<=" and ("--" in step):
                    add_finding(findings, path, "loop-direction", line, f"{name}(): ascending condition with decrement")

            if declared:
                prefix = body[:lm.start()]
                prior_decl = re.search(rf"\bint\s+[^;{{}}]*\b{re.escape(var)}\b[^;{{}}]*;", prefix)
                prior_for = re.search(rf"\bfor\s*\(\s*int\s+{re.escape(var)}\b", prefix)
                if prior_decl or prior_for:
                    add_finding(
                        findings,
                        path,
                        "duplicate-loop-declaration",
                        line,
                        f"{name}(): int {var} redeclared under verified non-strict MT4 compatibility mode",
                    )


def scan_file(path: Path, root: Path, findings: list[dict[str, Any]]) -> None:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    scrubbed = scrub_source(text)
    rel = path.relative_to(root)

    scan_loops(rel, text, scrubbed, findings)

    if "IndicatorCounted(" not in text:
        add_finding(findings, rel, "indicator-counted", 1, "IndicatorCounted() missing")
    if not re.search(r'#include\s+["<][^">]*Common\.mqh[">]', text):
        add_finding(findings, rel, "common-include", 1, "Common.mqh include missing")

    prop = re.search(r"#property\s+indicator_buffers\s+(\d+)", text)
    if prop:
        declared = int(prop.group(1))
        bound = len(re.findall(r"SetIndexBuffer\s*\(", text))
        if declared != bound:
            add_finding(findings, rel, "buffer-binding-count", line_number(text, prop.start()), f"property={declared}, SetIndexBuffer={bound}")

    for n, line in enumerate(scrubbed.splitlines(), 1):
        if SIGNAL_BAR0_RE.search(line) and "EMPTY_VALUE" not in line:
            add_finding(findings, rel, "bar0-signal-write", n, line.strip())


def targeted_checks(root: Path, findings: list[dict[str, Any]]) -> None:
    def text(p: str) -> str:
        return (root / p).read_text(encoding="utf-8-sig", errors="replace")

    signal = text("Include/SignalBase.mqh")
    if "buffer[0] = EMPTY_VALUE;" not in signal or "buffer[0] = signal;" in signal:
        add_finding(findings, Path("Include/SignalBase.mqh"), "strict-bar0-contract", 1, "STRICT bar[0] must be EMPTY_VALUE")

    price = text("Include/PriceData.mqh")
    block = re.search(r"double\s+GetVolumeSignal\s*\([^)]*\)\s*\{(.*?)\}", price, re.S)
    if not block or "iVolume(symbol, timeframe, safeShift)" not in block.group(1):
        add_finding(findings, Path("Include/PriceData.mqh"), "safe-volume-shift", 1, "GetVolumeSignal() must use safeShift")

    backtest = text("Custom/Backtest_Safe.mq4")
    if "for(int k=testBar-1;k>=0;k--)" in backtest or "for(int k=testBar-1;k>=i;k--)" not in backtest:
        add_finding(findings, Path("Custom/Backtest_Safe.mq4"), "backtest-lookahead", 1, "historical outcome scan must stop at decision bar i")

    mtf = text("Custom/MTF_RSI_Safe.mq4")
    if "CalcClosedRSI" not in mtf or "iBarShift(_Symbol,_Period,iTime(_Symbol,_Period,i))" in mtf:
        add_finding(findings, Path("Custom/MTF_RSI_Safe.mq4"), "mtf-time-alignment", 1, "MTF RSI must align each target timeframe independently to a closed bar")


def report_markdown(title: str, report: dict[str, Any]) -> str:
    lines = [f"# {title}", "", f"- Status: **{report.get('status', 'UNKNOWN')}**"]
    for key, value in report.items():
        if key in {"status", "findings", "failures"}:
            continue
        if isinstance(value, (str, int, float, bool)) or value is None:
            lines.append(f"- {key}: **{value}**")
    failures = report.get("failures") or []
    findings = report.get("findings") or []
    if failures:
        lines += ["", "## Failures"] + [f"- {x}" for x in failures]
    if findings:
        lines += ["", "## Findings"] + [
            f"- {x['file']}:{x['line']} [{x['rule']}] {x['detail']}" for x in findings
        ]
    return "\n".join(lines) + "\n"


def write_report(out: Path, stem: str, title: str, report: dict[str, Any]) -> None:
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{stem}.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (out / f"{stem}.md").write_text(report_markdown(title, report), encoding="utf-8")


def run_static(root: Path, out: Path) -> dict[str, Any]:
    files: list[Path] = []
    for directory in PRODUCTION_DIRS:
        files.extend((root / directory).rglob("*.mq4"))
    files = sorted(set(files))

    findings: list[dict[str, Any]] = []
    if len(files) != EXPECTED_PRODUCTION:
        findings.append({
            "file": ".",
            "rule": "production-count",
            "line": 1,
            "detail": f"expected {EXPECTED_PRODUCTION}, found {len(files)}",
        })

    for path in files:
        scan_file(path, root, findings)
    targeted_checks(root, findings)

    report = {
        "schema": 1,
        "status": "PASS" if not findings else "FAIL",
        "expected_count": EXPECTED_PRODUCTION,
        "discovered_count": len(files),
        "finding_count": len(findings),
        "findings": findings,
    }
    write_report(out, "static-report", "P0.5 Static Verification", report)
    return report


def find_report(path: Path, name: str) -> Path:
    if path.is_file():
        return path
    found = list(path.rglob(name))
    if len(found) != 1:
        raise ValueError(f"expected exactly one {name} under {path}, found {len(found)}: {found}")
    return found[0]


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def run_ci_gate(compile_path: Path, probe_path: Path, static_path: Path, lock_path: Path, out: Path) -> dict[str, Any]:
    compile_report = load_json(find_report(compile_path, "compile-report.json"))
    probe_report = load_json(find_report(probe_path, "compile-report.json"))
    static_report = load_json(find_report(static_path, "static-report.json"))
    lock = load_json(lock_path)

    failures: list[str] = []
    expected = {
        "expected_count": EXPECTED_PRODUCTION,
        "discovered_count": EXPECTED_PRODUCTION,
        "passed_count": EXPECTED_PRODUCTION,
        "failed_count": 0,
        "errors_total": 0,
        "parser_failures": 0,
    }
    for key, value in expected.items():
        if compile_report.get(key) != value:
            failures.append(f"compile {key}: expected {value}, got {compile_report.get(key)}")
    if compile_report.get("status") != "PASS":
        failures.append(f"compile status: {compile_report.get('status')}")

    if probe_report.get("status") != "PASS":
        failures.append(f"probe status: {probe_report.get('status')}")
    if probe_report.get("expected_count") != 1 or probe_report.get("passed_count") != 1:
        failures.append("probe did not compile 1/1")
    if probe_report.get("errors_total") != 0 or probe_report.get("parser_failures") != 0:
        failures.append("probe compiler errors/parser failures are non-zero")

    if static_report.get("status") != "PASS":
        failures.append(f"static verification failed with {static_report.get('finding_count')} findings")

    for label, report in (("compile", compile_report), ("probe", probe_report)):
        if report.get("compiler_image") != lock.get("mt4_image"):
            failures.append(f"{label} compiler image does not match lock")
        if report.get("wine_image") != lock.get("wine_image"):
            failures.append(f"{label} wine image does not match lock")
    if compile_report.get("compiler_sha256") != probe_report.get("compiler_sha256"):
        failures.append("MetaEditor SHA256 differs between production and probe jobs")

    report = {
        "schema": 1,
        "status": "PASS" if not failures else "FAIL",
        "production_passed": compile_report.get("passed_count"),
        "production_expected": EXPECTED_PRODUCTION,
        "compile_errors": compile_report.get("errors_total"),
        "compile_warnings": compile_report.get("warnings_total"),
        "static_findings": static_report.get("finding_count"),
        "probe_passed": probe_report.get("passed_count"),
        "compiler_sha256": compile_report.get("compiler_sha256"),
        "compiler_image": compile_report.get("compiler_image"),
        "failures": failures,
    }
    write_report(out, "ci-gate", "P0.5 CI Gate", report)
    return report


def upper_binomial_rate(violations: int, checks: int, confidence: float) -> float:
    if checks <= 0:
        return 1.0
    alpha = 1.0 - confidence
    if violations == 0:
        return 1.0 - alpha ** (1.0 / checks)

    p = violations / checks
    z = NormalDist().inv_cdf(confidence)
    denom = 1.0 + z * z / checks
    centre = p + z * z / (2.0 * checks)
    margin = z * math.sqrt((p * (1.0 - p) / checks) + (z * z / (4.0 * checks * checks)))
    return min(1.0, (centre + margin) / denom)


def read_runtime_summary(csv_path: Path, channels: int, tracked_bars: int) -> tuple[int, int, int]:
    rows = list(csv.DictReader(csv_path.open("r", encoding="utf-8-sig", newline="")))
    summaries = [row for row in rows if (row.get("kind") or "").strip() == "SUMMARY"]
    if not summaries:
        raise ValueError("runtime CSV has no SUMMARY row")
    row = summaries[-1]
    checks = int(float(row.get("checks") or 0))
    violations = int(float(row.get("violations") or 0))
    raw_transitions = row.get("transitions")
    if raw_transitions not in (None, ""):
        transitions = int(float(raw_transitions))
    else:
        per_transition = channels * tracked_bars
        transitions = checks // per_transition if per_transition else 0
    return checks, violations, transitions


def run_runtime(
    csv_path: Path,
    out: Path,
    min_checks: int,
    min_transitions: int,
    confidence: float,
    max_upper: float,
    channels: int,
    tracked_bars: int,
) -> dict[str, Any]:
    failures: list[str] = []
    try:
        checks, violations, transitions = read_runtime_summary(csv_path, channels, tracked_bars)
    except Exception as exc:
        report = {"schema": 1, "status": "FAIL", "failures": [str(exc)]}
        write_report(out, "runtime-report", "P0.5 Runtime No-Repaint", report)
        return report

    upper = upper_binomial_rate(violations, checks, confidence)
    if checks < min_checks:
        failures.append(f"checks {checks} < required {min_checks}")
    if transitions < min_transitions:
        failures.append(f"transitions {transitions} < required {min_transitions}")
    if violations != 0:
        failures.append(f"repaint violations must be 0, got {violations}")
    if upper > max_upper:
        failures.append(f"{confidence:.1%} violation-rate upper bound {upper:.6%} > allowed {max_upper:.4%}")

    report = {
        "schema": 1,
        "status": "PASS" if not failures else "FAIL",
        "checks": checks,
        "violations": violations,
        "transitions": transitions,
        "channels": channels,
        "tracked_bars": tracked_bars,
        "confidence": confidence,
        "violation_rate_upper_bound": upper,
        "max_allowed_upper_bound": max_upper,
        "minimum_checks": min_checks,
        "minimum_transitions": min_transitions,
        "failures": failures,
    }
    write_report(out, "runtime-report", "P0.5 Runtime No-Repaint", report)
    return report


def run_release_gate(ci_path: Path, runtime_path: Path, out: Path) -> dict[str, Any]:
    ci = load_json(find_report(ci_path, "ci-gate.json"))
    runtime = load_json(find_report(runtime_path, "runtime-report.json"))
    failures: list[str] = []
    if ci.get("status") != "PASS":
        failures.append("CI gate is not PASS")
    if runtime.get("status") != "PASS":
        failures.append("runtime no-repaint gate is not PASS")
    if float(runtime.get("confidence") or 0.0) < DEFAULT_CONFIDENCE:
        failures.append("runtime confidence level is below 95%")
    if float(runtime.get("violation_rate_upper_bound") or 1.0) > DEFAULT_MAX_UPPER:
        failures.append("runtime 95% violation-rate upper bound exceeds 0.1%")

    report = {
        "schema": 1,
        "status": "PASS" if not failures else "FAIL",
        "engineering_confidence_target": ">=95%",
        "ci_status": ci.get("status"),
        "runtime_status": runtime.get("status"),
        "runtime_confidence": runtime.get("confidence"),
        "runtime_violation_rate_upper_bound": runtime.get("violation_rate_upper_bound"),
        "failures": failures,
    }
    write_report(out, "release-gate", "P0.5 Release Gate", report)
    return report


def selftest() -> bool:
    assert upper_binomial_rate(0, DEFAULT_MIN_CHECKS, 0.95) < DEFAULT_MAX_UPPER
    assert upper_binomial_rate(1, DEFAULT_MIN_CHECKS, 0.95) > 0.0

    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / "runtime.csv"
        p.write_text(
            "kind,channel,bar_time,before,after,checks,violations,transitions\n"
            f"SUMMARY,,,,,{DEFAULT_MIN_CHECKS},0,{DEFAULT_MIN_TRANSITIONS}\n",
            encoding="utf-8",
        )
        checks, violations, transitions = read_runtime_summary(p, DEFAULT_CHANNELS, DEFAULT_TRACKED_BARS)
        assert checks == DEFAULT_MIN_CHECKS
        assert violations == 0
        assert transitions == DEFAULT_MIN_TRANSITIONS

    broken = "int start(){ int j; for(int j=0;j<5;j++){} return(0); }"
    scrubbed = scrub_source(broken)
    findings: list[dict[str, Any]] = []
    scan_loops(Path("x.mq4"), broken, scrubbed, findings)
    assert any(x["rule"] == "duplicate-loop-declaration" for x in findings)
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("static")
    p.add_argument("--root", type=Path, default=Path("."))
    p.add_argument("--out", type=Path, required=True)

    p = sub.add_parser("ci-gate")
    p.add_argument("--compile", type=Path, required=True)
    p.add_argument("--probe", type=Path, required=True)
    p.add_argument("--static", type=Path, required=True)
    p.add_argument("--lock", type=Path, default=Path("Tools/ci/mt4-compiler.lock.json"))
    p.add_argument("--out", type=Path, required=True)

    p = sub.add_parser("runtime")
    p.add_argument("--csv", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)
    p.add_argument("--min-checks", type=int, default=DEFAULT_MIN_CHECKS)
    p.add_argument("--min-transitions", type=int, default=DEFAULT_MIN_TRANSITIONS)
    p.add_argument("--confidence", type=float, default=DEFAULT_CONFIDENCE)
    p.add_argument("--max-upper", type=float, default=DEFAULT_MAX_UPPER)
    p.add_argument("--channels", type=int, default=DEFAULT_CHANNELS)
    p.add_argument("--tracked-bars", type=int, default=DEFAULT_TRACKED_BARS)

    p = sub.add_parser("release-gate")
    p.add_argument("--ci", type=Path, required=True)
    p.add_argument("--runtime", type=Path, required=True)
    p.add_argument("--out", type=Path, required=True)

    sub.add_parser("selftest")

    args = parser.parse_args()

    if args.command == "selftest":
        selftest()
        print("P0.5 verifier selftest: PASS")
        return 0
    if args.command == "static":
        report = run_static(args.root.resolve(), args.out)
    elif args.command == "ci-gate":
        report = run_ci_gate(args.compile, args.probe, args.static, args.lock, args.out)
    elif args.command == "runtime":
        report = run_runtime(
            args.csv, args.out, args.min_checks, args.min_transitions,
            args.confidence, args.max_upper, args.channels, args.tracked_bars,
        )
    else:
        report = run_release_gate(args.ci, args.runtime, args.out)

    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report.get("status") == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
