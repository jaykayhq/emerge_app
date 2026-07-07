#!/usr/bin/env python3
"""
Task Observer — Append-only observation logger.

Records observations (corrections, rework, friction, patterns, successes)
to a JSONL file for later synthesis. Never overwrites; always appends.

Usage:
    python record_observation.py observe  --session-id <id> --type <type> \
        --description "<text>" --evidence "<text>" --severity <1-5>

    python record_observation.py session_start --session-id <id> --task "<text>"
    python record_observation.py session_end   --session-id <id>
"""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

DATA_DIR = (
    Path(__file__).resolve().parent.parent
    / "data"
)
DATA_DIR.mkdir(exist_ok=True)

OBSERVATIONS_FILE = DATA_DIR / "observations.jsonl"
SESSIONS_FILE = DATA_DIR / "sessions.jsonl"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def observation(
    session_id: str,
    obs_type: str,
    description: str,
    evidence: str,
    severity: int,
    feature: str | None = None,
    file_path: str | None = None,
    agent: str = "claude-code",
) -> dict:
    """Build an observation record."""
    return {
        "id": f"obs_{uuid.uuid4().hex[:12]}",
        "sessionId": session_id,
        "userId": "developer",
        "observationType": obs_type,
        "description": description,
        "evidence": evidence,
        "severity": max(1, min(5, severity)),
        "isResolved": False,
        "createdAt": _utc_now(),
        "context": {
            **({"feature": feature} if feature else {}),
            **({"file": file_path} if file_path else {}),
            "agent": agent,
        },
    }


def session_event(event_type: str, session_id: str, task: str | None = None) -> dict:
    """Build a session start/end record."""
    return {
        "id": f"sess_{uuid.uuid4().hex[:12]}",
        "sessionId": session_id,
        "eventType": event_type,
        "task": task,
        "createdAt": _utc_now(),
    }


def append_jsonl(path: Path, record: dict) -> None:
    """Append a single JSON record as a newline-terminated JSON line."""
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def handle_observe(args: argparse.Namespace) -> None:
    record = observation(
        session_id=args.session_id,
        obs_type=args.type,
        description=args.description,
        evidence=args.evidence,
        severity=args.severity,
        feature=getattr(args, "feature", None),
        file_path=getattr(args, "file", None),
    )
    append_jsonl(OBSERVATIONS_FILE, record)
    print(f"Recorded: {record['id']} ({args.type}, severity {args.severity})")


def handle_session_start(args: argparse.Namespace) -> None:
    record = session_event("session_start", args.session_id, args.task)
    append_jsonl(SESSIONS_FILE, record)
    print(f"Session started: {args.session_id}")


def handle_session_end(args: argparse.Namespace) -> None:
    record = session_event("session_end", args.session_id)
    append_jsonl(SESSIONS_FILE, record)
    print(f"Session ended: {args.session_id}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Task Observer — observation logger",
    )
    sub = parser.add_subparsers(dest="command")

    # observe
    p_obs = sub.add_parser("observe", help="Record an observation")
    p_obs.add_argument("--session-id", required=True)
    p_obs.add_argument("--type", required=True, choices=[
        "correction", "rework", "unmet_need", "friction", "pattern", "success",
    ])
    p_obs.add_argument("--description", required=True)
    p_obs.add_argument("--evidence", default="")
    p_obs.add_argument("--severity", type=int, default=3, choices=range(1, 6))
    p_obs.add_argument("--feature", default=None)
    p_obs.add_argument("--file", default=None)

    # session_start
    p_start = sub.add_parser("session_start", help="Mark session start")
    p_start.add_argument("--session-id", required=True)
    p_start.add_argument("--task", default="")

    # session_end
    p_end = sub.add_parser("session_end", help="Mark session end")
    p_end.add_argument("--session-id", required=True)

    args = parser.parse_args()

    match args.command:
        case "observe":
            handle_observe(args)
        case "session_start":
            handle_session_start(args)
        case "session_end":
            handle_session_end(args)
        case _:
            parser.print_help()
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
