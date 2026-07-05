# Narrator, Onboarding & Timeline Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the always-on narrator and overloaded timeline with a quiet-companion narrator, an inline reflection widget, and a faster Future Self Studio, while keeping the existing 5-milestone onboarding structure.

**Architecture:** Introduce a `NarratorLine` sealed class (generic vs. personal) resolved by a single `NarratorLineResolver` service. Replace the typewriter-based `NarratorSheet` with instant text + an avatar widget (44 dp top-right) and a slide-up `NarratorMilestoneCard`. Add a new `reflections/` feature with a `daily_reflections` drift table for the inline mood+note widget on the timeline. Cap Future Self Studio animations to Material 3 (150–550 ms). All changes are non-destructive to existing data.

**Tech Stack:** Flutter 3.x, Dart 3.10+, Riverpod 3.x (annotation), drift, fpdart, fake_cloud_firestore, mocktail.

**Spec:** `docs/superpowers/specs/2026-07-05-narrator-onboarding-timeline-redesign-design.md`

**Plan structure:** 4 phases. Each phase produces working, testable software and can be executed standalone.

---

## File structure

### New files

| Path | Responsibility |
|------|----------------|
| `lib/features/narrator/domain/models/narrator_line.dart` | Sealed `NarratorLine` (GenericLine, PersonalLine). |
| `lib/features/narrator/domain/services/narrator_line_resolver.dart` | Single entry point that returns a `NarratorLine` for any `(trigger, stats)`. |
| `lib/features/narrator/presentation/widgets/narrator_avatar.dart` | 44 dp persistent avatar with idle pulse + status dot. |
| `lib/features/narrator/presentation/widgets/narrator_milestone_card.dart` | Slide-up milestone card (auto-dismiss 6 s). |
| `lib/features/reflections/domain/entities/mood.dart` | `Mood` enum (terrible=1..great=5). |
| `lib/features/reflections/domain/entities/daily_reflection.dart` | Equatable entity for one day's reflection. |
| `lib/features/reflections/data/datasources/reflection_local_datasource.dart` | drift CRUD on `daily_reflections`. |
| `lib/features/reflections/data/datasources/reflection_remote_datasource.dart` | Firestore mirror writes. |
| `lib/features/reflections/data/repositories/reflection_repository.dart` | `Either<Failure, T>` repo orchestrating local+remote. |
| `lib/features/reflections/presentation/providers/reflection_providers.dart` | Riverpod providers (DAOs, repo, today state). |
| `lib/features/reflections/presentation/providers/reflection_providers.g.dart` | Generated. |
| `lib/features/timeline/presentation/widgets/today_arc_card.dart` | Single hero progress card. |
| `lib/features/timeline/presentation/widgets/timeline_reflection_card.dart` | Inline mood + 1-line note widget. |
| `test/features/narrator/narrator_line_resolver_test.dart` | Pure-logic resolver tests. |
| `test/features/narrator/narrator_trigger_engine_test.dart` | Update existing or create — covers 9 triggers. |
| `test/features/reflections/daily_reflection_test.dart` | Entity equality + Mood mapping. |
| `test/features/reflections/reflection_repository_test.dart` | Repo orchestration with fakes. |
| `test/features/timeline/today_arc_card_test.dart` | Widget test with mock stats. |
| `test/features/timeline/timeline_reflection_card_test.dart` | Save / collapse / re-edit flow. |
| `test/features/narrator/narrator_avatar_test.dart` | Idle / pending / tap. |
| `test/features/narrator/narrator_milestone_card_test.dart` | Auto-dismiss / swipe / kind badge. |

### Modified files

