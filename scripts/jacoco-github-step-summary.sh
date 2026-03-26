#!/usr/bin/env bash
# Append JaCoCo coverage and Surefire totals to GitHub Actions job summary (Markdown).
# Run from repository root after Maven (expects **/target/site/jacoco/jacoco.xml and surefire-reports).

set -uo pipefail

SUMMARY="${GITHUB_STEP_SUMMARY:-}"
if [[ -z "${SUMMARY}" ]]; then
  echo "GITHUB_STEP_SUMMARY is not set; skipping job summary."
  exit 0
fi

python3 <<'PY'
import glob
import os
import sys
import xml.etree.ElementTree as ET

summary_path = os.environ.get("GITHUB_STEP_SUMMARY", "")
if not summary_path:
    sys.exit(0)


def module_target_key(path: str) -> str:
    norm = path.replace("\\", "/")
    parts = norm.split("/")
    if "target" in parts:
        i = parts.index("target")
        return "/".join(parts[: i + 1])
    return norm


def module_label(path: str) -> str:
    """Maven module path (parent of target/), for display."""
    norm = path.replace("\\", "/")
    parts = norm.split("/")
    if "target" in parts:
        i = parts.index("target")
        if i > 0:
            return "/".join(parts[:i])
    return norm


def pick_jacoco_files():
    merged = glob.glob("**/target/site/jacoco/jacoco.xml", recursive=True)
    unit_only = glob.glob(
        "**/target/site/jacoco-unit-test-coverage-report/jacoco.xml", recursive=True
    )
    by_mod = {}
    for p in merged:
        by_mod[module_target_key(p)] = p
    for p in unit_only:
        k = module_target_key(p)
        if k not in by_mod:
            by_mod[k] = p
    return sorted(by_mod.values())


lines = []
lines.append("## Java test & coverage summary")
lines.append("")
lines.append("| Scope | Covered | Missed | Coverage |")
lines.append("|-------|--------:|-------:|---------:|")

jacoco_files = pick_jacoco_files()
if not jacoco_files:
    lines.append("| *(no JaCoCo XML found)* | — | — | — |")
else:
    total_cov = total_mis = 0
    for path in jacoco_files:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        inst = None
        # Only totals on <report> (not nested class counters)
        for c in root.findall("counter"):
            if c.get("type") == "INSTRUCTION":
                inst = (int(c.get("covered", 0)), int(c.get("missed", 0)))
                break
        if not inst:
            continue
        cov, mis = inst
        total = cov + mis
        pct = (100.0 * cov / total) if total else 0.0
        total_cov += cov
        total_mis += mis
        name_attr = (root.get("name") or "").strip()
        if name_attr and ":" in name_attr:
            short = name_attr.split(":")[-1]
        else:
            short = module_label(path)
        lines.append(f"| `{short}` | {cov:,} | {mis:,} | {pct:.1f}% |")

    grand = total_cov + total_mis
    gpct = (100.0 * total_cov / grand) if grand else 0.0
    lines.append(f"| **All modules (instructions)** | **{total_cov:,}** | **{total_mis:,}** | **{gpct:.1f}%** |")

lines.append("")
lines.append("### Surefire (unit tests)")
lines.append("")

surefire_xml = sorted(glob.glob("**/target/surefire-reports/TEST-*.xml", recursive=True))
if not surefire_xml:
    lines.append("*No Surefire XML reports found.*")
else:
    t = f = e = s = 0
    for path in surefire_xml:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        if root.tag == "testsuite":
            t += int(root.get("tests", 0))
            f += int(root.get("failures", 0))
            e += int(root.get("errors", 0))
            s += int(root.get("skipped", 0))
        else:
            for suite in root.iter("testsuite"):
                t += int(suite.get("tests", 0))
                f += int(suite.get("failures", 0))
                e += int(suite.get("errors", 0))
                s += int(suite.get("skipped", 0))
    lines.append(f"- **Tests:** {t}")
    lines.append(f"- **Failures:** {f}")
    lines.append(f"- **Errors:** {e}")
    lines.append(f"- **Skipped:** {s}")

lines.append("")
lines.append(
    "*Full HTML reports are attached as workflow artifacts (`java-reports-*`) when upload is enabled.*"
)

with open(summary_path, "a", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print("Wrote Java coverage/test summary to GITHUB_STEP_SUMMARY", file=sys.stderr)
PY
status=$?
if [[ "${status}" -ne 0 ]]; then
  echo "::warning::Could not write Java job summary (JaCoCo/Surefire parse failed)"
fi
exit 0
