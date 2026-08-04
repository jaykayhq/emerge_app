# SP-A-R Design — "The Narrator IS The Guide": Narrator-Guided Tutorials, Day Card, Typewriter, Spotlight

> **Date:** 2026-08-04
> **Status:** Approved (brainstorming session 2026-08-04; revises SP-A)
> **Predecessor:** `2026-08-01-narrator-coach-tutorials-premium-limits-design.md` (SP-A, approved 2026-08-01). SP-A's tutorials layer (`lib/features/tutorials/`) and coach sheet shipped; this revision **replaces** the node-guide system with the narrator as the guide, **deletes** the modal NarratorSheet, and restores typewriter rendering. Premium limits (3 coach asks/day) are **unchanged** and reused as-is.
> **Scope:** Client-only. No `firestore.rules`, `firestore.indexes.json`, or `functions/` changes.

---

## 1. Goals

1. **The narrator is the guide.** Delete the node-guide system (`lib/features/tutorials/`, `FeatureCoachMark`) and all "little guides". First-visit tutorials become narrator-voiced scripts: the narrator card types a line while a **spotlight hole** highlights the exact section it explains.
2. **The timeline narrator card gives value.** Replace the passive `NarratorSummaryCard` with the **Day Card**: typed day-line + glanceable status chips (streak, remaining today) + inline coach ask. It must be useful on every open, not just on events.
3. **Typewriter everywhere.** All narrator text types out (~35 cps, blinking caret), tap-to-skip completes instantly, reduced motion renders instantly. `docs/design.md` is amended (it currently bans typewriter text).
4. **One narrator surface.** Delete `NarratorSheet` (coach modal, evening reflection modal, streak-break modal). Those jobs move to the Day Card (ask) and the typed `NarratorMilestoneCard` (events). Premium quota behavior preserved.

## 2. Recorded design decisions

| Decision | Choice |
|---|---|
| Guide system | **Narrator-voiced guide** — node-guide registry/host/overlay + `FeatureCoachMark` deleted |
| Guide flow | **Tap-through steps** — 2–4 steps per screen; text types → spotlight moves → [Next →] / [Got it] |
| Guide surfaces | 9 nodes (`coach` folds into `timeline`'s last step, spotlighting the card's ask chip) |
| Timeline card | **Day Card**: typed line + streak/remaining chips + expandable ✎ ask chip |
| NarratorSheet | **Deleted** — ask → card (inline, typed reply); evening/streak-break → typed milestone card |
| Typewriter | **Restored everywhere** narrator text appears: 35 cps, caret, tap-to-skip, reduced-motion instant |
| Spotlight | In-tree host + `GuideTarget` GlobalKeys + `SpotlightPainter` (scrim, animated hole) |
| Seen-flag keys | `hasSeenNodeGuide_*` → `hasSeenNarratorGuide_*`, idempotent migration |
| Premium quota | Unchanged (3 asks/day free, unlimited premium) — logic relocated into the card |

## 3. Architecture

```
                    NARRATOR (single voice, two surfaces)
                             │
        ┌────────────────────┼─────────────────────┐
        │                    │                     │
   Day Card (timeline)   NarratorMilestoneCard   NarratorGuide
   ┌─────────────────┐   (slide-up, typed)      (first-visit)
   │ typed day-line   │   events: on-fire,      NarratorGuideHost
   │ status chips     │   level-up, streak-     └ GuideTarget keys
   │ ✎ ask → quota →  │   break, evening,       └ SpotlightPainter
   │   typed reply    │   long absence          └ NarratorGuideCard
   └─────────────────┘                          (typed script + Next)
        │
        └── TypewriterText (core widget, all surfaces)
```

