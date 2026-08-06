# Habit Time-of-Day, Create-Habit Integrations, Starter-Pack Selection & Coach Fixes — Design

**Date:** 2026-08-05
**App:** Emerge — Identity-First Habit Formation

---

## 1. Problem Statement

Six related defects and regressions across the habits surface and the coach (narrator) surface:

1. **Every habit lands in the "anytime" timeline slot.** The create screen persists a `reminderTime` but never sets `timeOfDayPreference`, so `Habit.timelineSection` (`lib/features/habits/domain/entities/habit.dart:357`) resolves to null and the timeline (`lib/features/timeline/presentation/screens/timeline_screen.dart:248`) groups everything under the fallback slot. Users never see the allotted-time-of-day experience.
2. **Create-habit integrations are gone.** The data model (`HabitIntegrationType`, `integrationTarget`), Drift columns, sync mapping, and the auto-complete engine (`lib/features/health/data/services/health_auto_complete_service.dart`) are all wired — but the create screen has no UI to select Steps / Screen Time integrations.
3. **First-habits screen auto-adopts all 3 recommendations.** Onboarding's "Your starter pack" screen (`lib/features/onboarding/presentation/screens/first_habits_screen.dart`) creates every blueprint on START MY JOURNEY with no way to pick a subset.
4. **Coach ask quota appears to scale with habit count.** The user observed the daily coach-ask budget behaving as ~8 when they had 8 habits. The current code is hardcoded to 3/day (`lib/features/monetization/domain/services/coach_ask_quota.dart:7`), so the observed behavior is a bug to root-cause, not a feature to re-add. The "hit your limit" dialog → paywall path already exists (`lib/features/monetization/presentation/widgets/premium_limit_dialog.dart`) and must be verified to actually fire.
5. **"Narrator" branding leaks into user-facing copy.** The character is the "Coach"; every user-visible string still says "Narrator".
6. **Tutorial spotlight cards cover the element they highlight.** The guide card is pinned to the bottom of the screen (`lib/features/narrator/presentation/widgets/narrator_guide_host.dart:152`) and overlaps targets near the bottom edge (FAB, create button, CTAs).

---

## 2. Goals & Non-Goals

**Goals**
- Every habit with a time lands in an intuitive time-of-day bucket on the timeline; the create screen keeps the existing time picker (no new "time of day" field).
- Users can link a habit to Health Connect steps or a Screen Time limit at creation time.
- Onboarding users choose 1–3 starter habits for their pack.
- Coach asks are exactly 3/day for free users and the limit-hit dialog routes to the paywall.
- All user-facing "Narrator" copy reads "Coach".
- Guide cards never cover the element they are explaining.

**Non-Goals**
- No data migration: legacy habits sort correctly at display time.
- No changes to the auto-complete *engine* semantics (steps `>=` target, screen-time `>=` target) — only its inputs become reachable from the UI.
- No internal code rename (`narrator_*` identifiers, folders, generated files stay).
- No change to the onboarding "Skip" flow.
- No new integrations beyond Steps and Screen Time.

---

## 3. Section 1 — Time-of-Day Buckets & Timeline Names

### 3.1 Pure slot mapping

New pure module `lib/features/habits/domain/services/habit_time_slots.dart` (unit-testable without Firebase, mirroring `decideRedirect`).

```dart
enum TimelineSlot { morning, afternoon, evening, beforeBed }

TimelineSlot timelineSlotFor(TimeOfDay? time);
```

- `4:00–11:59` → `morning`
- `12:00–16:59` → `afternoon`
- `17:00–20:59` → `evening`
- `21:00–3:59` → `beforeBed`
- `null` (no time) → `beforeBed`

A second pure helper maps a `StarterHabitBlueprint.shortCue` to a slot via a keyword table:

```dart
TimelineSlot timelineSlotForCue(String shortCue);
```

- `wake/breakfast/coffee/morning/shower/sunrise` → `morning`
- `lunch/noon/midday/afternoon` → `afternoon`
- `work/dinner/evening/commute` → `evening`
- `bed/night/reflection/journal/relax` → `beforeBed`
- no keyword → `morning`

### 3.2 `Habit.timelineSection`

Change `Habit.timelineSection` (`lib/features/habits/domain/entities/habit.dart:357`) resolution to:

1. `timeOfDayPreference` if set (stored, authoritative);
2. else `timelineSlotFor(reminderTime)` if `reminderTime` is set (legacy habits with a clock time);
3. else `timelineSlotFor(null)` = `beforeBed` (legacy habits with neither).

This gives correct buckets for all existing rows with **zero migration**.

### 3.3 Create habit persists the slot

In `_createHabit` (`lib/features/habits/presentation/screens/habit_create_screen.dart:659`) set:

