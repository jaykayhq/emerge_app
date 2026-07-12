# Habit Widget Rebuild — Timeline Row + Per-Habit Reflection

## Problem

The timeline habit row (`_IndentedHabitItem` in `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`) is too dense: inline 2-minute drawer, inline expand toggle, inline reward chip, swipe-to-complete, swipe-to-delete, attribute badge, and rune indicator all compete for the same 48dp row.

Editing any habit currently requires navigating to a full-screen detail page (`habit_detail_screen.dart`, route `/timeline/detail/:habitId`), which fragments the flow. The reflection widget (`TimelineReflectionCard`) is global (one-per-day) and lives at the bottom of the timeline — there's no way to reflect on a specific habit.

We want the habit row to be **simple and icon-driven**, the **detail screen gone**, and a **per-habit reflection** available right where the user is thinking about that habit.

## Goals

- Reduce the habit row to four explicit affordances: **body tap → World Map**, **checkbox tap → instant complete**, **⏱️ tap → modal timer**, **⋮ tap → bottom sheet**.
- Move all habit editing and per-habit actions into a modal bottom sheet with five sections: **Start Timer, Environment Priming, Set Reward, Log Reflection, Delete Habit**.
- Add **per-habit reflections** (mood + 140-char note) — one per `(userId, habitId, localDate)` — independent of the existing daily global reflection.
- Replace the inline 2-minute countdown pill with a **modal timer dialog** (existing `TwoMinuteTimerDialog`) + **card progress fill** that visually represents the timer running.
- Delete `habit_detail_screen.dart` and the `/timeline/detail/:habitId` route.

## Non-Goals (v1)

- Timer state persistence across app kills
- Reflection cleanup when a habit is deleted (orphan rows allowed; v1.1 follow-up)
- Editing Health Integration, Anchor Habit, or two-minute rule defaults from the sheet (those lived in `HabitDetailScreen` and are not surfaced in the new UI; follow-up)
- Reordering habits via long-press drag (unchanged)

---

## UX — Timeline Habit Row (Layout B)

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─── body zone ────┐ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │   Morning Med.   │ │  ☐  │ │ ⏱️  │ │  ⋮  │                │
│ └──────────────────┘ └─────┘ └─────┘ └─────┘                │
└─────────────────────────────────────────────────────────────┘
   GestureDetector   IconButton  IconButton IconButton
   (→ /)             (toggle)   (modal)   (sheet)
