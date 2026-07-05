---
name: memory-management
description: |
  Use when storing or retrieving persistent memory across sessions.
  Covers: storing facts/preferences/decisions, semantic search, user profile,
  cross-project recall, and scratchpad state. Activated by opencode-mem plugin.
  ALWAYS think "should I store this?" before concluding a session.
---

# Memory Management

This project uses **opencode-mem** (v2.17.1) — a persistent local vector memory
system. Data lives in SQLite at `~/.opencode-mem/data/`. Embedding uses
`Xenova/nomic-embed-text-v1` (local, no API key). Web UI at `http://127.0.0.1:4747`.

## Commands

Use the `memory()` tool exposed by the plugin:

```
memory({ mode: "add", content: "..." })           # store a fact/preference/decision
memory({ mode: "search", query: "..." })           # semantic search current project
memory({ mode: "search", query: "...", scope: "all-projects" })  # search all projects
memory({ mode: "list", limit: 10 })                # list recent memories
memory({ mode: "profile" })                        # show learned user profile
```

## When to Store

| Situation | Example |
|---|---|
| Project decisions | "We chose Riverpod over BLoC for state management" |
| User preferences | "User prefers dark mode, 4-space tabs, double quotes" |
| Gotchas / workarounds | "Firestore batch writes limit is 500 — chunk larger operations" |
| Architecture conventions | "Domain layer must not depend on data layer" |
| Dependency rationale | "We use go_router not auto_route because..." |
| Debugging discoveries | "Bug #42 caused by off-by-one in habit streak calc" |
| Session scratchpad | "Currently refactoring HabitRepository — halfway done" |

## When to Search

- Before making architecture assumptions
- Before recommending dependencies
- When the user references past decisions
- When resuming work after a break
- At session start: `memory({ mode: "search", query: "<project context>" })`

## Memory Scope

- `scope: "project"` — current project only (default)
- `scope: "all-projects"` — across all projects

User profile is global and cross-project.

## Auto-capture

The plugin auto-captures conversation summaries every N turns. These are
indexed into the vector DB and become searchable across sessions. No action
needed.

## Privacy

All data is local SQLite on disk. No cloud, no network egress. The web UI is
localhost-only. Sensitive-content filters are built in.
