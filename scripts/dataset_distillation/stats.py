#!/usr/bin/env python3
"""Print dataset stats: per-category counts, token estimates, system-prompt share.

Token estimate uses a cheap heuristic (chars/4); for exact counts, point a real
tokenizer at the JSONL. The point is relative magnitude and balance, not precision.

Usage:
  python stats.py
  python stats.py --src seeds.jsonl
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).parent
SRC = HERE / "seeds.jsonl"


def _est_tokens(text: str) -> int:
    """Rough token estimate (~4 chars/token for English+code)."""
    return max(1, len(text) // 4)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--src", default=str(SRC))
    args = p.parse_args()

    src = Path(args.src)
    if not src.exists():
        raise SystemExit(f"source not found: {src} (run build_seeds.py first)")

    rows = [json.loads(l) for l in src.read_text(encoding="utf-8").splitlines() if l.strip()]

    by_cat: Counter = Counter()
    tokens_by_cat: defaultdict = defaultdict(int)
    total_user_toks = 0
    total_assistant_toks = 0
    total_system_toks = 0
    system_prompt_len = 0

    for r in rows:
        cat = r["category"]
        by_cat[cat] += 1
        for t in r["conversations"]:
            toks = _est_tokens(t["value"])
            if t["from"] == "system":
                total_system_toks += toks
                system_prompt_len = max(system_prompt_len, len(t["value"]))
            elif t["from"] == "human":
                total_user_toks += toks
                tokens_by_cat[cat] += toks
            elif t["from"] == "gpt":
                total_assistant_toks += toks
                tokens_by_cat[cat] += toks

    total_examples = sum(by_cat.values())
    max_cat = max(by_cat.values())
    min_cat = min(by_cat.values())

    print(f"Dataset: {src}")
    print(f"Examples: {total_examples}")
    print(f"Categories: {len(by_cat)}")
    print(f"Balance: min={min_cat} max={max_cat} (ratio {max_cat / min_cat:.1f}:1)")
    print()
    print(f"{'category':24} {'count':>6} {'est tokens':>12}")
    print("-" * 46)
    for cat in sorted(by_cat):
        print(f"{cat:24} {by_cat[cat]:>6} {tokens_by_cat[cat]:>12}")
    print("-" * 46)
    total_toks = total_user_toks + total_assistant_toks + total_system_toks
    print(f"{'TOTAL':24} {total_examples:>6} {total_toks:>12}")
    print()
    print(f"System prompt: ~{system_prompt_len} chars, {total_system_toks} est tokens/row")
    print(f"  -> {total_system_toks * total_examples} est tokens across dataset (system repeats per row)")
    print(f"User turns:      ~{total_user_toks} tokens")
    print(f"Assistant turns: ~{total_assistant_toks} tokens  (this is what the model learns to produce)")
    print()
    print("Note: token estimate is chars/4, approximate. Use a real tokenizer")
    print("(e.g. tiktoken) for exact counts before sizing a training run.")


if __name__ == "__main__":
    main()
