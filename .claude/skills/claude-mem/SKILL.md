---
name: claude-mem
description: |
  Use when storing or retrieving persistent agent memory across sessions.
  Layers project-specific memory protocols on top of opencode-mem's SQLite
  vector store (~/.opencode-mem/data/, web UI at http://127.0.0.1:4747).
  Activated at session start/end, when referencing past decisions, or when
  the developer mentions continuing prior work.
  ALWAYS check memory before making architecture assumptions.
---

# Claude Mem — Persistent Cross-Session Memory for Agents

This project uses **opencode-mem** (v2.17.1) as the persistent memory backend.
All data is local SQLite with local embeddings via `Xenova/nomic-embed-text-v1`.
No API keys, no network egress.

## Backend Commands (opencode-mem)

```bash
memory({ mode: "add",       content: "..." })                                  # store a memory
memory({ mode: "search",    query: "...", scope: "project" })                 # semantic search (current project)
memory({ mode: "search",    query: "...", scope: "all-projects" })            # semantic search (all projects)
memory({ mode: "list",      limit: 10 })                                       # list recent memories
memory({ mode: "profile" })                                                    # show learned user profile
```

## When to Store

| Situation | Example |
|---|---|
| Architecture decisions | "Chose Riverpod over BLoC for state management" |
| Dependency rationale | "Drift for local-first, Firestore for sync — not Room/REST" |
| Bug root causes | "Bug #42 was off-by-one in streak calc, fixed in commit abc123" |
| User preferences | "Developer prefers dark mode, 4-space indents, double quotes" |
| Workarounds | "Firestore batch limit is 500 — chunk to 400 with buffer" |
| Pattern commitments | "Domain layer never depends on data layer — Clean Architecture" |
| Session scratchpad | "Refactoring HabitRepository: halfway done, next is DriftHabitRepository" |
| Cancellation reasons | "Skipped Companion Engine v1 — pivoted to narrator notes table" |
| Commit conventions | "feat(feature): verb-noun, fix: cause-not-symptom" |

## When to Search

Always search memory before:
- Making architecture assumptions
- Recommending dependencies
- Answering "what did we decide about X?"
- Resuming work after a break
- Repeating a correction the developer already gave

Session-start ritual:
```bash
memory({ mode: "search", query: "<project name> architecture decisions" })
memory({ mode: "search", query: "<project name> user preferences coding style" })
```

## Project-Specific Memory Types

Beyond general facts, this project uses structured memory entries:

### Decision Memories
```
content: "DECISION: go_router 17 over auto_route"
tags: ["architecture", "routing", "decision"]
context: { "feature": "core", "commit": "abc123", "date": "2026-07-06" }
```

### Pattern Memories
```
content: "PATTERN: Riverpod @riverpod auto-dispose for streams, @Riverpod(keepAlive) for repos"
tags: ["pattern", "riverpod", "convention"]
context: { "files": ["habits/presentation/providers/habit_providers.dart"] }
```

### Bug Memory
```
content: "BUG: ref.watch inside go_router redirect causes rebuild loop"
tags: ["bug", "gotcha", "routing", "fire-and-forget"]
context: { "severity": "high", "fixed_commit": "abc123" }
```

### Scratchpad Memory (ephemeral, low priority)
```
content: "Current work: PulseFeedScreen drift migration — 60% done"
tags: ["scratchpad", "in-progress"]
context: { "session": "2026-07-06-001" }
```

## Compression Strategy

Over time, individual memories accumulate. Use the compression strategy:

1. **Active window**: All memories from the last 7 days — fully searchable
2. **Summary window**: Older memories get batch-summarized into fewer summary entries
3. **Archive**: >90 days → minimal tags only, full text pruned

When opencode-mem grows beyond practical search, record a synthesis:
```bash
memory({ mode: "add", content: "SUMMARY: All July 2026 corrections were about Drift migration patterns — see commit range abc..def" })
```

## Privacy

All memory data is stored locally at `~/.opencode-mem/data/`. Never:
- Store secrets, API keys, tokens
- Record full error messages with stack traces
- Include credentials from `.env`
- Share memory contents with external services

## Cross-Skill Integration

| Skill | When to Check Memory |
|---|---|
| `systematic-debugging` | Before hypothesizing root cause, check if this bug was seen before |
| `test-driven-development` | Before writing tests, check "what test patterns do we use?" |
| `writing-plans` | Before planning, check "what architectural decisions are locked?" |
| `verification-before-completion` | Before claiming done, check "did I verify the right things last time?" |
| `task-observer` | After session, check "what patterns emerged that should be remembered?" |

## Session Protocol

### Session Start
1. Search project memories for context
2. Check user profile for preferences
3. Load scratchpad for in-progress work

### Session End
1. Record key decisions made this session
2. Record any new patterns or bug discoveries
3. Update scratchpad with current state
4. Run `task-observer` synthesis to capture patterns

### On Resume
1. List recent memories
2. Search for active scratchpad items
3. Check pending task-observer recommendations