- **Narrator core (kept):** `NarratorTriggerEngine`, `NarratorLineResolver` (generic/premium), `lineResolverProvider`, `PendingMilestone` notifier, `NarratorAvatar`, `NarratorMilestoneCard`, Drift notes. Unchanged except where noted.
- **Deleted:** `lib/features/tutorials/` (registry, controller, host, overlay), `feature_coach_mark.dart`, `narrator_sheet.dart`, `narrator_summary_card.dart`.
- **New (in `lib/features/narrator/`):** Day Card, guide engine (registry/host/target/painter/card), controller. **New (core):** `TypewriterText`.

## 4. Component specs

### 4.1 TypewriterText (`lib/core/presentation/widgets/typewriter_text.dart`)

- Pure function for testability (project signature pattern): `int visibleCharCount(String text, int elapsedMs, int charsPerSecond)` → 0 at t=0, linear progress, saturates at `text.length`.
- Widget: `AnimationController` (duration = `text.length / cps * 1000ms`, default 35 cps), renders `text.substring(0, visible)`.
- Blinking caret: 1s steps-opacity animation, visible while typing and ~400ms after completion.
- Tap anywhere on the text → `controller.value = 1.0` (complete instantly). `onComplete` fires when typing finishes (natural or skipped).
- Reduced motion (`MediaQuery.disableAnimationsOf(context)` or `accessibleNavigation`) → full text instantly, no caret.
- Semantics: expose the **full** string as the label while typing (screen readers never see fragments).
- Long lines wrap normally (substring of the full string; no measurement hacks).

### 4.2 NarratorCard — the Day Card (replaces `NarratorSummaryCard`)

`lib/features/narrator/presentation/widgets/narrator_card.dart`, mounted in the timeline sliver where `NarratorSummaryCard` sits today (`timeline_screen.dart:558`).

Structure (top → bottom), glass base (existing `GlassmorphismCard`, teal glow):

1. **Header:** small narrator avatar (pulses while a line is typing) + `NARRATOR` wordmark + ✕ dismiss.
   - ✕ hides the card for the current session (`narratorCardDismissedProvider`, session-scoped notifier). Card returns when a new line arrives (pending milestone set, insight change) or next app open.
2. **Typed line** (`TypewriterText`). Source priority (pure `resolveCardLine(latestInsight, pendingMilestone, dayStatus)` → `NarratorLine?`, unit-tested):
   a. pending milestone line (if set),
   b. latest `aiInsight` note (`latestNarratorInsightProvider`),
   c. computed day-status line (no LLM): `N left today — start with <first incomplete habit name>.` / `All done for today. <N>-day streak is holding you.` / empty-state (`total == 0`): `This is where your day takes shape. Add a habit and I'll keep watch.`
   - `DATA-GROUNDED` badge (warmGold) when the line is a `PersonalLine` (kept from the sheet).