```

**Tap zones** (siblings in a `Row`; no nested gesture conflicts):

| Zone | Action |
|---|---|
| Body (title + connector) | `context.go('/')` — push to World Map |
| Checkbox | Toggle complete via `completeHabitProvider(habit.id)` (existing) |
| ⏱️ | Open `TwoMinuteTimerDialog` for duration + Start |
| ⋮ | Open `HabitOptionsSheet(habit)` modal bottom sheet |

**No `Dismissible` wrapper.** Swipe gestures are removed entirely.

### Card progress fill

- Default: `LinearGradient(stops: [0, 0])` — no fill, plain card.
- **Timer running:** `stops: [progress, progress]` where `progress = 1 - (remainingSeconds / totalSeconds)`. Ticks linearly each second.
- **Checkbox instant complete:** animate `progress: current → 1.0` over 250ms (`Curves.easeOut`). Draw ✓ + strikethrough title + xp badge.
- **Timer reaches 0:** same as instant complete — auto-fires `onCheckboxTap`.
- **Undo via checkbox on completed habit:** progress animates back to 0 over 200ms.

The fill color is `attributeColor(habit.attribute).withValues(alpha: 0.35)`; unfilled portion stays at `Colors.white.withValues(alpha: 0.06)`.

Pure logic extracted to `habitCardFillFraction({required int remainingSeconds, required int totalSeconds}) → double` in `lib/features/timeline/presentation/widgets/habit_progress_math.dart`, unit-tested directly.

---

## UX — Bottom Sheet (`HabitOptionsSheet`)

Modal bottom sheet, `isScrollControlled: true`, `DraggableScrollableSheet` so it grows to ~90% screen height. Sections, top → bottom:

```
┌──────────────────────────────────────┐
│  Morning Meditation            ✕     │
├──────────────────────────────────────┤
│  ▶  Start Timer                      │
├──────────────────────────────────────┤
│  ENVIRONMENT PRIMING                 │
│    □ Lay out gym clothes      ✕      │
│    □ Pack water bottle        ✕      │
│    [+ Add step…]                     │
├──────────────────────────────────────┤
│  SET REWARD                          │
│    [ Watch 1 episode ]               │
│    [Check social] [Coffee] [Podcast] │
├──────────────────────────────────────┤
│  LOG REFLECTION                      │
│    😀 😐 😕 ☹️ 😣                    │
│    [ Add a note… (140 chars) ]       │
│                  [ Save Reflection ] │
├──────────────────────────────────────┤
│  🗑️  Delete Habit                    │
└──────────────────────────────────────┘
```

| Section | Behavior |
|---|---|
| **Start Timer** | Opens `TwoMinuteTimerDialog` with new **"Exit & run in background"** button (Q3, user-confirmed). On exit, returns duration; sheet closes; row's inline progress fill takes over. On full wait, dialog's existing `onComplete` auto-fires `completeHabitProvider`. |
| **Environment Priming** | List of `habit.environmentPriming` with ✕ to remove + add input. Each add/remove calls `habitRepository.updateHabit(habit.copyWith(environmentPriming: [...]))`. Empty state: "No priming steps yet. Add one to reduce friction." |
| **Set Reward** | Text field + 4 suggestion chips. On field blur, calls `habitRepository.updateHabit(habit.copyWith(reward: text))`. |
| **Log Reflection** | Reads `habitReflectionProvider(userId, habitId, date)` for initial mood/note. Mood emoji row (5 options from `Mood.values`) + 140-char note + Save button. Save calls `saveHabitReflectionProvider`. Hint text above mood row if habit not completed today: "Habit not yet completed today." |
| **Delete Habit** | Confirmation `AlertDialog` (reuses `_showDeleteConfirmationDialog` pattern from `habit_detail_screen.dart`). On confirm: `habitRepository.deleteHabit(habit.id)` + `notificationServiceProvider.cancelHabitNotifications(habit.id)`. Sheet closes; `habitsProvider` rebuilds. |

Edits to priming and reward auto-save on each mutation (add, remove, field blur) — there is no explicit "Save" button for those sections. The sheet close path (tap outside, drag down, or tap ✕) does **not** need to flush pending changes because each mutation is already persisted.

---

## Timer Dialog — New Behavior

`TwoMinuteTimerDialog` (`lib/features/habits/presentation/widgets/habit_timer_dialog.dart`) gets one new affordance: an **"Exit & run in background"** button alongside the existing flow.

- On **Exit**: dialog returns the chosen duration (1/2/5/10 min) without auto-completing. Caller (sheet or row) starts the inline countdown in the row.
- On **Wait inside dialog (unchanged)**: timer counts down; `onComplete` fires `completeHabitProvider(habit.id)` and pops.

The dialog's existing API stays compatible — `onComplete` is still a callback. The caller decides whether to invoke `completeHabitProvider` immediately (full-wait path) or pass the duration back to the row (exit path).

---

## Data Model — Per-Habit Reflection

### New entity

```dart
// lib/features/reflections/domain/entities/habit_reflection.dart
class HabitReflection extends Equatable {
  final String id;
  final String userId;
  final String habitId;          // NEW vs DailyReflection
  final DateTime localDate;
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### New drift table

`habit_reflections` — columns `id`, `userId`, `habitId`, `localDate` (date-only), `mood` (int), `note`, `createdAt`, `updatedAt`. Unique index on `(userId, habitId, localDate)`. Mirrors `daily_reflections_table` exactly.

### Schema migration

Increment `schemaVersion` in `app_database.dart`. `onUpgrade` calls `m.createTable(db.habitReflectionsTable)`. Existing tables and data preserved.

### Local DAO

`HabitReflectionsDao` (`lib/core/drift/daos/habit_reflections_dao.dart`):
- `getByDate(userId, habitId, localDate) → Future<HabitReflectionsTableData?>`
- `upsert(userId, habitId, localDate, mood, note) → Future<void>`
- `watchForHabit(userId, habitId, fromDate, toDate) → Stream<List<HabitReflectionsTableData>>`

### Remote datasource

`HabitReflectionRemoteDatasource` mirrors `ReflectionRemoteDatasource`. Writes to `users/{uid}/habit_reflections/{autoId}` with fields `{userId, habitId, localDate, mood, note, updatedAt}`. Uses `fake_cloud_firestore` for tests.

### Repository

```dart
class HabitReflectionRepository {
  Future<Either<Failure, HabitReflection?>> getForHabit({
    required String userId,
    required String habitId,
    required DateTime localDate,
  });
  Future<Either<Failure, HabitReflection>> save({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  });
}
```

Local drift is source of truth. Remote write is `unawaited(...)` — failure is logged, not thrown.

### Sync integration

`habit_reflections` joins the existing sync queue via `mutation_queue_dao` + `enhancedSyncEngineProvider`. Same FIFO pattern as habits/completions.

---

## Providers (new)

```dart
@riverpod
Future<HabitReflection?> habitReflection(Ref ref, {
  required String userId, required String habitId, required DateTime date,
});

@riverpod
Future<void> saveHabitReflection(Ref ref, {
  required String userId, required String habitId, required DateTime date,
  required Mood mood, required String note,
});
```

After save, the reflection provider is invalidated so the sheet re-reads.

---

## Files

### New

- `lib/features/reflections/domain/entities/habit_reflection.dart`
- `lib/features/reflections/data/datasources/habit_reflection_local_datasource.dart`
- `lib/features/reflections/data/datasources/habit_reflection_remote_datasource.dart`
- `lib/features/reflections/data/repositories/habit_reflection_repository.dart`
- `lib/features/reflections/presentation/providers/habit_reflection_providers.dart`
- `lib/features/reflections/presentation/widgets/habit_options_sheet.dart`
- `lib/core/drift/daos/habit_reflections_dao.dart`
- `lib/features/timeline/presentation/widgets/habit_progress_math.dart` (pure helper)

### Modified

- `lib/core/drift/app_database.dart` — add `habit_reflections` table, bump `schemaVersion`, add migration
- `lib/features/timeline/presentation/widgets/habit_timeline_section.dart` — rewrite `_IndentedHabitItem`; add new `onRowBodyTap` / `onCheckboxTap` / `onTimerTap` / `onMenuTap` / `onTimerStart(minutes)` callbacks; remove `Dismissible`, inline expand, inline reward chip, inline countdown state
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — update callback wiring (`onHabitTap` → navigate to `/`; `onHabitToggle` → toggle; remove `onHabitDelete` from timeline — delete lives in sheet)
- `lib/core/router/router.dart` — drop the `/timeline/detail/:habitId` route + import of `habit_detail_screen.dart`
- `lib/features/habits/presentation/widgets/habit_timer_dialog.dart` — add **"Exit & run in background"** button; on tap, return chosen duration without auto-completing

### Deleted

- `lib/features/habits/presentation/screens/habit_detail_screen.dart`

---

## Testing Strategy

### Pure logic

`test/features/timeline/presentation/widgets/habit_progress_math_test.dart`
- `habitCardFillFraction` — total=0, remaining>total, halfway, complete, negative edge, clamp boundaries

### Repositories

`test/features/reflections/data/repositories/habit_reflection_repository_test.dart`
- `getForHabit` — returns existing; null when none; `Left(CacheFailure)` on local error
- `save` — upserts and returns updated; remote failure is silent

`test/features/reflections/data/datasources/habit_reflection_remote_datasource_test.dart`
- writes to `users/{uid}/habit_reflections/{autoId}` with correct fields (uses `fake_cloud_firestore`)

### Drift DAO

`test/core/drift/daos/habit_reflections_dao_test.dart`
- `getByDate` — row when exists; null otherwise; time component of `localDate` ignored
- `upsert` — inserts new; updates existing on same `(userId, habitId, day)`
- Unique index enforced (second insert updates, doesn't duplicate)
- `watchForHabit` — emits on insert + update + delete

### Providers

`test/features/reflections/presentation/providers/habit_reflection_providers_test.dart`
- `habitReflectionProvider` — loads from repo; loading / error / empty states
- After `saveHabitReflectionProvider` — invalidates + re-reads; returns new value

### Widgets

`test/features/timeline/presentation/widgets/habit_timeline_section_test.dart` (rewrite)
- Layout B render — row contains title, checkbox, ⏱️, ⋮
- Tap body zone → `onRowBodyTap` fires once; doesn't fire checkbox/timer/menu
- Tap checkbox → `onCheckboxTap` fires; doesn't fire body tap
- Tap ⏱️ → `onTimerTap` fires; doesn't fire body tap
- Tap ⋮ → `onMenuTap` fires; doesn't fire body tap
- Timer running: `_progress` increments each second
- Timer reaches 0 → `onCheckboxTap` called automatically
- Undo via checkbox → progress returns to 0
- Assert widget is NOT a `Dismissible`

`test/features/reflections/presentation/widgets/habit_options_sheet_test.dart` (new)
- Renders all sections (Start Timer, Environment Priming, Set Reward, Log Reflection, Delete)
- Add priming rule → `updateHabit` called with appended list; new rule visible
- Remove priming rule → `updateHabit` called with filtered list
- Change reward → on blur, `updateHabit` called
- Pick mood + type note + Save → `saveHabitReflectionProvider` called with right args
- Delete habit → confirm dialog → on confirm, `deleteHabit` called + notifications cancelled
- Sheet closes on tap outside (modal default)
- Loading state shows `LinearProgressIndicator`
- Error state shows retry

### Router

`test/core/router/router_redirect_test.dart` (extend existing)
- `/timeline/detail/:habitId` no longer matches any route
- All existing redirect tests still pass

### Migration

`test/core/drift/database_migration_test.dart` (new)
- Start at `schemaVersion=N` → migrate to `N+1` → `habit_reflections` table exists and is queryable
- Existing tables (habits, daily_reflections) intact; data preserved

---

## Verification Commands

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All three must be clean before claiming "done". Any failure → root-cause fix per AGENTS.md systematic-debugging rule.

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Tap-zone overlap / accidental World Map navigation when user meant to complete | Each action is a separate `IconButton` or wrapped `GestureDetector` with `HitTestBehavior.opaque`; body zone excludes icons |
| Timer running when user navigates away | Acceptable v1 limitation; timer state resets on return. Documented in spec. |
| Drift migration on existing devices | Tested via `database_migration_test.dart`; `onUpgrade` is additive (new table only) — no data loss |
| Sync failure leaves local-only per-habit reflection | Same fire-and-forget pattern as `DailyReflection`; local is source of truth; retry happens on next mutation_queue flush |
| Sheet height on small phones | `DraggableScrollableSheet` with `initialChildSize: 0.9`, `minChildSize: 0.5`, `maxChildSize: 0.95` |
| Orphan `habit_reflections` rows after habit delete | Out of scope v1; flagged follow-up |

---

## Decisions Log

| Q | Decision | Rationale |
|---|---|---|
| Layout | **B** — `[title] [☐] [⏱️] [⋮]` | User pick; keeps checkbox + timer grouped, ⋮ at far right edge |
| Reflection type | **Per-habit** (new table) | User pick; daily global reflection stays for top-of-day vibe check |
| Detail screen | **Delete entirely** | User pick; all editing moves to sheet |
| Menu UI | **Modal bottom sheet** | Best fit for 4 sections with inline editing |
| Swipe gestures | **Remove** | User pick; explicit icons replace hidden gestures |
| Timer UX | **Modal first** | User pick; reuses existing `TwoMinuteTimerDialog` |
| Per-habit reflection storage | **New `habit_reflections` table** (Q1=A) | Mirrors existing per-day pattern; clean separation |
| Timer dialog | **"Exit & run in background"** added (Q3) | User pick; gives flexibility — set timer and let row fill, or wait in modal |
