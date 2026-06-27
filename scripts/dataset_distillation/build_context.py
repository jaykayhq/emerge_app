#!/usr/bin/env python3
"""Generate runtime agent-context files (CLAUDE.md, .cursorrules, ...) from
SYSTEM_PROMPT.md, so every coding agent works from one source of truth.

Why this exists alongside the fine-tuning dataset:
  - The fine-tuning dataset (seeds.jsonl) trains a custom MODEL'S weights.
  - These context files shape any OFF-THE-SHELF agent (Claude Code, Cursor,
    Windsurf, Copilot) at RUNTIME — the model reads them each session.
  They are derived from the same SYSTEM_PROMPT.md so they never drift.

Output files (written to the repo root, two levels up from this script):
  CLAUDE.md                         <- Claude Code reads this automatically
  .cursorrules                      <- Cursor
  .windsurfrules                    <- Windsurf
  AGENTS.md                         <- generic fallback (some agents/OpenAI)
  .github/copilot-instructions.md   <- GitHub Copilot

Usage:
  python build_context.py            # write all targets
  python build_context.py --dry-run  # print what would be written, write nothing
"""

from __future__ import annotations

import argparse
from pathlib import Path

HERE = Path(__file__).parent
REPO_ROOT = HERE.parent.parent
SOURCE = HERE / "SYSTEM_PROMPT.md"

# (relative path from repo root, tool-specific header)
TARGETS: list[tuple[str, str]] = [
    ("CLAUDE.md", "claude"),
    (".cursorrules", "cursor"),
    (".windsurfrules", "windsurf"),
    ("AGENTS.md", "agents"),
    (".github/copilot-instructions.md", "copilot"),
]

HEADERS: dict[str, str] = {
    "claude": (
        "# Emerge App — Guide for Claude Code\n\n"
        "Claude Code reads this file at the start of every session. Follow these "
        "project-specific rules for all work on `emerge_app`. They override "
        "generic Flutter/Dart advice when they conflict.\n"
    ),
    "cursor": (
        "# Emerge App — Cursor Rules\n\n"
        "Project-specific rules for working on `emerge_app`. Apply to every "
        "edit. They override generic Flutter/Dart advice when they conflict.\n"
    ),
    "windsurf": (
        "# Emerge App — Windsurf Rules\n\n"
        "Project-specific rules for working on `emerge_app`. Apply to every "
        "edit. They override generic Flutter/Dart advice when they conflict.\n"
    ),
    "agents": (
        "# Emerge App — Agent Guide\n\n"
        "Coding agents working on this repo should read and follow these "
        "project-specific rules. They override generic Flutter/Dart advice "
        "when they conflict.\n"
    ),
    "copilot": (
        "# Emerge App — Copilot Instructions\n\n"
        "Project-specific rules for GitHub Copilot when working on `emerge_app`. "
        "They override generic Flutter/Dart advice when they conflict.\n"
    ),
}

FOOTER = (
    "\n\n---\n\n"
    "## Where to look\n\n"
    "- Skill rule details: `.agents/skills/` (especially `test-driven-development`, "
    "`systematic-debugging`, `verification-before-completion`).\n"
    "- Design decisions: `docs/superpowers/specs/` and `docs/superpowers/plans/`.\n"
    "- A fine-tuning dataset capturing these rules as examples lives at "
    "`scripts/dataset_distillation/` (regenerate with `python build_seeds.py`).\n"
)


def _rules_body(source_text: str) -> str:
    """Strip the meta header from SYSTEM_PROMPT.md.

    The file's real instructions begin after the first '---' separator
    (everything above it is meta about the dataset)."""
    parts = source_text.split("\n---\n", 1)
    body = parts[1] if len(parts) == 2 else source_text
    return body.strip()


def build(target: str, body: str) -> str:
    return f"{HEADERS[target]}\n{body}{FOOTER}"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--dry-run", action="store_true",
                   help="print targets without writing files")
    args = p.parse_args()

    if not SOURCE.exists():
        raise SystemExit(f"source not found: {SOURCE}")
    body = _rules_body(SOURCE.read_text(encoding="utf-8"))

    for rel, tool in TARGETS:
        content = build(tool, body)
        path = REPO_ROOT / rel
        if args.dry_run:
            print(f"=== WOULD WRITE {path} ({len(content)} chars) ===")
            print(content[:400] + "...\n")
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print(f"wrote {path}  ({len(content)} chars)")


if __name__ == "__main__":
    main()
