---
name: loop-engineering
description: Use when needing systematic multi-pass improvement across interconnected systems, bugs that recur across surfaces, or when designing self-improving development workflows. Apply when architectural changes affect multiple features and need iterative validation. Do NOT use for single-file changes or straightforward bug fixes.
---

# Loop Engineering

## Overview

Loop engineering is designing systems where agents work in recurring cycles of action, evaluation, memory, and improvement — rather than prompting one step at a time. A loop replaces the human as the thing inside the loop; the human becomes the author of the loop.

## Core Principle

```
Prompting  = ask for one answer
Loop       = design the recurring system that asks, checks, remembers, and improves
```

A real loop has: **trigger → action → evaluation → memory → stop condition**.

## Five Building Blocks

| Block | Purpose | Failure Mode |
|---|---|---|
| **Trigger** | What starts a cycle (timer, event, condition) | Loop never fires |
| **Scope** | What the agent can touch (files, collections, API scope) | Overreach |
| **Action** | What work is done per tick | Wrong action repeats |
| **Evaluator** | Something that can say "no" (test, type check, assertion) | Agent agrees with itself |
| **Stop condition** | Hard cap (iterations, budget, passing criteria) | Runaway costs |

## The Three Feedback Loops

For software engineering, three loops compose:

1. **Agentic Coding Loop** — fast inner loop: write → run → read result → correct → commit. Capped at N iterations or dollar budget.
2. **Developer Feedback Loop** — medium loop: human reviews output, adjusts direction, loop resumes with refined scope.
3. **External Feedback Loop** — slow loop: user data, analytics, crash reports inform the next product cycle.

The three loops run at different cadences simultaneously. The inner loop is automated; the outer loops involve humans.

## Loop Design Template

```
TRIGGER  → every N minutes, on event, on condition
SCOPE    → which files, repos, features, or data
ACTION   → what the agent does each tick
EVALUATE → tests, lint, typecheck, assertion queries
BUDGET   → max sub-agents, max tokens, max dollars
STOP     → all green, or N iterations, or error repeats
REPORT   → where results land (commit, PR, summary)
```

## Application to App Architecture

Apply loop thinking to product features themselves:

### Social/Engagement Loops

```
Habit complete → XP earned → leaderboard updates → tribe feed notification
→ partner sees activity → streak maintained → badge awarded
→ identity reinforced → more habits completed
```

Each loop must have:
- **Entry point**: what triggers the loop (habit completion, friend request)
- **State**: what persists between cycles (Drift tables, Firestore docs)
- **Evaluator**: what checks success (streak count, XP threshold, challenge progress)
- **Exit**: when the user levels up, finishes a challenge, or disengages

### Offline-First Sync Loops

```
User action → Drift write (immediate) → queue sync operation
→ Firestore flush (async) → Firestore snapshot triggers
→ Drift merge → UI update
```

Failure at any point: local is truth until sync confirms.

## Common Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|---|---|---|
| Open loop | Agent writes until it says "done" with no verification | Add evaluator (test, lint, type check) |
| No-progress loop | Same error repeats across iterations | Counter: stop after N identical failures |
| No stop condition | Loop runs forever, unbounded cost | Hard cap: iterations, dollars, time |
| Missing entry state | Each iteration starts from scratch | Anchor files (VISION.md, AGENTS.md, design docs) |
| Silent failure | Error swallowed, loop continues with bad state | Log + surface errors; stop on critical |

## Verification-Driven Development Loop

For implementing features across multiple interconnected systems (tribes, friends, challenges):

```
1. DEFINE: What "done" looks like (acceptance criteria)
2. IMPLEMENT: Smallest change that moves toward done
3. VERIFY: Run tests, analyze, check criteria
4. LEARN: What broke? What's missing? What's wrong?
5. ADAPT: Refine approach based on evidence
6. REPEAT: Until all criteria met or stop condition triggered
```

Each VERIFY step MUST produce empirical evidence (test output, analyze results). "Should work now" is not evidence.

## When to Use

- Multi-feature changes that interact (tribes + friends + challenges)
- Recurring bugs in same area (offline-first sync race conditions)
- Architecture decisions that span feature boundaries
- Implementing feedback from user testing or analytics

## When NOT to Use

- Single-file, straightforward changes
- Changes with no external dependencies
- Tasks where the first approach is known to work
