# Challenges, World Map & Animation — Design Spec

## Overview

Three interconnected workstreams improving the core loop: fixing confirmation sheet spam on multi-day challenges, removing the redundant world map node dialog for unlocked nodes, and adding animation micro-interactions across 6 priority areas.

---

## Workstream A: Challenges — Sheet Guard & Calendar-Based Day Progression

### Problem
The `QuestConfirmationSheet` (a `showModalBottomSheet` in `challenge_detail_screen.dart:557`) shows on **every** action button tap — join, day completion, and final completion alike. For multi-day challenges (`totalDays > 1`), this forces friction each day.

### Solution

#### A1. Challenge Model — Add `joinedAt`
Add `DateTime? joinedAt` field to `Challenge` model (`lib/features/social/domain/models/challenge.dart`):
- `null` when `status == ChallengeStatus.featured`
- Set on join via `joinChallenge()` in `DriftChallengeRepository`
- Persisted in `ChallengeProgressTable` as a new column

#### A2. Sheet Guard Logic (challenge_detail_screen.dart)
`_showConfirmation()` checks challenge status:
- If `status == ChallengeStatus.featured` → show sheet (join flow)
- If `status == ChallengeStatus.active` → skip sheet, call action directly

This means:
- **JOIN QUEST** → sheet shown (first time only)
- **COMPLETE DAY X / FINISH QUEST** → direct action, no sheet

#### A3. Calendar-Based Day Progression
Current: `currentDay` only advances when user taps the action button.
Proposed: Day availability is computed from `joinedAt`:

- `daysSinceJoin = DateTime.now().difference(joinedAt!).inDays` (capped at `totalDays`)
- The "available day" = `min(daysSinceJoin, totalDays - 1)`
- The "logged day" = `currentDay` (only advances when user taps COMPLETE)
- `currentDay` **never exceeds** `availableDay`

**User sees:**
- Day's task/content is visible/accessible based on calendar day, not completion
- Progress counter only ticks up on manual log
- If they miss 3 days on a 7-day challenge, they can still jump to Day 4's content but their progress shows Day 1

#### A4. Implementation Files
| File | Change |
|------|--------|
| `lib/features/social/domain/models/challenge.dart` | Add `joinedAt` field |
| `lib/core/drift/tables/challenge_progress_table.dart` | Add `joined_at` column |
| `lib/core/drift/daos/challenge_progress_dao.dart` | Include `joinedAt` in CRUD |
| `lib/core/drift_repositories/drift_challenge_repository.dart` | Set `joinedAt` on join, compute day availability |
| `lib/features/social/presentation/screens/challenge_detail_screen.dart` | Sheet guard in `_showConfirmation`, update action button label logic |
| `lib/features/social/presentation/widgets/quest_confirmation_sheet.dart` | No change (still used for join) |

---

## Workstream B: World Map — Skip Dialog, Direct to Level

### Problem
Clicking a node on the world map always shows `NodeQuestDialog` (a `showDialog` in `world_map_screen.dart:324`), which adds an extra tap before the player reaches the content.

### Solution

#### B1. Conditional Navigation (world_map_screen.dart)
`_showNodeDetail()` becomes conditional:

```
if node.state == NodeState.locked:
  → showDialog(NodeQuestDialog) // locked info only
else:
  → Navigator.push(LevelImmersiveScreen)
```

- `NodeQuestDialog` retains only the locked state rendering (remove available/inProgress/completed branches from the dialog or use dialog only for locked)
- All unlocked states bypass dialog entirely

#### B2. Companion Guide Brief (level_immersive_screen.dart)
On first visit to a node's immersive screen, show a one-time brief overlay:

- Small glassmorphic card with 3-4 tips explaining the screen sections (directive → attributes → quests → action button)
- Can be dismissed by tapping "GOT IT" or tapping outside
- Persisted via `LocalSettingsRepository` keyed by `hasSeenNodeGuide_${node.id}`
- Reuses the companion overlay pattern from `lib/features/companion/`

#### B3. Implementation Files
| File | Change |
|------|--------|
| `lib/features/world_map/presentation/screens/world_map_screen.dart` | Conditional `_showNodeDetail` |
| `lib/features/world_map/presentation/widgets/node_quest_dialog.dart` | Simplify to locked-only content |
| `lib/features/world_map/presentation/screens/level_immersive_screen.dart` | Add companion guide brief overlay |

---

## Workstream C: Animation & Interactivity (6 Priority Areas)

