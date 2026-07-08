#!/usr/bin/env python3
"""
Task Observer — Synthesize observations into recommendations.

Reads observations.jsonl and produces improvement recommendations.
No files are modified. Output is a structured report for review.

Usage:
    python synthesize.py                             # synthesize all unresolved
    python synthesize.py --session-id <id>            # synthesize one session
    python synthesize.py --review-mode                # show pending recommendations
    python synthesize.py --output recommendations.json # write JSONL file
"""

import argparse
import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

DATA_DIR = (
    Path(__file__).resolve().parent.parent
    / "data"
)
OBSERVATIONS_FILE = DATA_DIR / "observations.jsonl"
SESSIONS_FILE = DATA_DIR / "sessions.jsonl"
RECOMMENDATIONS_FILE = DATA_DIR / "recommendations.jsonl"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    lines = path.read_text(encoding="utf-8").strip().splitlines()
    return [json.loads(line) for line in lines if line.strip()]


def priority_from_severity(avg_severity: float) -> str:
    if avg_severity >= 4.0:
        return "high"
    if avg_severity >= 2.5:
        return "medium"
    return "low"


def synthesize(session_id: str | None = None) -> list[dict]:
    observations = load_jsonl(OBSERVATIONS_FILE)
    sessions = load_jsonl(SESSIONS_FILE)

    if session_id:
        observations = [o for o in observations if o["sessionId"] == session_id]

    unresolved = [o for o in observations if not o.get("isResolved", False)]
    if not unresolved:
        return []

    type_counts: Counter = Counter()
    type_severity: dict[str, list[int]] = defaultdict(list)
    type_descriptions: dict[str, list[str]] = defaultdict(list)

    for obs in unresolved:
        t = obs["observationType"]
        type_counts[t] += 1
        type_severity[t].append(obs.get("severity", 3))
        desc = obs.get("description", "")
        if desc:
            type_descriptions[t].append(desc)

    recommendations: list[dict] = []

    # Generate one recommendation per observation type that repeats >= 2 times
    # or a single high-severity observation
    for obs_type, count in type_counts.items():
        severities = type_severity[obs_type]
        avg_severity = sum(severities) / len(severities)
        descs = type_descriptions[obs_type]
        obs_ids = [o["id"] for o in unresolved if o["observationType"] == obs_type]

        if count >= 2 or any(s >= 4 for s in severities):
            suggestion = _build_suggestion(obs_type, descs, count, avg_severity)
            recommendations.append({
                "id": f"rec_{abs(hash(suggestion)) % 10**12:012d}",
                "observationIds": obs_ids,
                "userId": "developer",
                "suggestion": suggestion,
                "rationale": f"{count} {obs_type}(s) observed, avg severity {avg_severity:.1f}",
                "basedOnPatterns": obs_ids,
                "priority": priority_from_severity(avg_severity),
                "createdAt": _utc_now(),
                "isResolved": False,
                "reviewStatus": "pending",
            })

    return recommendations


def _build_suggestion(obs_type: str, descriptions: list[str], count: int, avg_severity: float) -> str:
    """Generate a human-readable suggestion from aggregated observations."""
    examples = descriptions[:3]
    example_text = "; ".join(f'"{d[:80]}"' for d in examples)

    templates = {
        "correction": (
            f"Repeated correction ({count}x): {example_text}. "
            "Consider adding a SKILL.md rule or AGENTS.md gotcha to prevent recurrence."
        ),
        "rework": (
            f"Rework detected {count} times (avg severity {avg_severity:.1f}): {example_text}. "
            "Review the chosen approach before writing code to reduce rework."
        ),
        "unmet_need": (
            f"Unmet need surfaced {count}x: {example_text}. "
            "Clarify requirements with the developer before implementing."
        ),
        "friction": (
            f"Friction point appeared {count}x: {example_text}. "
            "Investigate root cause and consider a fix or workaround."
        ),
        "pattern": (
            f"Recurring pattern ({count}x): {example_text}. "
            "Investigate whether this is a systemic issue worth addressing."
        ),
        "success": (
            f"Successful pattern ({count}x): {example_text}. "
            "Document and replicate this approach."
        ),
    }

    return templates.get(
        obs_type,
        f"Observation of type '{obs_type}' occurred {count}x: {example_text}. Review for improvement.",
    )


def print_report(recommendations: list[dict]) -> None:
    if not recommendations:
        print("No recommendations at this time.")
        return

    by_priority = defaultdict(list)
    for rec in recommendations:
        by_priority[rec["priority"]].append(rec)

    print("## Task Observer — Session Summary\n")

    # Count observations by type
    observations = load_jsonl(OBSERVATIONS_FILE)
    unresolved = [o for o in observations if not o.get("isResolved", False)]
    type_counts = Counter(o["observationType"] for o in unresolved)

    if type_counts:
        print("### Raw Observations by Type\n")
        for otype, count in sorted(type_counts.items()):
            print(f"  {otype}: {count}")
        print()

    # Recommendations
    priority_order = ["high", "medium", "low"]
    rec_count = 0
    for priority in priority_order:
        recs = by_priority.get(priority, [])
        if not recs:
            continue
        label = priority.upper()
        print(f"### Recommendations [{label}]\n")
        for rec in recs:
            rec_count += 1
            print(f"{rec_count}. **{rec['suggestion']}**")
            print(f"   Rationale: {rec['rationale']}")
            print(f"   Based on: {len(rec.get('basedOnPatterns', []))} observations")
            print()

    print("---\nNo changes were auto-applied.\nReview each recommendation and decide whether to act on it.")


def append_recommendations(recommendations: list[dict]) -> None:
    """Append new recommendations to the recommendations file."""
    existing_ids = {r["id"] for r in load_jsonl(RECOMMENDATIONS_FILE)}
    new_recs = [r for r in recommendations if r["id"] not in existing_ids]
    for rec in new_recs:
        RECOMMENDATIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(RECOMMENDATIONS_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    if new_recs:
        print(f"Appended {len(new_recs)} new recommendation(s) to {RECOMMENDATIONS_FILE}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Task Observer — synthesize observations into recommendations",
    )
    parser.add_argument("--session-id", default=None, help="Limit to a specific session")
    parser.add_argument("--review-mode", action="store_true", help="Show pending recommendations")
    parser.add_argument("--output", default=None, help="Write JSONL to this file")
    args = parser.parse_args()

    if args.review_mode:
        recs = load_jsonl(RECOMMENDATIONS_FILE)
        pending = [r for r in recs if not r.get("isResolved")]
        print_report(pending)
        return 0

    recommendations = synthesize(session_id=args.session_id)

    if args.output:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            for rec in recommendations:
                f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        print(f"Wrote {len(recommendations)} recommendation(s) to {out_path}")

    append_recommendations(recommendations)
    print_report(recommendations)

    return 0


if __name__ == "__main__":
    sys.exit(main())