```dart
timeOfDayPreference: timeOfDayPreferenceFrom(timelineSlotFor(form.reminderTime ?? defaults.time))
```

where `timeOfDayPreferenceFrom` maps the slot back onto the existing `TimeOfDayPreference` enum (`morning` → `morning`, `afternoon` → `afternoon`, `evening` → `evening`, `beforeBed` → `anytime`). The `TimeOfDayPreference` enum and the Drift schema stay untouched; `anytime` is repurposed internally as the rest/before-bed slot. The time picker and its `updateTime` flow are unchanged.

### 3.4 Starter pack persists the slot

`createStarterPack` (`lib/core/drift_repositories/drift_habit_repository.dart:705`) sets `timeOfDayPreference` from `timelineSlotForCue(blueprint.shortCue)` for each blueprint.

### 3.5 Timeline section titles

Update `_categoryTitle` in `lib/features/timeline/presentation/widgets/habit_timeline_section.dart:179`:

| Internal slot | Title |
|---|---|
| `morning` | **After I Wake Up** |
| `afternoon` | **During Lunch** |
| `evening` | **After Work** |
| `anytime` | **Before Bed** |

Keep the slot keys (`morning/afternoon/evening/anytime`) and their order in `HierarchicalHabitTimeline` (`habit_timeline_section.dart:87`) and `_groupHabitsByTimeOfDay` (`timeline_screen.dart:248`); only the displayed titles change.

---

## 4. Section 2 — Create-Habit Integrations

### 4.1 Form state

Extend `HabitFormData` (`lib/features/habits/presentation/screens/habit_create_screen.dart:28`) and `HabitCreateState` with:

- `HabitIntegrationType integrationType` (default `none`)
- `int? integrationTarget`
- copyWith/update methods (`updateIntegration`, `updateIntegrationTarget`)

### 4.2 UI

- Add a pill to the secondary pills row: **"NO INTEGRATION"** (or the active integration label + target).
- Tapping it opens a glass sheet (`_GlassSheet`):
  - **No integration** — clears target.
  - **Health Steps** — numeric target input (steps, default 10,000).
  - **Screen Time Limit** — numeric target input (minutes, default 30).
- When Steps or Screen Time is selected and the matching connection flag (`userSettings.healthKitConnected` / `screenTimeConnected`) is false, show an inline hint: "Not connected — connect in Settings" with an action that opens Settings.
- When a `HabitTemplate` carrying `integrationType`/`integrationTarget` is chosen from the action sheet, prefill the form from it.

### 4.3 Persistence

`_createHabit` passes `integrationType` and `integrationTarget` into the constructed `Habit`. No repository/Drift/sync changes — all already persist and sync these fields (`drift_habit_repository.dart:98-99,654-675`; `health_auto_complete_service.dart` reads them).

---

## 5. Section 3 — First-Habits Screen Multi-Select

### 5.1 Selection state

`_FirstHabitsScreenState` holds `final Set<String> _selectedIds` (blueprint ids). Each `_BlueprintCard` becomes selectable:

- Tap toggles selection (haptic feedback), shows a check indicator.
- A dedicated customize affordance (chevron) opens the existing `_HabitDetailSheet`.

### 5.2 Detail sheet stops creating directly

Remove the direct `repository.createHabit(...)` call in `_HabitDetailSheetState._save` (`first_habits_screen.dart:454`). The sheet only edits the local blueprint (title/cue), marks it selected, and closes. Pack persistence happens once, on START MY JOURNEY — this prevents double-creation when a customized habit is also part of the pack.

### 5.3 Commit

START MY JOURNEY:
- Enabled only when `_selectedIds.isNotEmpty`.
- Calls `createStarterPack(blueprints: blueprints.where((b) => _selectedIds.contains(b.id)))`.
- "Skip" unchanged (completes milestone, no pack).

---

## 6. Section 4 — Coach

### 6.1 Quota: flat 3/day + verify the dialog gate

- Keep `CoachAskQuota.freeDailyLimit = 3` (`coach_ask_quota.dart:7`). It must not depend on habit count, anywhere.
- Root-cause the reported "8" (systematic-debugging): check stale builds, the `consume()` path (`coach_ask_quota_provider.dart:36`), the narrator-card ask flow (`narrator_card.dart:84`), and whether `canAsk` ever failed to gate. One hypothesis at a time.
- Verify the limit-hit UI actually appears on the 4th free ask and routes to `/paywall` (`premium_limit_dialog.dart:125-129`, invoked from `narrator_card.dart:96`). Fix if the dialog never fires.
- Regression tests:
  - Pure `CoachAskQuota` tests lock `freeDailyLimit == 3`, `remaining`, `canAsk`, rollover.
  - A narrator-card widget test: 4th free ask → dialog shown, no LLM call, paywall navigation.
  - Guard against any future habit-count scaling.