### P1: StructureNode Tap Feedback (world map)
**File:** `lib/features/world_map/presentation/widgets/structure_node.dart`
**Change:** Wrap `GestureDetector` with `InkResponse` or add `Transform.scale` tween on tap-down:
- On pointer down: scale to 0.92 with 100ms `easeOut`
- On pointer up/cancel: scale back to 1.0 with 200ms `easeOutBack`
- Use `AnimatedScale` or manual `AnimationController` with `TickerProviderStateMixin`
- Haptic `selectionClick()` on tap

### P2: LevelImmersiveScreen Entrance Stagger
**File:** `lib/features/world_map/presentation/screens/level_immersive_screen.dart`
**Change:** Staggered entrance using `flutter_animate`:
- Background: already (immediate)
- Hero section (emoji + name): `.fadeIn().slideY(begin: 0.1)` at 100ms
- Directive card: `.fadeIn().slideY(begin: 0.1)` at 200ms
- Attribute chips: `.fadeIn().scale()` at 300ms
- Quest challenges: staggered per card at 400ms + 100ms delay each
- Action button: `.fadeIn().slideY(begin: 0.1)` at 600ms

### P3: ChallengeDetailScreen Entrance Animations
**File:** `lib/features/social/presentation/screens/challenge_detail_screen.dart`
**Change:** Staggered entrance with `flutter_animate`:
- Hero image: `.fadeIn()` at 0ms
- Title + badges: `.fadeIn().slideY()` at 200ms
- Progress bar: `.scaleX()` width tween at 300ms
- Step timeline: each step `.fadeIn().slideX()` with 80ms stagger
- Action button: `.fadeIn().slideY()` at 500ms

### P4: Social/Leaderboard Staggered Lists
**Files:** `lib/features/social/presentation/screens/friends_leaderboard.dart`, `tribe_tab_content.dart`
**Change:** Wrap list items in `flutter_animate` with index-based delay:
```
items.asMap().entries.map((entry) => entry.value
  .animate(delay: (50 * entry.key).ms)
  .fadeIn().slideX(begin: 0.05))
```
Use `AnimatedList` or manual key-based stagger; respect `MediaQuery.disableAnimations`.

### P5: Auth Screen Entrance Animations
**Files:** Auth screens (login, signup)
**Change:** Add entrance sequence:
- Logo/title: `.fadeIn().slideY()` at 0ms
- Form fields: sequential `.fadeIn().slideX(begin: 0.03)` at 150ms, 250ms, 350ms
- Action button: `.fadeIn().scale()` at 400ms
- Respect `MediaQuery.disableAnimations`

### P6: AttributeRadarChart Animated Fill
**File:** `lib/features/gamification/presentation/widgets/attribute_radar_chart.dart`
**Change:** Replace static `CustomPainter` with animated version:
- Add `AnimationController` with `TickerProviderStateMixin` (1.2s duration)
- `Tween<double>` from 0.0 to 1.0 controlling fill amount
- `CustomPainter` reads animation value to interpolate polygon vertices from center outward
- Trigger animation on first frame via `WidgetsBinding.instance.addPostFrameCallback`
- Re-animate if attribute values change (use `didUpdateWidget` diff)

### Animation Implementation Notes (All)
- **Reduced motion:** Check `MediaQuery.of(context).disableAnimations` — skip all custom animations if true
- **No new dependencies:** Use existing `flutter_animate` (already imported in 13 files) and `AnimationController` patterns already established in the codebase
- **No shared utility:** Keep each animation self-contained (consistent with existing pattern — no central animation helper currently)

---

## Implementation Order

| Phase | Workstream | Dependencies | Est. Files |
|-------|-----------|-------------|------------|
| 1 | Challenges — `joinedAt` model + drift table | None | 4 files |
| 2 | Challenges — sheet guard + day progression | Phase 1 | 2 files |
| 3 | World map — conditional dialog removal | None | 2 files |
| 4 | World map — companion guide brief | None | 1 file |
| 5 | Animations — P1 (StructureNode tap) | None | 1 file |
| 6 | Animations — P2 (LevelImmersiveScreen stagger) | None | 1 file |
| 7 | Animations — P3 (ChallengeDetailScreen stagger) | None | 1 file |
| 8 | Animations — P4 (Social lists stagger) | None | 2 files |
| 9 | Animations — P5 (Auth entrance) | None | 2-3 files |
| 10 | Animations — P6 (Radar chart fill) | None | 1 file |

Phases 1–2 are sequential; phases 3–10 are independent of each other.

---

## Files With No Changes Needed
- `quest_confirmation_sheet.dart` — still used for join flow
- `challenge_catalog.dart` — no catalog changes
- `archetype_maps_catalog.dart` — no map data changes
- `nebula_background.dart` — already rich in animation
- `completion_celebration.dart` — already excellent