3. **Status chips** (always visible, glanceable value): `🔥 <N>-day streak` (from `userStatsStreamProvider.avatarStats.streak`) + `N left today` / `✓ All done` (computed from today's active habits vs completed).
4. **✎ Ask the narrator** chip → expands to an inline `TextField` → **relocated `_submitAsk` logic** from `NarratorSheet`:
   - quota check (`coachAskQuotaControllerProvider`) → exhausted → `showPremiumLimitDialog(PremiumLimitType.coachAsk)`;
   - premium → `GroqAiService.getCoachAdvice` grounded in `userStatsStreamProvider` profile → `PersonalLine` (DATA-GROUNDED);
   - free → curated `_genericAskPool` (hash by question) → `GenericLine`;
   - `quotaCtrl.consume()`; reply **types in place** in the card; hint line `2 of 3 coach asks left today` / `Unlimited coach asks`.

Avatar tap (timeline header) now **expands the card's ask field** and scrolls it into view: `narratorAskFocusProvider` (session notifier) → card listens, expands, focuses, `Scrollable.ensureVisible`. This replaces `_openCoach` (`timeline_screen.dart:253-267`).

### 4.3 NarratorMilestoneCard (polish + optional actions)

`lib/features/narrator/presentation/widgets/narrator_milestone_card.dart`:

- Line renders via `TypewriterText` (tap-to-skip); keep slide-up, swipe-to-dismiss, 6s auto-dismiss, trigger label, PERSONAL badge.
- **New optional `actions`** (label + onTap chips, rendered under the line) so event messages keep their response recording. The **evening reflection** (was sheet at `timeline_screen.dart:232`): fires the milestone card with the evening line + action chips; tap records `NarratorNoteType.reflectionLogged` (completedCount/totalHabits/response) exactly as the sheet's `onResponse` did; once-per-day prefs key kept.
- **Streak break** (`streak_recovery_screen.dart`): the streak-break line becomes a milestone card (typed), shown on open **when the guide is not due** (same gating as today: guide first visit → message after). `NarratorSheet.show` call removed.

### 4.4 Narrator Guide engine (replaces `lib/features/tutorials/`)

Lives in `lib/features/narrator/`. Same first-visit gate concept, narrator renderer, real spotlight.

1. **`domain/services/narrator_guide_registry.dart`** (pure data, hardcoded Dart like the current registry):
   - `NarratorGuideStep { String script; String targetKey; }`
   - `NarratorGuideDefinition { String nodeId; List<NarratorGuideStep> steps; }`
   - **9 nodes**, 2–4 steps each, scripts rewritten in first-person narrator voice ("See the + down there? That's where habits are born."). `timeline`'s last step spotlights the Day Card's ask chip (coach node folded in). Every `targetKey` must exist in that screen's tree.
2. **`presentation/providers/narrator_guide_controller.dart`** (`@Riverpod(keepAlive: true)`, `.g.dart` generated): `shouldShow(nodeId)` = `tutorialsEnabled` && unseen; `markSeen(nodeId)` persists `hasSeenNarratorGuide_<nodeId>` via `LocalSettingsRepository`. (Direct port of the current `NodeGuideController`.)
3. **`presentation/widgets/guide_target.dart`**: keyed wrapper (`GlobalKey` + `RepaintBoundary`) placed around explainable sections; registers its rect for the painter. Inside a scrollable, it listens to its enclosing `Scrollable` and repaints on scroll.
4. **`presentation/widgets/spotlight_painter.dart`**: `CustomPainter` — dims everything (`Colors.black` ~60%) except a rounded-rect hole at the active target's rect (`Path.combine(PathOperation.difference, ...)`); hole position glides between steps (200ms easeInOut); reduced motion → no glide. Unmounted/off-screen target → no hole for that step (card-only), never blocks.
5. **`presentation/widgets/narrator_guide_host.dart`**: wraps the screen (swap-in for `NodeGuideHost` at the 9 call sites); post-frame `_maybeShow`; renders `Stack[ child, Positioned.fill(SpotlightPainter), Positioned(bottom: NarratorGuideCard) ]`. Rects resolved via `GlobalKey.currentContext → RenderBox → localToGlobal` against the overlay's own coordinate space.
6. **`presentation/widgets/narrator_guide_card.dart`**: compact narrator card (same glass styling): avatar + typed script (`TypewriterText`) + `[Next →]` / `[Got it]` (enabled when typing completes or skipped) + `[Skip]` top-right. Any dismissal (Got it/Skip) → `markSeen`.

Screens and their guides (host + targets), 9 total:

| Node | Screen | Route/file |
|---|---|---|
| `timeline` | Timeline (steps: FAB → progress ring → Day Card ask) | `timeline_screen.dart` |
| `habit_create` | Create habit | `habit_create_screen.dart` |
| `streak_recovery` | Streak Recovery | `streak_recovery_screen.dart` |
| `world_map` | World Map | `world_map_screen.dart` |
| `leveling` | Leveling | `leveling_screen.dart` |
| `future_self` | Future Self Studio | `future_self_studio_screen.dart` |
| `challenges` | Challenges | `challenges_screen.dart` |
| `all_tribes` | All Tribes | `all_tribes_screen.dart` |
| `tribe_lobby` | Tribe Lobby | `tribe_lobby_screen.dart` |

`coach` node is **dropped as a standalone node** (the sheet that hosted its overlay is deleted); its content is the timeline guide's final step.

### 4.5 Settings & migration

- `settings_screen.dart` Tutorials section (lines 324–362): copy → **"Show narrator guides"** toggle (reuses `tutorialsEnabled`) and **"Replay narrator guides"** (`resetTutorials()`). No structural change.
- `local_settings_repository.dart`: new pure `migrateNarratorGuideFlags()` — idempotent `hasSeenNodeGuide_<node>` → `hasSeenNarratorGuide_<node>` (copy only existing keys, never overwrite); retarget the existing `companion_visited_*` migration to the new keys.

### 4.6 Deletions

- `lib/features/tutorials/` (registry, controller + `.g.dart`, host, overlay) + `test/features/tutorials/`.
- `lib/core/presentation/widgets/feature_coach_mark.dart` + test (verified: sole consumers were the tutorials files).
- `lib/features/narrator/presentation/widgets/narrator_sheet.dart` + `narrator_summary_card.dart` + their tests (`narrator_coach_flow_test.dart`, `narrator_summary_card_test.dart`).
- `NarratorStateNotifier` / `NarratorAppearance` — delete **only if** `dart analyze` proves no consumers remain after the sheet deletion (streak_recovery + timeline become the only authors, and they switch to milestone-card args). Clean what the analyzer proves dead; no speculative deletion.

### 4.7 `docs/design.md` amendments (keep it the source of truth)

- §11.5 "The Narrator as Feedback" → rewrite as "The Narrator is the Guide": narrator owns first-visit tutorials (spotlight + typed scripts), the Day Card, and the coach ask; typewriter restored (35 cps, tap-to-skip, reduced-motion instant); milestone card for events; sheet removed.
- §12.4 anti-pattern table: replace the `Typewriter text anywhere` ban with `Unskippable typewriter` (tap-to-skip + reduced-motion are the mitigations).
- §6 animation: add typewriter pacing token (35 cps) and spotlight glide token (200ms).

## 5. Data & storage changes

| Storage | Change |
|---|---|
| shared_prefs `tutorialsEnabled` | Reused |
| shared_prefs `hasSeenNodeGuide_*` | **Migrated once** → `hasSeenNarratorGuide_*`, then obsolete |
| shared_prefs `hasSeenNarratorGuide_<node>` | New target keys |
| shared_prefs `coach_asks_<date>` | Reused (quota unchanged) |
| shared_prefs `companion_visited_*` | Read once by migration (retargeted), then obsolete |
| Drift / Firestore | No changes |

## 6. File inventory

**New:**
- `lib/core/presentation/widgets/typewriter_text.dart` (+ test)
- `lib/features/narrator/presentation/widgets/narrator_card.dart` (+ test)
- `lib/features/narrator/domain/services/narrator_guide_registry.dart` (+ test)
- `lib/features/narrator/presentation/providers/narrator_guide_controller.dart` (+ `.g.dart`, generated)
- `lib/features/narrator/presentation/widgets/narrator_guide_host.dart`
- `lib/features/narrator/presentation/widgets/narrator_guide_card.dart`
- `lib/features/narrator/presentation/widgets/guide_target.dart`
- `lib/features/narrator/presentation/widgets/spotlight_painter.dart`

**Modified (primary):**
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — host swap, Day Card mount, avatar tap → card ask focus, evening reflection → milestone card, `_openCoach` removal
- `lib/features/narrator/presentation/widgets/narrator_milestone_card.dart` — typing + optional actions
- `lib/features/narrator/presentation/providers/narrator_providers.dart` — card ask focus / dismiss notifiers; resolver wiring unchanged
- `lib/features/habits/presentation/screens/streak_recovery_screen.dart` — host swap, sheet → milestone card
- `lib/features/onboarding/data/repositories/local_settings_repository.dart` — flag migration
- `lib/features/settings/presentation/screens/settings_screen.dart` — copy
- 7 guide screens (`habit_create`, `world_map`, `leveling`, `future_self`, `challenges`, `all_tribes`, `tribe_lobby`) — host swap + `GuideTarget` wrappers
- `docs/design.md` — amendments (§6, §11.5, §12.4)

**Deleted:**
- `lib/features/tutorials/` + tests
- `lib/core/presentation/widgets/feature_coach_mark.dart` + test
- `lib/features/narrator/presentation/widgets/narrator_sheet.dart` + `narrator_summary_card.dart` + tests
- (Conditional) `NarratorStateNotifier` / `NarratorAppearance` if analyzer-proven dead

## 7. Error handling & edge cases

- **Target unmounted / off-screen** (guide step's section scrolled away or not built): skip the hole for that step, card-only, never blocks `Next`.
- **Scroll during guide:** `GuideTarget` listens to its enclosing `Scrollable` → rects recompute per scroll frame (single `setState`; painter repaints the hole only).
- **Typing vs. fast readers:** tap-to-skip completes the line instantly; `Next`/`Got it` enabled on completion or skip.
- **Reduced motion:** no typewriter, no caret, no spotlight glide — instant text and hole jumps.
- **Quota/prefs failure:** prefs read failure → default 0 used (never hard-block); write failure → log, still allow the ask. (SP-A policy, preserved.)
- **Migration idempotency:** `migrateNarratorGuideFlags()` copies only existing keys, never overwrites already-seen flags.
- **Evening reflection dedupe:** once-per-day prefs key behavior preserved from the sheet flow.
- **Milestone card during guide:** streak-break message defers until the guide is seen (same ordering as today).
- **Premium on web:** `isPremiumProvider` false on web → free quota until SP-B. Unchanged, accepted.

## 8. Testing strategy (TDD Iron Law — focused runs only)

1. `typewriter_text_test.dart` — pure `visibleCharCount` (t=0 → 0, mid-progress, saturation); widget: typed prefix renders, tap completes, reduced-motion instant.
2. `narrator_guide_registry_test.dart` — pure: 9 nodes, unique nodeIds, 2–4 steps each, every step has non-empty script + targetKey.
3. `narrator_card_test.dart` — widget: line priority (pending > insight > day-status), chips (streak / N left / all done / empty state), ask expand → quota consume → typed reply, exhausted → premium dialog, dismiss → session-hidden.
4. `narrator_guide_host_test.dart` — widget: first visit shows guide, `tutorialsEnabled=false` suppresses, `Next` advances steps, hole rect present at target, Got it/Skip → `markSeen`.
5. `narrator_milestone_card_test.dart` — update: typing + tap-to-skip; new: optional actions render + fire + dismiss.
6. `guide_flags_migration_test.dart` — pure: `hasSeenNodeGuide_*` → `hasSeenNarratorGuide_*` + idempotency + retargeted `companion_visited_*` mapping.
7. Update `settings_screen_test.dart` copy expectations; delete `node_guide_registry_test`, `node_guide_host_test`, `feature_coach_mark_test`, `narrator_coach_flow_test`, `narrator_summary_card_test`.

## 9. Out of scope (unchanged queue from SP-A)

- **SP-B:** web premium activation, generic limits framework extension, offer copy.
- **SP-C through SP-H:** as listed in the SP-A spec (theme lock, All Tribes split, creator invites, blueprints removal, tribe XP accounting, server-side changes).

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Spotlight rect drift across devices/surfaces | `GuideTarget` + `RepaintBoundary` + per-frame/scroll recompute; degrade to card-only when a rect is unavailable |
| Typewriter regressions on slow devices | Tap-to-skip always available; reduced-motion path; pure function unit-tested |
| Sheet deletion breaks unseen callers | Grep-verified 4 call sites (timeline ×2, streak_recovery, summary card); `dart analyze` gates; all three flows re-wired in this spec |
| Migration mis-runs on existing installs | Idempotent copy-only migration; unit-tested; never overwrites |
| Half-finished working tree | Plan commits in coherent task units; `dart analyze` + focused tests before each commit |