| Path | Change |
|------|--------|
| `lib/features/narrator/domain/models/narrator_appearance.dart` | Remove `hasTextField`, add `line` (`NarratorLine`). |
| `lib/features/narrator/domain/models/narrator_trigger.dart` | Remove `dailyInsight`, `newHabitCreation`, `screenFirstVisit`, `nodeFirstVisit`. |
| `lib/features/narrator/domain/services/narrator_trigger_engine.dart` | Drop checks for removed triggers; update tests. |
| `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | No typewriter; reads `appearance.line`. |
| `lib/features/narrator/presentation/providers/narrator_providers.dart` | Add `lineResolverProvider`, `pendingMilestoneProvider`. |
| `lib/features/timeline/presentation/screens/timeline_screen.dart` | Remove 6 widgets; add `NarratorAvatar`, `TodayArcCard`, `NarratorMilestoneCard` host, `TimelineReflectionCard`; move overflow actions to ⋯ menu. |
| `lib/features/onboarding/presentation/screens/welcome_screen.dart` | Add step indicator ("Step 1 of 5"). |
| `lib/features/onboarding/presentation/screens/identity_studio_screen.dart` | Remove `NarratorSheet.show` after archetype; move "Write your own" motive CTA above presets; add Skip; add step indicator. |
| `lib/features/onboarding/presentation/screens/first_habit_screen.dart` | Add step indicator; add Skip. |
| `lib/features/onboarding/presentation/screens/world_reveal_screen.dart` | Add step indicator; remove any narrator sheets. |
| `lib/features/onboarding/presentation/screens/creator_onboarding/*` | Remove any narrator sheets mid-flow. |
| `lib/features/profile/presentation/screens/future_self_studio_screen.dart` | Remove `screenFirstVisit` typewriter; cap animation durations 150–550 ms; wrap animated subtrees in `RepaintBoundary`; lazy-load avatar renderer; replace large-area `BackdropFilter` with cached blur. |
| `lib/features/profile/presentation/widgets/evolving_silhouette_widget.dart` | Cap animation durations. |
| `lib/features/profile/presentation/widgets/stickman_avatar.dart` | Cap animation durations. |
| `lib/features/profile/presentation/widgets/synergy_card.dart` | Cap animation durations. |
| `lib/features/profile/presentation/widgets/decay_recovery_overlay.dart` | Cap animation durations. |
| `lib/features/ai/presentation/screens/ai_reflections_screen.dart` | Remove `screenFirstVisit` NarratorSheet call. |
| `lib/features/gamification/presentation/screens/leveling_screen.dart` | Remove `screenFirstVisit` NarratorSheet call. |
| `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart` | Remove `screenFirstVisit` NarratorSheet call. |
| `lib/features/habits/data/services/habit_completion_service.dart` | Drop `newHabitCreation` trigger; keep `streakBreakFirstMiss`, `onFireState`. |
| `lib/core/drift/drift_native.dart` | Add `DailyReflections` table; bump schema version; add migration `onUpgrade` step. |

### Deleted files

| Path | Reason |
|------|--------|
| `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` | Replaced by instant text. |

---

# Phase 1 — Narrator core (no UI yet)

> Goal: narrator backend produces `NarratorLine`s and the sheet renders them instantly. No new widgets on screen yet. Phase 1 produces a working narrator with no typewriter, ready for UI integration in Phase 2.

## Task 1: `NarratorLine` sealed class + tests

**Files:**
- Create: `lib/features/narrator/domain/models/narrator_line.dart`
- Create: `test/features/narrator/narrator_line_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/narrator/narrator_line_test.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorLine', () {
    test('GenericLine carries only text', () {
      const line = GenericLine('Nice work — 3 days in a row!');
      expect(line.text, 'Nice work — 3 days in a row!');
      expect(line, isA<GenericLine>());
    });

    test('PersonalLine carries text and dataBasis', () {
      const line = PersonalLine(
        text: 'Tuesday is your strongest day — 6 weeks in a row.',
        dataBasis: 'Tuesday 6-week streak',
      );
      expect(line.text, contains('Tuesday'));
      expect(line.dataBasis, 'Tuesday 6-week streak');
      expect(line, isA<PersonalLine>());
    });

    test('pattern match is exhaustive', () {
      const NarratorLine line = GenericLine('hi');
      final kind = switch (line) {
        GenericLine() => 'generic',
        PersonalLine() => 'personal',
      };
      expect(kind, 'generic');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/narrator_line_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:emerge_app/features/narrator/domain/models/narrator_line.dart'"

- [ ] **Step 3: Implement the model**

`lib/features/narrator/domain/models/narrator_line.dart`:

```dart
/// A line of narrator text.
///
/// [GenericLine] is pre-written copy shown to all users (free tier).
/// [PersonalLine] is data-grounded copy shown to Pro users.
sealed class NarratorLine {
  const NarratorLine();
}

class GenericLine extends NarratorLine {
  final String text;
  const GenericLine(this.text);
}

class PersonalLine extends NarratorLine {
  final String text;
  final String dataBasis;

  const PersonalLine({required this.text, required this.dataBasis});
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/narrator_line_test.dart`
Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain/models/narrator_line.dart test/features/narrator/narrator_line_test.dart
git commit -m "feat(narrator): add NarratorLine sealed class (GenericLine, PersonalLine)"
```

---

## Task 2: `Mood` enum + `DailyReflection` entity + tests

**Files:**
- Create: `lib/features/reflections/domain/entities/mood.dart`
- Create: `lib/features/reflections/domain/entities/daily_reflection.dart`
- Create: `test/features/reflections/daily_reflection_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/reflections/daily_reflection_test.dart`:

```dart
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mood', () {
    test('int values are 1..5 in order', () {
      expect(Mood.terrible.value, 1);
      expect(Mood.meh.value, 2);
      expect(Mood.ok.value, 3);
      expect(Mood.good.value, 4);
      expect(Mood.great.value, 5);
    });

    test('fromInt round-trips', () {
      for (final m in Mood.values) {
        expect(Mood.fromInt(m.value), m);
      }
    });
  });

  group('DailyReflection', () {
    test('equality is value-based', () {
      final a = DailyReflection(
        id: 'r1',
        userId: 'u1',
        localDate: DateTime(2026, 7, 5),
        mood: Mood.ok,
        note: 'good day',
        createdAt: DateTime(2026, 7, 5, 9),
        updatedAt: DateTime(2026, 7, 5, 9),
      );
      final b = a.copyWith();
      expect(a, equals(b));
    });

    test('moodEmoji returns expected emoji', () {
      expect(Mood.great.emoji, '🔥');
      expect(Mood.terrible.emoji, '😞');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reflections/daily_reflection_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Implement Mood enum**

`lib/features/reflections/domain/entities/mood.dart`:

```dart
enum Mood {
  terrible(1, '😞'),
  meh(2, '😐'),
  ok(3, '🙂'),
  good(4, '😊'),
  great(5, '🔥');

  final int value;
  final String emoji;
  const Mood(this.value, this.emoji);

  static Mood fromInt(int value) =>
      Mood.values.firstWhere((m) => m.value == value, orElse: () => Mood.ok);
}
```

- [ ] **Step 4: Implement DailyReflection entity**

`lib/features/reflections/domain/entities/daily_reflection.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'mood.dart';

class DailyReflection extends Equatable {
  final String id;
  final String userId;
  final DateTime localDate;
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyReflection({
    required this.id,
    required this.userId,
    required this.localDate,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyReflection copyWith({
    Mood? mood,
    String? note,
    DateTime? updatedAt,
  }) {
    return DailyReflection(
      id: id,
      userId: userId,
      localDate: localDate,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, localDate, mood, note, createdAt, updatedAt];
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/reflections/daily_reflection_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reflections/domain test/features/reflections/daily_reflection_test.dart
git commit -m "feat(reflections): add Mood enum and DailyReflection entity"
```

---

## Task 3: `daily_reflections` drift table + migration

**Files:**
- Modify: `lib/core/drift/drift_native.dart` — add table + bump schema version
- Modify: `lib/core/drift/drift_web.dart` — same table on web (no migration needed; share model)

- [ ] **Step 1: Read current schema version**

Run: `grep -n "schemaVersion\|MigrationStrategy\|onUpgrade" lib/core/drift/drift_native.dart`

Note the current schemaVersion. Use that as `currentVersion` below.

- [ ] **Step 2: Read `drift_native.dart` to find table declarations**

Read `lib/core/drift/drift_native.dart` and locate where existing tables are declared (typically a `List<Table>` passed to `@DriftDatabase`). Add a new file `lib/features/reflections/data/datasources/daily_reflections_table.dart` with the table declaration (kept in the feature folder so the feature owns its schema):

`lib/features/reflections/data/datasources/daily_reflections_table.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

@DataClassName('DailyReflectionRow')
class DailyReflections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get localDate => dateTime()();
  IntColumn get mood => intEnum<Mood>()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 3: Update `drift_native.dart`**

In `lib/core/drift/drift_native.dart`:

- Bump the `@DriftDatabase(tables: [...], schemaVersion: N)` value by 1.
- Add `DailyReflections` to the `tables:` list.
- Add a DAO factory in the existing `AppDatabase` class:
  ```dart
  late final DailyReflectionsDao dailyReflectionsDao = DailyReflectionsDao(this);
  ```
- In the existing `MigrationStrategy` `onUpgrade` callback, add a `case` for the new version that runs `m.createTable(db.dailyReflectionsDao.attachedTable)` (use the actual DAO method — likely `db.dailyReflectionsDao.createTableQuery`).
- Import the new table file at the top.

Exact pattern matches what is already done for `HabitCompletionsDao`. Read the file to mirror its style.

- [ ] **Step 4: Mirror the change in `drift_web.dart`**

In `lib/core/drift/drift_web.dart`, mirror the schema bump and DAO wiring (same table list, same `onUpgrade` step).

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD SUCCESSFUL. New `*.g.dart` files for the table + DAO.

- [ ] **Step 6: Verify schema**

Run: `flutter test test/core/drift/database_smoke_test.dart` (or write one if absent)

If no smoke test exists, create `test/core/drift/daily_reflections_table_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/drift_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppDatabase opens with new schema version', () {
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, greaterThanOrEqualTo(<NEW_VERSION>));
    db.close();
  });
}
```

Run: `flutter test test/core/drift/daily_reflections_table_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/drift lib/features/reflections/data/datasources/daily_reflections_table.dart
git commit -m "feat(reflections): add daily_reflections drift table + migration"
```

---

## Task 4: `DailyReflectionsDao` + tests

**Files:**
- Create: `lib/core/drift/daos/daily_reflections_dao.dart`
- Create: `test/core/drift/daos/daily_reflections_dao_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/drift/daos/daily_reflections_dao_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/drift_native.dart';
import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DailyReflectionsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.dailyReflectionsDao;
  });
  tearDown(() => db.close());

  test('upsert + getByDate round-trip', () async {
    await dao.upsert(
      userId: 'u1',
      localDate: DateTime(2026, 7, 5),
      mood: Mood.good,
      note: 'felt strong',
    );
    final row = await dao.getByDate('u1', DateTime(2026, 7, 5));
    expect(row, isNotNull);
    expect(row!.mood, Mood.good);
    expect(row.note, 'felt strong');
  });

  test('upsert overwrites existing row', () async {
    await dao.upsert(userId: 'u1', localDate: DateTime(2026, 7, 5), mood: Mood.ok, note: 'a');
    await dao.upsert(userId: 'u1', localDate: DateTime(2026, 7, 5), mood: Mood.great, note: 'b');
    final row = await dao.getByDate('u1', DateTime(2026, 7, 5));
    expect(row!.mood, Mood.great);
    expect(row.note, 'b');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/drift/daos/daily_reflections_dao_test.dart`
Expected: FAIL — `DailyReflectionsDao` not found.

- [ ] **Step 3: Implement the DAO**

`lib/core/drift/daos/daily_reflections_dao.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:emerge_app/core/drift/drift_native.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'daily_reflections_dao.g.dart';

@DriftAccessor(tables: [DailyReflections])
class DailyReflectionsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyReflectionsDaoMixin {
  DailyReflectionsDao(super.db);

  Future<DailyReflectionRow?> getByDate(String userId, DateTime localDate) {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    return (select(dailyReflections)
          ..where((t) => t.userId.equals(userId) & t.localDate.equals(day))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsert({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    final existing = await getByDate(userId, day);
    final now = DateTime.now();
    if (existing == null) {
      await into(dailyReflections).insert(
        DailyReflectionsCompanion.insert(
          id: _newId(),
          userId: userId,
          localDate: day,
          mood: mood,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(dailyReflections)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        DailyReflectionsCompanion(
          mood: Value(mood),
          note: Value(note),
          updatedAt: Value(now),
        ),
      );
    }
  }

  String _newId() => '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  static int _counter = 0;
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/drift/daos/daily_reflections_dao_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/core/drift/daos/daily_reflections_dao.dart test/core/drift/daos/daily_reflections_dao_test.dart
git commit -m "feat(reflections): add DailyReflectionsDao with upsert + getByDate"
```

---

## Task 5: `NarratorTrigger` slimming (drop 4 triggers) + tests

**Files:**
- Modify: `lib/features/narrator/domain/models/narrator_trigger.dart`
- Modify: `lib/features/narrator/domain/services/narrator_trigger_engine.dart`
- Modify: `test/features/narrator/narrator_trigger_engine_test.dart` (existing — update if present, else create)

- [ ] **Step 1: Update the trigger enum**

Edit `lib/features/narrator/domain/models/narrator_trigger.dart` — remove these enum values:
- `dailyInsight`
- `newHabitCreation`
- `screenFirstVisit`
- `nodeFirstVisit`

Also remove their cases in `toNoteType()`.

The remaining 9 values are:
- `onboardingPostArchetype`
- `morningBriefEarlyDays`
- `streakBreakFirstMiss`
- `onFireState`
- `levelUp`
- `weeklyRecap`
- `longAbsence`
- `eveningReflection`
- `askNarrator` (new — replaces `screenFirstVisit` for explicit user asks)

Add `askNarrator` with note type `NarratorNoteType.aiInsight`.

- [ ] **Step 2: Update the trigger engine**

Edit `lib/features/narrator/domain/services/narrator_trigger_engine.dart`:

- Remove `_checkScreenFirstVisit`, `_checkNodeFirstVisit` methods.
- Remove `_checkDailyInsight` if present.
- Remove `_excludedScreenFirstVisitRoutes` and `_cooldownExemptTriggers` constants.
- Update `shouldTrigger` candidates list — drop the removed checks.
- Add a public method `NarratorTrigger? resolveAskNarratorTrigger(NarratorUserStats stats, Map<NarratorTrigger, DateTime> recent)` that returns `askNarrator` when the user taps the avatar (no cooldown applies to user-initiated triggers).

- [ ] **Step 3: Update or create the test**

If `test/features/narrator/narrator_trigger_engine_test.dart` doesn't exist, create it. Either way, ensure these tests pass:

```dart
test('removed triggers never fire', () {
  // Construct stats + context that would have fired screenFirstVisit;
  // assert the result is null.
  final stats = NarratorUserStats(
    momentumScore: 0.0, consecutiveActiveDays: 0, totalHabitsToday: 0,
    completedHabitsToday: 0, currentLevel: 1, previousLevel: 1,
    hasStreakBreak: false, currentStreak: 0, longestStreak: 0,
    consecutiveMisses: 0, isFirstVisitToRoute: true, isFirstVisitToNode: true,
    hasCompletedEveningReflectionToday: false, hasCompletedOnboarding: true,
    archetypeSelected: true,
  );
  final ctx = AppOpenContext(
    currentRoute: '/random', now: DateTime.now(),
    isFirstAppOpen: false, daysSinceInstall: 10, daysSinceLastOpen: 1,
  );
  final trigger = NarratorTriggerEngine.shouldTrigger(
    context: ctx, stats: stats, recentTriggers: const {},
  );
  expect(trigger, isNot(NarratorTrigger.screenFirstVisit));
  expect(trigger, isNot(NarratorTrigger.nodeFirstVisit));
});

test('priority order is preserved', () {
  // Long absence beats level up beats streak break ...
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/narrator/narrator_trigger_engine_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain test/features/narrator/narrator_trigger_engine_test.dart
git commit -m "refactor(narrator): drop 4 triggers (dailyInsight, newHabitCreation, screenFirstVisit, nodeFirstVisit); add askNarrator"
```

---

## Task 6: `NarratorLineResolver` + tests

**Files:**
- Create: `lib/features/narrator/domain/services/narrator_line_resolver.dart`
- Create: `test/features/narrator/narrator_line_resolver_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/narrator/narrator_line_resolver_test.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_line_resolver.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeResolver extends NarratorLineResolver {
  _FakeResolver({required this.isPremium});
  final bool isPremium;
  @override
  bool get isPro => isPremium;

  @override
  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    return PersonalLine(text: 'personal: ${trigger.name}', dataBasis: 'fake');
  }

  @override
  GenericLine pickGeneric(NarratorTrigger trigger) =>
      GenericLine('generic: ${trigger.name}');
}

NarratorUserStats _stats() => const NarratorUserStats(
      momentumScore: 0.5,
      consecutiveActiveDays: 1,
      totalHabitsToday: 3,
      completedHabitsToday: 1,
      currentLevel: 1,
      previousLevel: 1,
      hasStreakBreak: false,
      currentStreak: 5,
      longestStreak: 5,
      consecutiveMisses: 0,
      isFirstVisitToRoute: false,
      isFirstVisitToNode: false,
      hasCompletedEveningReflectionToday: false,
      hasCompletedOnboarding: true,
      archetypeSelected: true,
    );

void main() {
  group('NarratorLineResolver', () {
    test('free user gets GenericLine for non-gated trigger', () async {
      final r = _FakeResolver(isPremium: false);
      final line = await r.resolve(trigger: NarratorTrigger.streakBreakFirstMiss, stats: _stats());
      expect(line, isA<GenericLine>());
      expect(line.text, contains('generic'));
    });

    test('pro user gets PersonalLine for non-gated trigger', () async {
      final r = _FakeResolver(isPremium: true);
      final line = await r.resolve(trigger: NarratorTrigger.streakBreakFirstMiss, stats: _stats());
      expect(line, isA<PersonalLine>());
      expect(line.text, contains('personal'));
    });

    test('weeklyRecap returns GatedResult for free user', () async {
      final r = _FakeResolver(isPremium: false);
      final result = await r.resolveGated(trigger: NarratorTrigger.weeklyRecap, stats: _stats());
      expect(result, isA<WeeklyRecapGated>());
    });

    test('weeklyRecap returns line for pro user', () async {
      final r = _FakeResolver(isPremium: true);
      final result = await r.resolveGated(trigger: NarratorTrigger.weeklyRecap, stats: _stats());
      expect(result, isA<PersonalLine>());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/narrator_line_resolver_test.dart`
Expected: FAIL — types don't exist.

- [ ] **Step 3: Implement the resolver**

`lib/features/narrator/domain/services/narrator_line_resolver.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';

/// Result for weeklyRecap: gated (show paywall) or a real line.
sealed class WeeklyRecapResult {
  const WeeklyRecapResult();
}
class WeeklyRecapGated extends WeeklyRecapResult {
  const WeeklyRecapGated();
}
class WeeklyRecapLine extends WeeklyRecapResult {
  final NarratorLine line;
  const WeeklyRecapLine(this.line);
}

/// Resolves a [NarratorTrigger] + [NarratorUserStats] into a [NarratorLine]
/// (or a paywall gate for weeklyRecap on free users).
abstract class NarratorLineResolver {
  bool get isPro;

  /// Resolve a non-gated trigger. Always returns a line.
  Future<NarratorLine> resolve({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    if (isPro) {
      return generatePersonal(trigger: trigger, stats: stats);
    }
    return pickGeneric(trigger);
  }

  /// Resolve weeklyRecap: gated for free users.
  Future<WeeklyRecapResult> resolveGated({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    assert(trigger == NarratorTrigger.weeklyRecap, 'resolveGated only for weeklyRecap');
    if (!isPro) return const WeeklyRecapGated();
    return WeeklyRecapLine(await generatePersonal(trigger: trigger, stats: stats));
  }

  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  });

  GenericLine pickGeneric(NarratorTrigger trigger);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/narrator_line_resolver_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain/services/narrator_line_resolver.dart test/features/narrator/narrator_line_resolver_test.dart
git commit -m "feat(narrator): add NarratorLineResolver with weeklyRecap gating"
```

---

## Task 7: `lineResolverProvider` + Riverpod wiring

**Files:**
- Modify: `lib/features/narrator/presentation/providers/narrator_providers.dart`

- [ ] **Step 1: Add the provider**

Append to `lib/features/narrator/presentation/providers/narrator_providers.dart`:

```dart
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_line_resolver.dart';

/// Concrete resolver implementation backed by [isPremiumProvider] and the LLM.
class LlmNarratorLineResolver implements NarratorLineResolver {
  LlmNarratorLineResolver({required this.isPro, required this.llmGeneratePersonal});

  final bool isPro;
  final Future<PersonalLine> Function(NarratorTrigger, NarratorUserStats) llmGeneratePersonal;

  @override
  bool get isPremium => isPro;

  @override
  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) =>
      llmGeneratePersonal(trigger, stats);

  @override
  GenericLine pickGeneric(NarratorTrigger trigger) {
    // Curated pool — see curated_lines.dart in next task. For now, a fallback.
    return GenericLine(_fallbackFor(trigger));
  }

  String _fallbackFor(NarratorTrigger trigger) => switch (trigger) {
        NarratorTrigger.streakBreakFirstMiss => 'One miss is a slip. Two is a pattern. What got in the way?',
        NarratorTrigger.onFireState => 'You\'re on fire this week.',
        NarratorTrigger.levelUp => 'You leveled up.',
        NarratorTrigger.longAbsence => 'Welcome back. Pick one small habit today.',
        NarratorTrigger.eveningReflection => 'How did today go?',
        NarratorTrigger.morningBriefEarlyDays => 'Small start, big difference.',
        NarratorTrigger.onboardingPostArchetype => 'A path begins.',
        NarratorTrigger.weeklyRecap => 'Your week, in numbers.',
        NarratorTrigger.askNarrator => 'You called — what\'s on your mind?',
      };
}

@Riverpod(keepAlive: true)
NarratorLineResolver lineResolver(Ref ref) {
  final isPremium = ref.watch(isPremiumProvider).value ?? false;
  return LlmNarratorLineResolver(
    isPro: isPremium,
    llmGeneratePersonal: (trigger, stats) async {
      // TODO(task-22): swap stub for real Groq call. For now, return a
      // deterministic PersonalLine referencing the stats.
      return PersonalLine(
        text: '${trigger.name} personal line for momentum=${stats.momentumScore.toStringAsFixed(2)}',
        dataBasis: 'momentumScore',
      );
    },
  );
}

/// Pending narrator line awaiting display in the slide-up card.
@Riverpod
class PendingMilestone extends _$PendingMilestone {
  @override
  NarratorLine? build() => null;

  void set(NarratorLine line) => state = line;
  void clear() => state = null;
}
```

- [ ] **Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Verify the project compiles**

Run: `dart analyze lib/features/narrator`
Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/narrator/presentation/providers/narrator_providers.dart
git commit -m "feat(narrator): add lineResolverProvider + PendingMilestone notifier"
```

---

## Task 8: `NarratorSheet` refactor (no typewriter, reads `NarratorLine`)

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Modify: `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` → delete
- Modify: `lib/features/narrator/domain/models/narrator_appearance.dart`

- [ ] **Step 1: Delete the typewriter file**

```bash
rm lib/features/narrator/presentation/widgets/narrator_typewriter.dart
```

- [ ] **Step 2: Slim down `NarratorAppearance`**

Edit `lib/features/narrator/domain/models/narrator_appearance.dart`:
- Remove `final bool hasTextField;` and its constructor parameter.
- Add `final NarratorLine line;` and require it in the constructor.
- Remove the `TextField` block from the sheet later (Step 4).

- [ ] **Step 3: Update all `NarratorAppearance` constructor calls**

Run: `grep -rn "NarratorAppearance(" lib/`

For each call site:
- Remove any `hasTextField:` parameter.
- Add `line: GenericLine('...')` (or `PersonalLine(...)` if the call site has user stats context).

Common call sites to update:
- `lib/features/timeline/presentation/screens/timeline_screen.dart` — the evening reflection block.
- `lib/features/onboarding/presentation/screens/identity_studio_screen.dart` — post-archetype.
- `lib/features/profile/presentation/screens/future_self_studio_screen.dart` — screenFirstVisit (will be removed in Phase 2).
- `lib/features/ai/presentation/screens/ai_reflections_screen.dart` (will be removed in Phase 2).

- [ ] **Step 4: Refactor `NarratorSheet`**

In `lib/features/narrator/presentation/widgets/narrator_sheet.dart`:

- Remove the `NarratorTypewriter` import + usage. Replace with `Text(appearance.line.text, ...)`.
- Remove the optional text-field block.
- Remove the `_textComplete` state, `_typewriterKey`, and `_entryController`-driven typewriter fade-in. Replace with a single `AnimatedOpacity` from 0 → 1 over 150 ms.
- Remove the skip-typing button.
- Render a "PersonalLine" badge in the top-right of the card when `appearance.line is PersonalLine` (small "DATA-GROUNDED" pill).

The final sheet body:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        NarratorPulseIndicator(color: EmergeColors.teal, size: 20),
        const SizedBox(width: 10),
        Text('EMERGE', style: ...),
        const Spacer(),
        if (widget.appearance.line is PersonalLine)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: EmergeColors.warmGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('DATA-GROUNDED', style: TextStyle(fontSize: 9, color: EmergeColors.warmGold, letterSpacing: 1.5)),
          ),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, color: Colors.white54)),
      ],
    ),
    const SizedBox(height: 16),
    Text(
      widget.appearance.line.text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.6),
    ),
    const SizedBox(height: 20),
    Row(
      children: [
        Expanded(child: _ActionButton(label: widget.appearance.buttonA, color: EmergeColors.teal, onTap: () { widget.onResponse?.call(widget.appearance.buttonA, null); Navigator.of(context).pop(); })),
        const SizedBox(width: 12),
        Expanded(child: _ActionButton(label: widget.appearance.buttonB, color: EmergeColors.violet, onTap: () { widget.onResponse?.call(widget.appearance.buttonB, null); Navigator.of(context).pop(); })),
      ],
    ),
  ],
)
```

Keep `_ActionButton` exactly as-is.

- [ ] **Step 5: Run tests + analyze**

Run: `dart analyze lib/features/narrator`
Expected: 0 errors.

Run: `flutter test test/features/narrator/`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add -A lib/features/narrator test/features/narrator
git commit -m "refactor(narrator): remove typewriter; NarratorSheet renders NarratorLine instantly"
```

---

## Task 9: Delete obsolete narrator call sites (Phase-1 part)

**Files:**
- Modify: `lib/features/ai/presentation/screens/ai_reflections_screen.dart`
- Modify: `lib/features/gamification/presentation/screens/leveling_screen.dart`
- Modify: `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`
- Modify: `lib/features/habits/data/services/habit_completion_service.dart`

- [ ] **Step 1: Remove `screenFirstVisit` calls in 3 screens**

In each of these files, delete:
- The `_checkScreenFirstVisit` helper method (if present).
- The call to it from `initState`.
- The `trigger: NarratorTrigger.screenFirstVisit` `NarratorAppearance` block.
- The corresponding `if (trigger == NarratorTrigger.screenFirstVisit && mounted)` callback branch.
- Unused imports for `narrator_appearance.dart`, `narrator_sheet.dart`, `narrator_trigger.dart`.

In `lib/features/habits/data/services/habit_completion_service.dart`:
- Remove the `NarratorTrigger.newHabitCreation` case (return null for new habits).
- Remove the trigger parameter usage if no longer needed.

- [ ] **Step 2: Run analyze**

Run: `dart analyze lib/`
Expected: 0 errors.

- [ ] **Step 3: Run tests**

Run: `flutter test test/`
Expected: all pass (some may need updates if they tested removed behaviour — fix or delete those tests).

- [ ] **Step 4: Commit**

```bash
git add lib/features/ai lib/features/gamification lib/features/habits
git commit -m "refactor: remove obsolete screenFirstVisit + newHabitCreation narrator calls"
```

**✅ Phase 1 complete.** Working software: narrator backend now produces `NarratorLine`s with free/pro gating, sheet renders instantly. No UI changes on screen yet.

---

# Phase 2 — Narrator UI (avatar + slide-up card on timeline)

> Goal: narrator becomes visible as the persistent avatar on the timeline and as the slide-up milestone card. Phase 2 produces a visible narrator that talks only on milestones.

## Task 10: `NarratorAvatar` widget + tests

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_avatar.dart`
- Create: `test/features/narrator/narrator_avatar_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/narrator/narrator_avatar_test.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('avatar renders in idle state when no pending line', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMilestoneProvider.overrideWith((ref) => _StubNotifier(null)),
        ],
        child: const MaterialApp(home: Scaffold(body: NarratorAvatar())),
      ),
    );
    expect(find.byType(NarratorAvatar), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing); // no close in idle
  });

  testWidgets('avatar shows status dot when pending line exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingMilestoneProvider.overrideWith((ref) => _StubNotifier(const GenericLine('hi'))),
        ],
        child: const MaterialApp(home: Scaffold(body: NarratorAvatar())),
      ),
    );
    await tester.pump();
    expect(find.byType(NarratorAvatar), findsOneWidget);
  });
}

class _StubNotifier extends PendingMilestone {
  _StubNotifier(this._value);
  final NarratorLine? _value;
  @override
  NarratorLine? build() => _value;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/narrator_avatar_test.dart`
Expected: FAIL — `NarratorAvatar` not found.

- [ ] **Step 3: Implement the widget**

`lib/features/narrator/presentation/widgets/narrator_avatar.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 44dp persistent narrator avatar. Idle: subtle pulse.
/// Has-pending-line: green status dot. Tap → opens NarratorSheet via callback.
class NarratorAvatar extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  const NarratorAvatar({super.key, this.onTap});

  @override
  ConsumerState<NarratorAvatar> createState() => _NarratorAvatarState();
}

class _NarratorAvatarState extends ConsumerState<NarratorAvatar>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMilestoneProvider);
    final hasPending = pending != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EmergeColors.violet.withValues(alpha: 0.35),
                    EmergeColors.teal.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [EmergeColors.violet, EmergeColors.teal],
                    ),
                  ),
                  child: const Center(
                    child: Text('✦', style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          if (hasPending)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EmergeColors.teal,
                  boxShadow: [
                    BoxShadow(color: EmergeColors.teal.withValues(alpha: 0.6), blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/narrator_avatar_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_avatar.dart test/features/narrator/narrator_avatar_test.dart
git commit -m "feat(narrator): add NarratorAvatar widget (44dp, pulse, pending dot)"
```

---

## Task 11: `NarratorMilestoneCard` widget + tests

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_milestone_card.dart`
- Create: `test/features/narrator/narrator_milestone_card_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/narrator/narrator_milestone_card_test.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders PersonalLine with dataBasis badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: const PersonalLine(
              text: '14-day streak — Tuesday strongest.',
              dataBasis: 'Tuesday streak',
            ),
            trigger: NarratorTrigger.onFireState,
          ),
        ),
      ),
    );
    expect(find.text('14-day streak — Tuesday strongest.'), findsOneWidget);
    expect(find.text('DATA-GROUNDED'), findsOneWidget);
  });

  testWidgets('auto-dismisses after duration', (tester) async {
    bool dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: const GenericLine('hi'),
            trigger: NarratorTrigger.levelUp,
            autoDismissAfter: const Duration(milliseconds: 100),
            onDismissed: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(dismissed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/narrator/narrator_milestone_card_test.dart`
Expected: FAIL — class not found.

- [ ] **Step 3: Implement the widget**

`lib/features/narrator/presentation/widgets/narrator_milestone_card.dart`:

```dart
import 'dart:async';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:flutter/material.dart';

/// Slide-up milestone card. Non-blocking. Auto-dismisses.
class NarratorMilestoneCard extends StatefulWidget {
  final NarratorLine line;
  final NarratorTrigger trigger;
  final Duration autoDismissAfter;
  final VoidCallback? onDismissed;

  const NarratorMilestoneCard({
    super.key,
    required this.line,
    required this.trigger,
    this.autoDismissAfter = const Duration(seconds: 6),
    this.onDismissed,
  });

  @override
  State<NarratorMilestoneCard> createState() => _NarratorMilestoneCardState();
}

class _NarratorMilestoneCardState extends State<NarratorMilestoneCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoDismissAfter, _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = widget.line is PersonalLine;
    return Dismissible(
      key: ValueKey(widget.line.runtimeType),
      direction: DismissDirection.up,
      onDismissed: (_) => _dismiss(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              EmergeColors.violet.withValues(alpha: 0.95),
              EmergeColors.teal.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(color: EmergeColors.violet.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Center(child: Text('✦', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_labelFor(widget.trigger),
                          style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white70)),
                      const Spacer(),
                      if (isPersonal)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EmergeColors.warmGold.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PERSONAL', style: TextStyle(fontSize: 8, color: EmergeColors.warmGold, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.line.text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Swipe ↑', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  String _labelFor(NarratorTrigger t) => switch (t) {
        NarratorTrigger.onFireState => 'ON FIRE',
        NarratorTrigger.levelUp => 'LEVEL UP',
        NarratorTrigger.streakBreakFirstMiss => 'STREAK',
        NarratorTrigger.longAbsence => 'WELCOME BACK',
        NarratorTrigger.weeklyRecap => 'WEEKLY RECAP',
        NarratorTrigger.morningBriefEarlyDays => 'GOOD MORNING',
        NarratorTrigger.eveningReflection => 'EVENING',
        NarratorTrigger.onboardingPostArchetype => 'WELCOME',
        NarratorTrigger.askNarrator => 'YOU ASKED',
      };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/narrator/narrator_milestone_card_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_milestone_card.dart test/features/narrator/narrator_milestone_card_test.dart
git commit -m "feat(narrator): add NarratorMilestoneCard (slide-up, auto-dismiss 6s, swipeable)"
```

---

## Task 12: `TodayArcCard` widget + tests

**Files:**
- Create: `lib/features/timeline/presentation/widgets/today_arc_card.dart`
- Create: `test/features/timeline/today_arc_card_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/timeline/today_arc_card_test.dart`:

```dart
import 'package:emerge_app/features/timeline/presentation/widgets/today_arc_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders percent + remaining count', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TodayArcCard(completed: 4, total: 6, streakDays: 12)),
    ));
    expect(find.textContaining('67%'), findsOneWidget);
    expect(find.textContaining('2'), findsOneWidget); // "2 habits left"
  });

  testWidgets('renders "Start your streak" when no streak', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TodayArcCard(completed: 0, total: 0, streakDays: 0)),
    ));
    expect(find.textContaining('Start'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/timeline/today_arc_card_test.dart`
Expected: FAIL — class not found.

- [ ] **Step 3: Implement the widget**

`lib/features/timeline/presentation/widgets/today_arc_card.dart`:

```dart
import 'dart:math' as math;

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// Single hero progress card. Replaces CurrentMissionBanner + best streak + vote icon.
class TodayArcCard extends StatelessWidget {
  final int completed;
  final int total;
  final int streakDays;
  final VoidCallback? onTap;

  const TodayArcCard({
    super.key,
    required this.completed,
    required this.total,
    required this.streakDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    final remaining = math.max(0, total - completed);
    final onTrack = remaining == 0 && total > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(EmergeColors.teal),
                    ),
                  ),
                  Text('${(pct * 100).round()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTrack
                        ? 'All done · $streakDays-day streak'
                        : (total == 0 ? 'Start your streak' : "$remaining habit${remaining == 1 ? '' : 's'} left today"),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0
                        ? 'Add your first habit'
                        : (onTrack ? 'Come back tomorrow' : 'Tap to jump to your next habit'),
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/timeline/today_arc_card_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/today_arc_card.dart test/features/timeline/today_arc_card_test.dart
git commit -m "feat(timeline): add TodayArcCard (single hero progress ring)"
```

---

## Task 13: Wire `NarratorAvatar` + `TodayArcCard` + slide-up host into `TimelineScreen`

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Replace the header**

In `TimelineScreen.build`:

- Replace the `ArchetypeSliverAppBar(actions: [...share, recap, profile])` with a `SliverToBoxAdapter` whose `child` is a `Row`:
  - Left: existing `MonthCalendarStrip` or simply the date title + count.
  - Right: `NarratorAvatar(onTap: () => _openNarratorForTap())`.
- Move share / recap / profile to a single `PopupMenuButton` (icon: `Icons.more_vert`) in the same Row.

- [ ] **Step 2: Replace the mission + streak row**

In `_buildTimelineList`:

- Delete `CurrentMissionBanner`, `_buildBestStreakWidget`, `_buildVoteIcon`.
- Insert `TodayArcCard(completed: completedCount, total: habits.length, streakDays: maxStreak)` where they were.

- [ ] **Step 3: Add the slide-up host**

Add a `ConsumerStatefulWidget`-style `Stack` overlay at the top of the timeline:

```dart
ref.listen(pendingMilestoneProvider, (prev, next) {
  if (prev == null && next != null) {
    _showMilestoneOverlay(next);
  }
});

void _showMilestoneOverlay(line) {
  // Use OverlayEntry to slide up from bottom; auto-dismisses via NarratorMilestoneCard.
  // On dismiss, call ref.read(pendingMilestoneProvider.notifier).clear();
}
```

The actual OverlayEntry creation:

```dart
late final OverlayEntry _entry;

void _showMilestoneOverlay(line) {
  _entry = OverlayEntry(builder: (_) => Positioned(
    left: 0, right: 0, bottom: 16 + MediaQuery.paddingOf(context).bottom,
    child: NarratorMilestoneCard(
      line: line,
      trigger: _triggerForLine(line),
      onDismissed: () {
        _entry.remove();
        ref.read(pendingMilestoneProvider.notifier).clear();
      },
    ),
  ));
  Overlay.of(context).insert(_entry);
}
```

(Store `_triggerForLine` as a small map; default to `askNarrator`.)

- [ ] **Step 4: Run analyze + tests**

Run: `dart analyze lib/`
Expected: 0 errors.

Run: `flutter test test/features/timeline test/features/narrator`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): add NarratorAvatar, TodayArcCard, slide-up milestone host"
```

**✅ Phase 2 complete.** Working software: narrator avatar visible on timeline, milestone cards slide up on triggers. Reflection widget still pending (Phase 3).

---

# Phase 3 — Reflection feature (drift table + widget)

> Goal: users can log a daily mood + 1-line note inline on the timeline. Phase 3 produces a working reflection widget backed by drift persistence.

## Task 14: `ReflectionRepository` + tests

**Files:**
- Create: `lib/features/reflections/data/datasources/reflection_local_datasource.dart`
- Create: `lib/features/reflections/data/datasources/reflection_remote_datasource.dart`
- Create: `lib/features/reflections/data/repositories/reflection_repository.dart`
- Create: `test/features/reflections/reflection_repository_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/reflections/reflection_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/drift_native.dart';
import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements ReflectionRemoteDatasource {
  final writes = <Map<String, Object?>>[];
  @override
  Future<void> write(Map<String, Object?> data) async => writes.add(data);
}

void main() {
  test('save returns Right(DailyReflection) and writes to remote', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = ReflectionRepository(
      local: ReflectionLocalDatasource(dao: db.dailyReflectionsDao),
      remote: _FakeRemote(),
    );
    final result = await repo.save(
      userId: 'u1',
      localDate: DateTime(2026, 7, 5),
      mood: Mood.good,
      note: 'felt strong',
    );
    expect(result.isRight(), isTrue);
    final r = result.getOrElse(() => throw 'unreachable');
    expect(r.mood, Mood.good);
    expect(r.note, 'felt strong');
    db.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reflections/reflection_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement local datasource**

`lib/features/reflections/data/datasources/reflection_local_datasource.dart`:

```dart
import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

class ReflectionLocalDatasource {
  ReflectionLocalDatasource({required this.dao});
  final DailyReflectionsDao dao;

  Future<DailyReflection?> getByDate(String userId, DateTime localDate) async {
    final row = await dao.getByDate(userId, localDate);
    if (row == null) return null;
    return DailyReflection(
      id: row.id,
      userId: row.userId,
      localDate: row.localDate,
      mood: row.mood,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<DailyReflection> upsert({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    await dao.upsert(userId: userId, localDate: localDate, mood: mood, note: note);
    final row = await dao.getByDate(userId, localDate);
    return DailyReflection(
      id: row!.id,
      userId: row.userId,
      localDate: row.localDate,
      mood: row.mood,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
```

- [ ] **Step 4: Implement remote datasource**

`lib/features/reflections/data/datasources/reflection_remote_datasource.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ReflectionRemoteDatasource {
  Future<void> write(Map<String, Object?> data);
}

class FirestoreReflectionRemoteDatasource implements ReflectionRemoteDatasource {
  FirestoreReflectionRemoteDatasource({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Future<void> write(Map<String, Object?> data) async {
    final uid = data['userId'] as String;
    final localDate = data['localDate'] as DateTime;
    final dayKey = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    await firestore
        .collection('users').doc(uid)
        .collection('reflections').doc(dayKey)
        .set(data, SetOptions(merge: true));
  }
}
```

- [ ] **Step 5: Implement the repository**

`lib/features/reflections/data/repositories/reflection_repository.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

class ReflectionRepository {
  ReflectionRepository({required this.local, required this.remote});
  final ReflectionLocalDatasource local;
  final ReflectionRemoteDatasource remote;

  Future<Either<Failure, DailyReflection?>> getForDate({
    required String userId,
    required DateTime localDate,
  }) async {
    try {
      return Right(await local.getByDate(userId, localDate));
    } catch (e) {
      return Left(CacheFailure('Could not load reflection: $e'));
    }
  }

  Future<Either<Failure, DailyReflection>> save({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    try {
      final saved = await local.upsert(userId: userId, localDate: localDate, mood: mood, note: note);
      // Fire-and-forget remote; failure does not fail the save.
      unawaited(remote.write({
        'userId': userId,
        'localDate': localDate,
        'mood': mood.value,
        'note': note,
        'updatedAt': saved.updatedAt,
      }).catchError((_) {}));
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure('Could not save reflection: $e'));
    }
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/reflections/reflection_repository_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/reflections test/features/reflections/reflection_repository_test.dart
git commit -m "feat(reflections): add ReflectionRepository (drift + Firestore mirror)"
```

---

## Task 15: `reflectionProviders` (Riverpod wiring)

**Files:**
- Create: `lib/features/reflections/presentation/providers/reflection_providers.dart`
- Create: `lib/features/reflections/presentation/providers/reflection_providers.g.dart` (generated)

- [ ] **Step 1: Implement providers**

`lib/features/reflections/presentation/providers/reflection_providers.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'reflection_providers.g.dart';

@Riverpod(keepAlive: true)
ReflectionLocalDatasource reflectionLocalDatasource(Ref ref) =>
    ReflectionLocalDatasource(dao: ref.watch(appDatabaseProvider).dailyReflectionsDao);

@Riverpod(keepAlive: true)
ReflectionRemoteDatasource reflectionRemoteDatasource(Ref ref) =>
    FirestoreReflectionRemoteDatasource(firestore: FirebaseFirestore.instance);

@Riverpod(keepAlive: true)
ReflectionRepository reflectionRepository(Ref ref) => ReflectionRepository(
      local: ref.watch(reflectionLocalDatasourceProvider),
      remote: ref.watch(reflectionRemoteDatasourceProvider),
    );

/// Loads the reflection for [date] (default = today). Returns null if none.
@riverpod
Future<DailyReflection?> dailyReflection(
  Ref ref, {
  required String userId,
  required DateTime date,
}) async {
  final result = await ref.watch(reflectionRepositoryProvider).getForDate(userId: userId, localDate: date);
  return result.fold((_) => null, (r) => r);
}
```

- [ ] **Step 2: Run codegen + analyze**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD SUCCESSFUL.

Run: `dart analyze lib/features/reflections`
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reflections/presentation/providers
git commit -m "feat(reflections): add Riverpod providers for reflection feature"
```

---

## Task 16: `TimelineReflectionCard` widget + tests

**Files:**
- Create: `lib/features/timeline/presentation/widgets/timeline_reflection_card.dart`
- Create: `test/features/timeline/timeline_reflection_card_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/timeline/timeline_reflection_card_test.dart`:

```dart
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/reflection_providers.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_reflection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _StubRepo implements ReflectionRepository {
  _StubRepo(this._existing);
  final DailyReflection? _existing;

  @override
  Future<Right<dynamic, DailyReflection?>> getForDate({required String userId, required DateTime localDate}) async =>
      Right(_existing);

  @override
  Future<Right<dynamic, DailyReflection>> save({required String userId, required DateTime localDate, required Mood mood, required String note}) async =>
      Right(DailyReflection(id: 'r1', userId: userId, localDate: localDate, mood: mood, note: note, createdAt: DateTime.now(), updatedAt: DateTime.now()));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('empty state shows 5 emoji row + note input + Save', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [reflectionRepositoryProvider.overrideWithValue(_StubRepo(null))],
      child: MaterialApp(home: Scaffold(body: TimelineReflectionCard(userId: 'u1', date: DateTime(2026, 7, 5)))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('How does today feel so far?'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('existing reflection renders collapsed summary', (tester) async {
    final existing = DailyReflection(
      id: 'r1', userId: 'u1', localDate: DateTime(2026, 7, 5),
      mood: Mood.good, note: 'morning was tough',
      createdAt: DateTime(2026, 7, 5, 9), updatedAt: DateTime(2026, 7, 5, 9),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [reflectionRepositoryProvider.overrideWithValue(_StubRepo(existing))],
      child: MaterialApp(home: Scaffold(body: TimelineReflectionCard(userId: 'u1', date: DateTime(2026, 7, 5)))),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('morning was tough'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/timeline/timeline_reflection_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the widget**

`lib/features/timeline/presentation/widgets/timeline_reflection_card.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/reflection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline mood + 1-line note widget for the timeline. Empty → save → collapsed.
class TimelineReflectionCard extends ConsumerStatefulWidget {
  final String userId;
  final DateTime date;
  const TimelineReflectionCard({super.key, required this.userId, required this.date});

  @override
  ConsumerState<TimelineReflectionCard> createState() => _TimelineReflectionCardState();
}

class _TimelineReflectionCardState extends ConsumerState<TimelineReflectionCard> {
  Mood? _mood;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;
  bool _collapsedAfterSave = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncExisting = ref.watch(dailyReflectionProvider(userId: widget.userId, date: widget.date));

    return asyncExisting.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _buildError(),
      data: (existing) {
        if (_collapsedAfterSave && _mood != null) {
          return _buildCollapsed(_mood!, _noteCtrl.text);
        }
        if (existing != null) {
          return _buildCollapsed(existing.mood, existing.note);
        }
        return _buildExpanded();
      },
    );
  }

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange)),
        child: const Text('Could not load reflection. Pull to refresh.', style: TextStyle(color: Colors.orange)),
      );

  Widget _buildExpanded() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            EmergeColors.violet.withValues(alpha: 0.1),
            EmergeColors.teal.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: EmergeColors.violet.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REFLECT', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 8),
          const Text('How does today feel so far?', style: TextStyle(fontSize: 14, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final m in Mood.values) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mood = m),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _mood == m
                              ? EmergeColors.teal.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: _mood == m ? EmergeColors.teal : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 22))),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLength: 140,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a one-line note (optional)…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: _mood == null || _isSaving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: EmergeColors.teal),
                child: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsed(Mood mood, String note) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _collapsedAfterSave = false;
          _mood = mood;
          _noteCtrl.text = note;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                note.isEmpty ? 'You felt ${mood.name} today.' : note,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const Icon(Icons.edit, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_mood == null) return;
    setState(() => _isSaving = true);
    final result = await ref.read(reflectionRepositoryProvider).save(
          userId: widget.userId,
          localDate: widget.date,
          mood: _mood!,
          note: _noteCtrl.text.trim(),
        );
    setState(() {
      _isSaving = false;
      _collapsedAfterSave = result.isRight();
    });
    ref.invalidate(dailyReflectionProvider(userId: widget.userId, date: widget.date));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/timeline/timeline_reflection_card_test.dart`
Expected: PASS — 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/timeline_reflection_card.dart test/features/timeline/timeline_reflection_card_test.dart
git commit -m "feat(timeline): add TimelineReflectionCard (inline mood + 1-line note)"
```

---

## Task 17: Integrate `TimelineReflectionCard` into timeline

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Add the widget below habits**

In `_buildTimelineList`:

- Replace the bottom of the timeline (after `HierarchicalHabitTimeline`) — delete `AdBannerWidget` (moves to overflow menu) and the `Bonus XP Boost` card (moves to overflow menu).
- Insert `TimelineReflectionCard(userId: ..., date: _selectedDate)`.
- Wrap the FAB label change: keep "Log Habit".

- [ ] **Step 2: Add overflow menu**

In the header row, add:

```dart
PopupMenuButton<String>(
  icon: Icon(Icons.more_vert, color: Colors.white),
  onSelected: (v) {
    switch (v) {
      case 'share': _shareTimelineProgress(); break;
      case 'recap': context.push('/recap'); break;
      case 'profile': context.push('/profile'); break;
      case 'bonus_xp': ref.read(adManagerProvider).showRewardedAd(...); break;
    }
  },
  itemBuilder: (_) => [
    PopupMenuItem(value: 'share', child: Text('Share progress')),
    PopupMenuItem(value: 'recap', child: Text('Weekly recap')),
    PopupMenuItem(value: 'profile', child: Text('Future Self Studio')),
    PopupMenuItem(value: 'bonus_xp', child: Text('Watch ad for bonus XP')),
  ],
)
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/timeline`
Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): integrate TimelineReflectionCard; overflow menu for share/recap/profile/bonus XP"
```

**✅ Phase 3 complete.** Working software: timeline shows narrator avatar + today-arc + habits + reflection widget. Users can log a daily mood + note.

---

# Phase 4 — Onboarding + Future Self Studio performance

> Goal: onboarding no longer narrates between milestones; Future Self Studio stops feeling slow. Phase 4 produces the full spec delivery.

## Task 18: Remove narrator interruptions in onboarding

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/identity_studio_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/first_habit_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/world_reveal_screen.dart`
- Modify: `lib/features/onboarding/presentation/screens/welcome_screen.dart`

- [ ] **Step 1: Remove `NarratorSheet.show` calls between milestones**

Run: `grep -rn "NarratorSheet.show" lib/features/onboarding/`

Delete each call. Also remove unused imports of:
- `narrator_appearance.dart`
- `narrator_sheet.dart`
- `narrator_trigger.dart`
- `narrator_local_datasource_provider` (if only used for the removed call)

Special case in `identity_studio_screen.dart`:
- Keep `NarratorTrigger.onboardingPostArchetype` as a slide-up card (it fires once after archetype is picked). Replace `NarratorSheet.show(...)` with `pendingMilestoneProvider.notifier.set(GenericLine('You\'ve chosen the ${archetypeName}. Show me what that looks like tomorrow.'))` — let the slide-up card host render it.

- [ ] **Step 2: Add a small `StepIndicator` widget to each onboarding screen**

Create `lib/features/onboarding/presentation/widgets/step_indicator.dart`:

```dart
import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int step;
  final int total;
  const StepIndicator({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('STEP $step OF $total',
              style: const TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54)),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Skip', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
```

Wire into each of the 5 onboarding screens at the top of the body:
- `welcome_screen.dart` → Step 1 of 5
- `identity_studio_screen.dart` → Step 2 of 5
- `first_habit_screen.dart` → Step 3 of 5 (or its actual position)
- `world_reveal_screen.dart` → Step 4 of 5
- (Implicit step 5 is final habit stack confirm — find the right screen)

(Read each screen to find the exact step number; the order may differ.)

- [ ] **Step 3: Reorder "Write your own" motive CTA in `identity_studio_screen.dart`**

In the motive selection UI, move `_isCustomMotive` button (with the custom motive text field) to render **above** the preset motive chips. Highlight it with a subtle violet border so it draws attention first.

- [ ] **Step 4: Run analyze + tests**

Run: `dart analyze lib/`
Expected: 0 errors.

Run: `flutter test test/features/onboarding test/features/timeline test/features/narrator`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding
git commit -m "feat(onboarding): remove mid-flow narrator interruptions; add step indicator + Skip; reorder custom motive CTA"
```

---

## Task 19: Future Self Studio performance fixes

**Files:**
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart`
- Modify: `lib/features/profile/presentation/widgets/evolving_silhouette_widget.dart`
- Modify: `lib/features/profile/presentation/widgets/stickman_avatar.dart`
- Modify: `lib/features/profile/presentation/widgets/synergy_card.dart`
- Modify: `lib/features/profile/presentation/widgets/decay_recovery_overlay.dart`

- [ ] **Step 1: Cap animation durations**

Run: `grep -rn "Duration(milliseconds:" lib/features/profile/`

For each file, replace any `Duration(milliseconds: N)`:
- If N < 150 → set to 150.
- If N > 550 → set to 550.

Material 3 motion caps: short 150-250, medium 250-400, long 400-550.

- [ ] **Step 2: Remove the screen-first-visit narrator typewriter**

In `future_self_studio_screen.dart`:
- Delete the `_checkScreenFirstVisit` call in `initState`.
- Delete the `NarratorAppearance` block.
- Delete the `if (trigger == NarratorTrigger.screenFirstVisit && mounted)` callback.
- Remove unused imports.

If anything should still greet the user once, replace with a non-blocking `NarratorMilestoneCard` slide-up via `pendingMilestoneProvider.notifier.set(...)` only for first-time visits (track with a local setting flag).

- [ ] **Step 3: Wrap animated subtrees in `RepaintBoundary`**

In `future_self_studio_screen.dart`, find each animated subtree (silhouette, aura, synergy card, recovery overlay) and wrap with `RepaintBoundary`:

```dart
RepaintBoundary(
  child: EvolvingSilhouetteWidget(...),
)
```

- [ ] **Step 4: Lazy-load avatar renderer**

Read the existing `useNewAvatarRendererProvider` flag. In the build method, gate the legacy silhouette widget behind the flag; if false, render `const SizedBox.shrink()` (or a placeholder `SkeletonShimmer`) until the user interacts with the screen. Read existing patterns from `lib/core/presentation/widgets/skeleton_shimmer.dart`.

- [ ] **Step 5: Replace large-area `BackdropFilter`**

Search `lib/features/profile/` for `BackdropFilter`. For any inside `GlassmorphismCard` whose surface covers > 30 % of the viewport on a typical phone screen (silhouette area, full-screen background), swap with a pre-baked blurred PNG (cached in `assets/`) or `ImageFiltered` applied once.

If a swap is impractical, leave the `BackdropFilter` but document the trade-off in code comments.

- [ ] **Step 6: Run analyze + tests**

Run: `dart analyze lib/`
Expected: 0 errors.

Run: `flutter test test/features/profile`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/profile
git commit -m "perf(profile): clamp animations to Material 3 150-550ms, isolate repaints, lazy-load avatar"
```

---

## Task 20: Manual QA verification

**Files:** none

- [ ] **Step 1: Cold-start the timeline**

Run: `flutter run -d <device>`

Verify:
- No typewriter anywhere.
- Avatar pulse is smooth.
- Tapping avatar opens sheet within 200 ms with instant text.

- [ ] **Step 2: Trigger a 7-day streak milestone**

Complete habits for 7 consecutive days (or stub `narratorStateProvider`). Verify:
- Slide-up card appears within 1 s.
- Free user sees generic copy ("You're on fire this week.").
- Pro user sees personal copy referencing their stats.
- Auto-dismisses after 6 s; swipe-up also dismisses.

- [ ] **Step 3: Log a reflection**

Verify:
- Emoji row is tappable; selection state is visible.
- Save → card collapses → re-tap expands for editing.

- [ ] **Step 4: Onboarding walkthrough**

Run: `flutter run` and reset onboarding (or use the "Reset onboarding" debug button if present).

Verify:
- No narrator sheets interrupt milestone progression.
- "Step X of 5" indicator visible on every milestone.
- Skip button works.
- Custom motive CTA renders above presets in identity studio.

- [ ] **Step 5: Future Self Studio first-paint**

Verify:
- First paint < 800 ms on a mid-tier emulator (Pixel 5 / mid-tier Android).
- No animation > 550 ms.

- [ ] **Step 6: Run full test suite + analyze**

Run: `dart analyze lib/`
Expected: 0 errors, 0 warnings on changed files.

Run: `flutter test test/`
Expected: all pass.

- [ ] **Step 7: Final commit**

If any small follow-ups were needed during QA, commit them as `chore: post-QA fixes for narrator/timeline/onboarding`.

---

## Self-review (do once after writing)

- [ ] **Spec coverage:** Each section of `docs/superpowers/specs/2026-07-05-narrator-onboarding-timeline-redesign-design.md` maps to at least one task:
  - §3 decisions → implicit in Phase 1-4 scope.
  - §4 narrator → Tasks 1, 5-11, 13.
  - §5 timeline → Tasks 12, 13, 17.
  - §6 onboarding → Task 18.
  - §7 future self studio → Task 19.
  - §8 data model → Tasks 3, 4.
  - §9 architecture → all tasks.
  - §13 testing → covered in every task via per-task tests + Task 20 manual QA.
  - §14 migration → Task 3.

- [ ] **Placeholder scan:** No "TBD", "TODO", "implement later", "fill in details" outside the single intentional `TODO(task-22)` marker in Task 7 (the LLM stub).

- [ ] **Type consistency:** All references to `NarratorLine`, `GenericLine`, `PersonalLine`, `DailyReflection`, `Mood`, `WeeklyRecapResult`, `WeeklyRecapGated`, `WeeklyRecapLine`, `NarratorLineResolver`, `NarratorAvatar`, `NarratorMilestoneCard`, `TodayArcCard`, `TimelineReflectionCard`, `StepIndicator`, `ReflectionRepository` are defined in the task that introduces them.

- [ ] **Open follow-ups:** Task 22 (swap LLM stub for real Groq call) is called out in Task 7's TODO and is the only intentional deferral.
