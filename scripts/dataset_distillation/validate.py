#!/usr/bin/env python3
"""Validate seeds.jsonl: schema, non-empty turns, near-duplicate detection, balance.

Exits non-zero on any hard error; prints warnings for soft issues.

Usage:
  python validate.py
  python validate.py --src seeds.jsonl --min-per-category 8
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).parent
SRC = HERE / "seeds.jsonl"

VALID_FROM = {"system", "human", "gpt"}
REQUIRED_TURNS = ["system", "human", "gpt"]


def _norm(text: str) -> str:
    """Normalize for near-duplicate detection: lowercase, collapse whitespace,
    strip code blocks + punctuation so rewordings of the same prompt still match."""
    t = text.lower()
    t = re.sub(r"```.*?```", " ", t, flags=re.DOTALL)   # drop code blocks
    t = re.sub(r"[`*_>#\-\[\](){}]", " ", t)            # drop markdown symbols
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _hash(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", default=str(SRC))
    p.add_argument("--min-per-category", type=int, default=8,
                   help="warn if any category has fewer than this many examples")
    args = p.parse_args()

    src = Path(args.src)
    if not src.exists():
        print(f"ERROR: source not found: {src}", file=sys.stderr)
        return 2

    lines = [l for l in src.read_text(encoding="utf-8").splitlines() if l.strip()]
    if not lines:
        print("ERROR: source is empty", file=sys.stderr)
        return 2

    errors: list[str] = []
    warnings: list[str] = []

    by_category: Counter = Counter()
    prompts: dict[str, list[int]] = defaultdict(list)   # normalized prompt -> line idxs
    dup_count = 0

    for i, line in enumerate(lines, 1):
        try:
            row = json.loads(line)
        except json.JSONDecodeError as e:
            errors.append(f"line {i}: invalid JSON ({e})")
            continue

        cat = row.get("category")
        conv = row.get("conversations")
        if not isinstance(cat, str) or not cat:
            errors.append(f"line {i}: missing/empty 'category'")
        else:
            by_category[cat] += 1

        if not isinstance(conv, list) or len(conv) < 3:
            errors.append(f"line {i}: 'conversations' must have >=3 turns")
            continue

        seen_from: list[str] = []
        for t in conv:
            if not isinstance(t, dict) or "from" not in t or "value" not in t:
                errors.append(f"line {i}: turn missing 'from'/'value'")
                continue
            if t["from"] not in VALID_FROM:
                errors.append(f"line {i}: invalid 'from'={t['from']!r}")
            if not isinstance(t["value"], str) or not t["value"].strip():
                errors.append(f"line {i}: empty turn value (from={t['from']})")
            seen_from.append(t["from"])

        # order check: system, human, gpt
        if seen_from[:3] != REQUIRED_TURNS:
            errors.append(f"line {i}: turn order should be {REQUIRED_TURNS}, got {seen_from[:3]}")

        # near-duplicate detection on the prompt
        human_val = next((t["value"] for t in conv if t["from"] == "human"), "")
        n = _norm(human_val)
        prompts[n].append(i)
        if len(prompts[n]) > 1 and len(prompts[n]) == 2:  # report once per dup group
            dup_count += 1

    # balance warnings
    for cat, n in sorted(by_category.items()):
        if n < args.min_per_category:
            warnings.append(f"category '{cat}' has only {n} examples (< {args.min_per_category})")

    # duplicate report (list the groups)
    dup_groups = {k: v for k, v in prompts.items() if len(v) > 1}
    if dup_groups:
        warnings.append(f"{len(dup_groups)} near-duplicate prompt group(s) detected:")
        for n, idxs in dup_groups.items():
            preview = n[:70] + ("..." if len(n) > 70 else "")
            warnings.append(f"  lines {idxs}: {preview!r}")

    # ---- report ----
    print(f"Validated {len(lines)} rows from {src}")
    print(f"Categories ({len(by_category)}):")
    for cat, n in sorted(by_category.items()):
        print(f"  {cat:24} {n}")
    print(f"Duplicate prompt groups: {dup_count}")

    for w in warnings:
        print(f"WARN: {w}")

    if errors:
        print(f"\n{len(errors)} ERROR(S):", file=sys.stderr)
        for e in errors[:50]:
            print(f"  {e}", file=sys.stderr)
        if len(errors) > 50:
            print(f"  ... and {len(errors) - 50} more", file=sys.stderr)
        return 1

    print(f"\nOK: {len(lines)} examples valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
