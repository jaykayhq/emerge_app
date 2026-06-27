#!/usr/bin/env python3
"""Convert seeds.jsonl into other fine-tuning formats.

Source of truth: seeds.jsonl (ShareGPT-style, with a per-row system turn).
Outputs are written to ./dist/<format>.jsonl.

Formats:
  openai   -> {"messages":[{"role":"system","value"}, {"role":"user",...},
                            {"role":"assistant",...}]}
  gemini   -> {"system_instruction": {"parts":[{"text":...}]},
               "contents":[{"role":"user","parts":[{"text":...}]},
                           {"role":"model","parts":[{"text":...}]}]}
  alpaca   -> {"instruction":..., "input":"", "output":..., "system":...}

Usage:
  python convert.py --to openai
  python convert.py --to openai --to gemini --to alpaca
  python convert.py --to openai --out dist/openai.jsonl
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

HERE = Path(__file__).parent
SRC = HERE / "seeds.jsonl"

# ShareGPT "from" -> OpenAI "role"
_ROLE = {"system": "system", "human": "user", "gpt": "assistant"}


def _turns_to_map(conv: list[dict]) -> dict[str, str]:
    """Return {system, user, assistant} from a conversations list."""
    out = {"system": "", "user": "", "assistant": ""}
    for t in conv:
        role = _ROLE.get(t["from"], t["from"])
        key = {"system": "system", "user": "user", "assistant": "assistant"}[role]
        out[key] = t["value"]
    return out


def to_openai(rows: list[dict]) -> list[dict]:
    out = []
    for r in rows:
        msgs = []
        for t in r["conversations"]:
            msgs.append({"role": _ROLE[t["from"]], "content": t["value"]})
        out.append({"messages": msgs})
    return out


def to_gemini(rows: list[dict]) -> list[dict]:
    out = []
    for r in rows:
        m = _turns_to_map(r["conversations"])
        contents = [{"role": "user", "parts": [{"text": m["user"]}]},
                    {"role": "model", "parts": [{"text": m["assistant"]}]}]
        out.append({
            "system_instruction": {"parts": [{"text": m["system"]}]},
            "contents": contents,
        })
    return out


def to_alpaca(rows: list[dict]) -> list[dict]:
    out = []
    for r in rows:
        m = _turns_to_map(r["conversations"])
        out.append({
            "instruction": m["user"],
            "input": "",
            "output": m["assistant"],
            "system": m["system"],
        })
    return out


CONVERTERS = {"openai": to_openai, "gemini": to_gemini, "alpaca": to_alpaca}


def _write_jsonl(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"  wrote {len(rows):>4} rows -> {path}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--to", action="append", required=True,
                   choices=list(CONVERTERS),
                   help="target format (repeatable)")
    p.add_argument("--src", default=str(SRC), help="source seeds.jsonl path")
    p.add_argument("--out", action="append", default=None,
                   help="output path (one per --to, in order)")
    args = p.parse_args()

    src = Path(args.src)
    if not src.exists():
        raise SystemExit(f"source not found: {src} (run build_seeds.py first)")

    rows = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    print(f"loaded {len(rows)} rows from {src}")

    outs = args.out or [None] * len(args.to)
    if len(outs) != len(args.to):
        raise SystemExit("--out count must match --to count")

    for fmt, out in zip(args.to, outs):
        converted = CONVERTERS[fmt](rows)
        target = Path(out) if out else HERE / "dist" / f"{fmt}.jsonl"
        _write_jsonl(converted, target)


if __name__ == "__main__":
    main()
