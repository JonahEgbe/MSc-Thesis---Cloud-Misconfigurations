#!/usr/bin/env python3
"""
Aggregate scan results from Checkov, tfsec, Terrascan, and Conftest
for a single scenario directory.

Usage:
    python3 scripts/aggregate_results.py test-suite/storage/STO-MISC-001-s3-public-unencrypted
"""

import json
import re
import sys
from pathlib import Path

# --- Helpers --------------------------------------------------------------

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")

def strip_ansi(s: str) -> str:
    """Remove ANSI colour codes from tool output."""
    return ANSI_RE.sub("", s)


# --- Per-tool parsers ------------------------------------------------------

def parse_checkov(output: str) -> dict:
    """Parse Checkov text output."""
    out = strip_ansi(output)

    failed_match = re.search(r"Failed checks:\s*(\d+)", out)
    failed = int(failed_match.group(1)) if failed_match else 0

    # Count individual failed resources
    high_critical = len(re.findall(r"FAILED for resource", out))

    return {
        "tool": "checkov",
        "total_failures": failed,
        "high_critical": high_critical,
        "detected": failed > 0,
    }


def parse_tfsec(output: str) -> dict:
    """
    Parse tfsec output.

    More robust to colour codes and minor formatting changes:
    we count 'Result #n HIGH/MEDIUM/CRITICAL' lines instead of
    relying on the summary table.
    """
    out = strip_ansi(output)

    critical = len(re.findall(r"Result #\d+\s+CRITICAL", out))
    high = len(re.findall(r"Result #\d+\s+HIGH", out))
    medium = len(re.findall(r"Result #\d+\s+MEDIUM", out))

    return {
        "tool": "tfsec",
        "critical": critical,
        "high": high,
        "medium": medium,
        "detected": (critical + high + medium) > 0,
    }


def parse_terrascan(output: str) -> dict:
    """Parse Terrascan summary text output."""
    out = strip_ansi(output)

    violated_match = re.search(r"Violated Policies\s*:\s*(\d+)", out, re.IGNORECASE)
    high_match = re.search(r"High\s*:\s*(\d+)", out, re.IGNORECASE)
    medium_match = re.search(r"Medium\s*:\s*(\d+)", out, re.IGNORECASE)
    low_match = re.search(r"Low\s*:\s*(\d+)", out, re.IGNORECASE)

    violated = int(violated_match.group(1)) if violated_match else 0
    high = int(high_match.group(1)) if high_match else 0
    medium = int(medium_match.group(1)) if medium_match else 0
    low = int(low_match.group(1)) if low_match else 0

    return {
        "tool": "terrascan",
        "total_violations": violated,
        "high": high,
        "medium": medium,
        "low": low,
        "detected": violated > 0,
    }


def parse_conftest(output: str) -> dict:
    """
    Parse Conftest output.

    Each 'FAIL -' line is a violation. We strip ANSI first
    to avoid colour code noise.
    """
    out = strip_ansi(output)
    failures = len(re.findall(r"\bFAIL\s*-", out))

    return {
        "tool": "conftest",
        "failures": failures,
        "detected": failures > 0,
    }


# --- Aggregator ------------------------------------------------------------

def aggregate_scenario_results(scenario_dir: Path) -> dict:
    """Aggregate all tool results for a given scenario directory."""
    scenario_name = scenario_dir.name
    log_dir = scenario_dir / "scan_logs"

    def read(path: Path) -> str:
        if not path.exists():
            raise FileNotFoundError(path)
        return path.read_text(errors="ignore")

    checkov_output = read(log_dir / f"checkov_{scenario_name}.txt")
    tfsec_output = read(log_dir / f"tfsec_{scenario_name}.txt")
    terrascan_output = read(log_dir / f"terrascan_{scenario_name}.txt")
    conftest_output = read(log_dir / f"conftest_{scenario_name}.txt")

    results = {
        "scenario_id": scenario_name,
        "checkov": parse_checkov(checkov_output),
        "tfsec": parse_tfsec(tfsec_output),
        "terrascan": parse_terrascan(terrascan_output),
        "conftest": parse_conftest(conftest_output),
    }

    results["combined_detection"] = (
        results["checkov"]["detected"]
        or results["tfsec"]["detected"]
        or results["terrascan"]["detected"]
        or results["conftest"]["detected"]
    )

    return results


# --- CLI entrypoint --------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: aggregate_results.py <scenario-dir>", file=sys.stderr)
        sys.exit(1)

    scenario_dir = Path(sys.argv[1]).resolve()
    if not scenario_dir.is_dir():
        print(f"Not a directory: {scenario_dir}", file=sys.stderr)
        sys.exit(1)

    aggregated = aggregate_scenario_results(scenario_dir)
    print(json.dumps(aggregated, indent=2))