### 6.2 Narrator → Coach, user-facing text only

Sweep every user-visible "Narrator" string to "Coach" while leaving code identifiers, file names, providers, and generated `*.g.dart` untouched. Known sites:

- Settings: "Replay narrator guides" (`settings_screen.dart:363`), section copy.
- Guide scripts: `narrator_guide_registry.dart` copy ("This card is me…" lines).
- Coach card, milestone card, avatar tooltip, ask copy (`narrator_card.dart`, `narrator_milestone_card.dart`, `narrator_avatar.dart`).
- Paywall offer copy, coach-ask limit dialog copy (already "coach").
- Notification/copy strings mentioning "narrator".
- Tests asserting user-facing copy must be updated to "Coach".

### 6.3 Spotlight card never covers the target

The guide card is `Positioned(bottom: 24 + safePadding)` (`narrator_guide_host.dart:152`). Introduce a pure layout helper:

```dart
// narrator_guide_host.dart (or a small pure module)
enum GuideCardPlacement { above, below, bottom, top }
GuideCardPlacement guideCardPlacementFor({
  required Rect targetRect,
  required Size screenSize,
  required double cardHeight,
  required double margin,
});
```

- If `targetRect.top - cardHeight - margin >= safeTop` → place **above** the target.
- Else if `targetRect.bottom + cardHeight + margin <= screenSize.height` → place **below** the target.
- Else fall back to bottom (or top) pinned, whichever hides less of the hole.
- The host uses the resolved placement to compute the card's `top`/`bottom` instead of a fixed bottom.
- Optionally inset the spotlight hole slightly so the highlighted element reads as "free" even in tight fallback cases.

Unit tests cover: target high on screen → above; target low → below when space exists; target low and screen full → fallback that keeps the hole visible.

---

## 7. Architecture & Data Flow

- **Pure logic** lives in domain services/helpers (`habit_time_slots.dart`, the placement helper, `CoachAskQuota`) and is unit-tested directly — the project's signature pattern (see `decideRedirect`/`RedirectContext`).
- **Presentation** (create form, first-habits selection, guide positioning, copy) consumes the pure logic.
- **Persistence** requires no schema change: `timeOfDayPreference`, `integrationType`, `integrationTarget` columns already exist in Drift and sync to Firestore.

```
Create screen ──time picker──▶ timelineSlotFor() ──▶ timeOfDayPreference
Starter pack ──shortCue──────▶ timelineSlotForCue() ─▶ timeOfDayPreference
Create screen ──integration sheet──▶ integrationType + integrationTarget ──▶ Drift/Firestore
HealthAutoCompleteService ◀──(reads persisted fields)── auto-complete habits
Timeline ── timelineSection ──▶ slot titles ("After I Wake Up" …)
Guide host ── placement helper ──▶ card never covers the hole
```

---

## 8. Testing Strategy

- **TDD (Iron Law):** failing test first for each pure function and each behavior change.
- `test/features/habits/domain/...`: `timelineSlotFor`, `timelineSlotForCue`, `Habit.timelineSection` fallback chain.
- `test/features/timeline/...`: section titles, grouping under the new names.
- `test/features/habits/presentation/...`: create-screen persists slot + integration fields; first-habits screen selection gating; detail sheet no longer creates.
- `test/features/monetization/...`: `CoachAskQuota` flat-3 regression; narrator-card dialog gate on the 4th ask.
- `test/features/narrator/...` (copy): updated strings; `narrator_guide_host` placement helper cases.
- Focused tests only; never the full suite during development.

## 9. Files Touched (primary)

- `lib/features/habits/domain/services/habit_time_slots.dart` (new)
- `lib/features/habits/domain/entities/habit.dart`
- `lib/features/habits/presentation/screens/habit_create_screen.dart`
- `lib/features/habits/presentation/screens/habit_create_screen.g.dart` (regenerated)
- `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`
- `lib/features/onboarding/presentation/screens/first_habits_screen.dart`
- `lib/core/drift_repositories/drift_habit_repository.dart`
- `lib/features/monetization/domain/services/coach_ask_quota.dart` (tests only)
- `lib/features/monetization/presentation/providers/coach_ask_quota_provider.dart`
- `lib/features/narrator/presentation/widgets/narrator_guide_host.dart`
- User-facing copy across `settings_screen.dart`, `narrator_guide_registry.dart`, `narrator_card.dart`, `narrator_milestone_card.dart`, `narrator_avatar.dart`, paywall/notifications.
- Mirrored test files under `test/`.

## 10. Out of Scope

- Internal narrator→coach code rename (separate future task).
- Auto-complete engine semantics changes.
- Health Connect / Screen Time platform permission code changes.
- Data migration of existing rows.
