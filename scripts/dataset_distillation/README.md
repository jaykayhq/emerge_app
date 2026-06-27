# Dataset Distillation for `emerge_app`

A curated, offline, **project-grounded** instruction-tuning dataset that teaches a
coding agent to make good decisions on this Flutter / Dart / Firebase / Riverpod
codebase — the way this agent does: concise, code-grounded, test-first,
evidence-before-claims.

The goal is **distillation**, not volume: a relatively small set of high-signal
examples that capture *how to work on this specific project*, so a weaker model
fine-tuned on it stops running into the same project-specific mistakes (rebuild
loops in the router, the role-claim race, editing generated `.g.dart`, claiming
"done" without running the tests, etc.).

## What's here

```
scripts/dataset_distillation/
├── README.md          # this file
├── SYSTEM_PROMPT.md   # the distilled agent persona + project rules (system turn)
├── build_seeds.py     # generates seeds.jsonl (the curated source of truth)
├── seeds.jsonl        # PRIMARY artifact: ShareGPT-style examples (~110)
├── convert.py         # JSONL -> {openai, gemini, alpaca}.jsonl
├── validate.py        # schema / dedup / balance checks (CI-friendly)
└── stats.py           # category counts + token estimates
```

Everything regenerates from `build_seeds.py` + `SYSTEM_PROMPT.md`. `seeds.jsonl`
and `dist/` are derived artifacts.

## Schema

`seeds.jsonl` — one JSON object per line, ShareGPT-style:

```json
{
  "category": "project_gotchas",
  "conversations": [
    {"from": "system", "value": "<contents of SYSTEM_PROMPT.md>"},
    {"from": "human",  "value": "My router rebuilds in an infinite loop..."},
    {"from": "gpt",    "value": "You almost certainly used ref.watch inside..."}
  ]
}
```

Every row carries the full system prompt (so the fine-tuned model internalizes
the rules without you having to pass them at inference). If you'd rather not
repeat it per row, strip the system turn with a one-liner (see *Variants*
below) — but the default is the more robust choice for small models.

## Categories

| Category | What it distills |
|----------|------------------|
| `architecture_layout` | Feature-first folders, Riverpod annotation+codegen, `core/` vs `features/`, provider/repo/entity conventions |
| `testable_design` | The project's signature pattern: extract pure logic + plain data struct, unit-test without Firebase/Riverpod (`decideRedirect` + `RedirectContext`) |
| `tdd_discipline` | Red-green-refactor, "watch it fail for the right reason," delete-code-before-test rationalizations |
| `systematic_debugging` | 4-phase root-cause, the 3-strike architecture rule, evidence at component boundaries |
| `verification` | Run the proving command and quote output before claiming done; "should work now" is a red flag |
| `project_gotchas` | `ref.watch`-in-redirect loops, role-claim race, `setUserRole` fallback, Google web/native fork, fpdart `Either`, never edit `*.g.dart` |

## Usage

### 1. Regenerate the source of truth

```bash
cd scripts/dataset_distillation
python build_seeds.py
```

Edit examples in `build_seeds.py` (the `EXAMPLES` list) and the persona in
`SYSTEM_PROMPT.md`, then re-run. Never hand-edit `seeds.jsonl`.

### 2. Validate

```bash
python validate.py
```

Checks JSON schema, turn order (`system` → `human` → `gpt`), non-empty turns,
category balance, and near-duplicate prompts. Exits non-zero on hard errors —
safe to wire into CI.

### 3. Inspect stats

```bash
python stats.py
```

Per-category counts, balance ratio, and a chars/4 token estimate. Use a real
tokenizer (e.g. `tiktoken`) for exact counts before sizing a training run.

### 4. Convert for your target platform

```bash
# all three at once
python convert.py --to openai --to gemini --to alpaca

# one, with a custom output path
python convert.py --to openai --out ../../dist/openai.jsonl
```

Outputs land in `./dist/<format>.jsonl` by default:

- **OpenAI** — `{"messages":[{"role":"system",...},{"role":"user",...},{"role":"assistant",...}]}`
  (upload directly for gpt-4o / gpt-4o-mini fine-tuning).
- **Gemini / Vertex AI** — `{"system_instruction":{...},"contents":[{"role":"user",...},{"role":"model",...}]}`
  (Vertex AI supervised tuning).
- **Alpaca** — `{"instruction","input":"","output","system"}` (portable across
  Axolotl / Unsloth / llama-factory / generic SFT).

## Workflow to grow the dataset

1. Notice a recurring mistake a model/agent makes on this project.
2. Add a `ex(CATEGORY, "<prompt>", "<response>")` entry in `build_seeds.py`,
   grounded in **real file paths and patterns** from this repo.
3. `python build_seeds.py && python validate.py` — the build dedupes by
   normalized prompt and will refuse to write duplicates.
4. `python convert.py --to <your target>` and re-fine-tune.

The dedup + validate gates are what keep the curated set high-signal as it grows.

## Variants

- **No per-row system prompt** (smaller file, system passed at inference instead):
  ```bash
  python -c "import json,sys;
  [print(json.dumps({k:v for k,v in json.loads(l).items() if k=='category'} | {'conversations':[t for t in json.loads(l)['conversations'] if t['from']!='system']})) for l in open('seeds.jsonl',encoding='utf-8')]" > dist/no_system.jsonl
  ```
- **Single category only**: filter `seeds.jsonl` by `"category"` with `jq` or a
  one-liner before converting.

## Non-goals

- No teacher-model / API calls. Purely offline and deterministic.
- No training run is included — this produces the *dataset*. Run fine-tuning on
  your platform of choice with the converted output.
- No app/lib code is touched. This lives entirely under `scripts/`.

## Provenance

Examples are mined from three sources, all project-specific:
1. **Real code patterns** — `lib/core/router/router.dart`, `creator_routes.dart`,
   `auth_providers.dart`, `test/core/router/router_redirect_test.dart`, `pubspec.yaml`.
2. **Existing skills/specs** — `.agents/skills/{test-driven-development,
   systematic-debugging,verification-before-completion}/*.md` and the
   `docs/superpowers/specs/*` design docs.
3. **Hand-written agent traces** — realistic Q&A modeled on real coding sessions
   on this repo.
