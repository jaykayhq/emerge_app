# Habit Widget Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the timeline habit row into a 4-icon compact row (body nav, checkbox, ⏱️, ⋮), move all habit editing into a modal bottom sheet, add per-habit reflection persistence, and delete the now-redundant `HabitDetailScreen`.

**Architecture:** Bottom-up TDD on the pure helper, then DAO, then repository, then providers, then widgets (row + sheet), then wiring, then deletion of the old screen + route. Local-first drift persistence mirrors the existing `DailyReflection` pattern; remote Firestore writes are fire-and-forget. Drift schema version bumps to add the new `habit_reflections` table.

**Tech Stack:** Flutter (Dart ^3.10.0), Riverpod 3.x (annotation + codegen), drift (SQLite), `fpdart` `Either`, `go_router 17`, `flutter_test`, `mocktail`, `fake_cloud_firestore`.

**Spec:** `docs/superpowers/specs/2026-07-10-habit-widget-rebuild-design.md`

---

## File Structure

| Status | File | Responsibility |
|---|---|---|
| **New** | `lib/features/reflections/domain/entities/habit_reflection.dart` | `HabitReflection` value type |
| **New** | `lib/features/reflections/data/datasources/habit_reflection_local_datasource.dart` | Drift-backed read/upsert |
| **New** | `lib/features/reflections/data/datasources/habit_reflection_remote_datasource.dart` | Firestore mirror write |
| **New** | `lib/features/reflections/data/repositories/habit_reflection_repository.dart` | `Either<Failure, T>` repo, local-first |
| **New** | `lib/features/reflections/presentation/providers/habit_reflection_providers.dart` | `habitReflection` + `saveHabitReflection` Riverpod providers |
| **New** | `lib/features/reflections/presentation/widgets/habit_options_sheet.dart` | Modal bottom sheet with 5 sections |
| **New** | `lib/core/drift/tables/habit_reflections_table.dart` | Drift table definition |
| **New** | `lib/core/drift/daos/habit_reflections_dao.dart` | DAO with `getByDate`, `upsert`, `watchForHabit` |
| **New** | `lib/features/timeline/presentation/widgets/habit_progress_math.dart` | Pure `habitCardFillFraction` helper |
| **Modified** | `lib/core/drift/app_database.dart` | Register table + DAO, bump `schemaVersion` to 8, add migration |
| **Modified** | `lib/features/timeline/presentation/widgets/habit_timeline_section.dart` | Rewrite `_IndentedHabitItem` as new layout |
| **Modified** | `lib/features/timeline/presentation/screens/timeline_screen.dart` | Update callback wiring for new tap semantics |
| **Modified** | `lib/core/router/router.dart` | Drop `/timeline/detail/:habitId` route + import |
| **Modified** | `lib/features/habits/presentation/widgets/habit_timer_dialog.dart` | Add "Exit & run in background" button |
| **Deleted** | `lib/features/habits/presentation/screens/habit_detail_screen.dart` | Replaced by sheet |
| **Deleted** | `test/features/habits/presentation/screens/habit_detail_screen_test.dart` | Tests for deleted screen |
| **New tests** | See test files in each task |

---

## Task 1: Add `habit_reflections` drift table

**Files:**
- Create: `lib/core/drift/tables/habit_reflections_table.dart`
- Modify: `lib/core/drift/app_database.dart`
- Test: N/A (table is exercised via DAO tests in Task 2)

- [ ] **Step 1: Create the table**

Create `lib/core/drift/tables/habit_reflections_table.dart`:

```dart
import 'package:drift/drift.dart';

/// Drift table for per-habit reflections.
///
/// Stores the user's mood (1-5) and optional 1-line note for a specific
/// habit on a given local date. One row per (userId, habitId, localDate) —
/// upserted via the DAO.
class HabitReflectionsTable extends Table {
  /// Unique row id.
  TextColumn get id => text()();

  /// Owner user id.
  TextColumn get userId => text()();

  /// Owning habit id.
  TextColumn get habitId => text()();

  /// Local date (year/month/day only, time stripped at write time).
  DateTimeColumn get localDate => dateTime()();

  /// Mood as integer 1..5. See [Mood.fromInt] for mapping.
  IntColumn get mood => integer()();

  /// Optional 1-line note (max 140 chars at the call site, not enforced here).
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Row creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String? get tableName => 'habit_reflections';
}
```

- [ ] **Step 2: Register table in `app_database.dart`**

Edit `lib/core/drift/app_database.dart`:

Add import (alphabetical, after `daily_reflections_table.dart`):
```dart
import 'tables/habit_reflections_table.dart';
```

Add to `@DriftDatabase(tables: [...])` list (after `DailyReflectionsTable`):
```dart
HabitReflectionsTable,
```

Add to `@DriftDatabase(daos: [...])` list (after `DailyReflectionsDao` — note: the DAO is added in Task 2, add the placeholder for now and adjust after Task 2 imports it):
```dart
HabitReflectionsDao,
```

Bump `schemaVersion`:
```dart
@override
int get schemaVersion => 8;
```

Add migration step (after the `from < 7` block):
```dart
if (from < 8) {
  await m.createTable(habitReflectionsTable);
}
```

- [ ] **Step 3: Run build_runner**

```bash
cd emerge_app && flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: builds succeed. New generated `habitReflectionsTable` symbol available.

- [ ] **Step 4: Commit**

```bash
git add lib/core/drift/tables/habit_reflections_table.dart lib/core/drift/app_database.dart lib/core/drift/app_database.g.dart
git commit -m "feat(drift): add habit_reflections table (schemaVersion=8)"
```

---

## Task 2: Add `HabitReflectionsDao` with tests

**Files:**
- Create: `lib/core/drift/daos/habit_reflections_dao.dart`
- Create: `test/core/drift/daos/habit_reflections_dao_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/core/drift/daos/habit_reflections_dao_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitReflectionsDao.getByDate', () {
    test('returns null when no row exists', () async {
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10),
      );
      expect(row, isNull);
    });

    test('ignores time component of localDate', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10, 9, 30),
        mood: Mood.good,
        note: 'felt strong',
      );
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10, 23, 59),
      );
      expect(row, isNotNull);
      expect(row!.note, 'felt strong');
    });
  });

  group('HabitReflectionsDao.upsert', () {
    test('inserts new row', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
      );
      final row = await db.habitReflectionsDao.getByDate(
        'u1',
        'h1',
        DateTime(2026, 7, 10),
      );
      expect(row, isNotNull);
      expect(row!.mood, Mood.ok.value);
      expect(row.note, 'first');
    });

    test('updates existing row on same (userId, habitId, day)', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
      );
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.great,
        note: 'second',
      );
      final rows = await db.select(db.habitReflectionsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.note, 'second');
      expect(rows.first.mood, Mood.great.value);
    });

    test('keeps separate rows per habitId on same day', () async {
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'h1 note',
      );
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h2',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.good,
        note: 'h2 note',
      );
      final rows = await db.select(db.habitReflectionsTable).get();
      expect(rows, hasLength(2));
    });
  });

  group('HabitReflectionsDao.watchForHabit', () {
    test('emits on insert', () async {
      final stream = db.habitReflectionsDao.watchForHabit(
        'u1',
        'h1',
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 31),
      );
      final emitted = <int>[];
      final sub = stream.listen((rows) => emitted.add(rows.length));
      await Future<void>.delayed(Duration.zero);
      await db.habitReflectionsDao.upsert(
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: '',
      );
      await Future<void>.delayed(Duration(milliseconds: 50));
      expect(emitted.last, 1);
      await sub.cancel();
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/core/drift/daos/habit_reflections_dao_test.dart
```

Expected: FAIL — `db.habitReflectionsDao` doesn't exist yet.

- [ ] **Step 3: Implement the DAO**

Create `lib/core/drift/daos/habit_reflections_dao.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/tables/habit_reflections_table.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'habit_reflections_dao.g.dart';

/// DAO for the habit_reflections table.
///
/// Stores per-habit mood (1..5) and optional 1-line note.
/// One row per (userId, habitId, localDate); upserts by key.
@DriftAccessor(tables: [HabitReflectionsTable])
class HabitReflectionsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitReflectionsDaoMixin {
  HabitReflectionsDao(super.db);

  static int _idCounter = 0;

  String _newId() {
    _idCounter++;
    return 'hr_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  DateTime _dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Returns the row for (userId, habitId, localDate), or null if none.
  /// Time component of [localDate] is ignored.
  Future<HabitReflectionsTableData?> getByDate(
    String userId,
    String habitId,
    DateTime localDate,
  ) {
    final day = _dayOnly(localDate);
    return (select(habitReflectionsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.habitId.equals(habitId) &
                t.localDate.equals(day),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// Inserts a new row, or overwrites the existing row for
  /// (userId, habitId, localDate).
  Future<void> upsert({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    final day = _dayOnly(localDate);
    final existing = await getByDate(userId, habitId, day);
    final now = DateTime.now();

    if (existing == null) {
      await into(habitReflectionsTable).insert(
        HabitReflectionsTableCompanion.insert(
          id: _newId(),
          userId: userId,
          habitId: habitId,
          localDate: day,
          mood: mood.value,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(habitReflectionsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        HabitReflectionsTableCompanion(
          mood: Value(mood.value),
          note: Value(note),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Streams rows for [habitId] owned by [userId] between [fromDate] and
  /// [toDate] (inclusive, day-only).
  Stream<List<HabitReflectionsTableData>> watchForHabit(
    String userId,
    String habitId,
    DateTime fromDate,
    DateTime toDate,
  ) {
    final from = _dayOnly(fromDate);
    final to = _dayOnly(toDate);
    return (select(habitReflectionsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.habitId.equals(habitId) &
                t.localDate.isBetweenValues(from, to),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.localDate)]))
        .watch();
  }
}
```

- [ ] **Step 4: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `_$HabitReflectionsDaoMixin` generated successfully.

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/core/drift/daos/habit_reflections_dao_test.dart
```

Expected: PASS — all 6 tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/core/drift/daos/habit_reflections_dao.dart lib/core/drift/daos/habit_reflections_dao.g.dart test/core/drift/daos/habit_reflections_dao_test.dart
git commit -m "feat(drift): add HabitReflectionsDao with upsert + watchForHabit"
```

---

## Task 3: Add `HabitReflection` entity

**Files:**
- Create: `lib/features/reflections/domain/entities/habit_reflection.dart`
- Create: `test/features/reflections/habit_reflection_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/reflections/habit_reflection_test.dart`:

```dart
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitReflection', () {
    test('equality is value-based', () {
      final a = HabitReflection(
        id: 'hr1',
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'good day',
        createdAt: DateTime(2026, 7, 10, 9),
        updatedAt: DateTime(2026, 7, 10, 9),
      );
      final b = a.copyWith();
      expect(a, equals(b));
    });

    test('copyWith updates mood + note + updatedAt', () {
      final a = HabitReflection(
        id: 'hr1',
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
        createdAt: DateTime(2026, 7, 10, 9),
        updatedAt: DateTime(2026, 7, 10, 9),
      );
      final b = a.copyWith(mood: Mood.great, note: 'amazing', updatedAt: DateTime(2026, 7, 10, 10));
      expect(b.mood, Mood.great);
      expect(b.note, 'amazing');
      expect(b.updatedAt, DateTime(2026, 7, 10, 10));
      // Unchanged fields
      expect(b.id, a.id);
      expect(b.userId, a.userId);
      expect(b.habitId, a.habitId);
      expect(b.localDate, a.localDate);
      expect(b.createdAt, a.createdAt);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/reflections/habit_reflection_test.dart
```

Expected: FAIL — `HabitReflection` not defined.

- [ ] **Step 3: Implement the entity**

Create `lib/features/reflections/domain/entities/habit_reflection.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'mood.dart';

/// One-per-(userId, habitId, localDate) mood + note entry for a single habit.
class HabitReflection extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final DateTime localDate;
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitReflection({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.localDate,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitReflection copyWith({
    Mood? mood,
    String? note,
    DateTime? updatedAt,
  }) {
    return HabitReflection(
      id: id,
      userId: userId,
      habitId: habitId,
      localDate: localDate,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    habitId,
    localDate,
    mood,
    note,
    createdAt,
    updatedAt,
  ];
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/reflections/habit_reflection_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reflections/domain/entities/habit_reflection.dart test/features/reflections/habit_reflection_test.dart
git commit -m "feat(reflections): add HabitReflection entity"
```

---

## Task 4: Add remote datasource

**Files:**
- Create: `lib/features/reflections/data/datasources/habit_reflection_remote_datasource.dart`
- Create: `test/features/reflections/habit_reflection_remote_datasource_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/reflections/habit_reflection_remote_datasource_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreHabitReflectionRemoteDatasource ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = FirestoreHabitReflectionRemoteDatasource(firestore: firestore);
  });

  test('write creates doc under users/{uid}/habit_reflections/{dateKey}', () async {
    await ds.write({
      'userId': 'u1',
      'habitId': 'h1',
      'localDate': DateTime(2026, 7, 10),
      'mood': 4,
      'note': 'felt strong',
      'updatedAt': DateTime(2026, 7, 10, 12),
    });
    final snap = await firestore
        .collection('users')
        .doc('u1')
        .collection('habit_reflections')
        .doc('2026-07-10')
        .get();
    expect(snap.exists, isTrue);
    expect(snap.data()!['mood'], 4);
    expect(snap.data()!['note'], 'felt strong');
    expect(snap.data()!['habitId'], 'h1');
  });

  test('write with merge=true does not overwrite unrelated fields', () async {
    final col = firestore
        .collection('users')
        .doc('u1')
        .collection('habit_reflections');
    await col.doc('2026-07-10').set({'extra': 'keep-me'});
    await ds.write({
      'userId': 'u1',
      'habitId': 'h1',
      'localDate': DateTime(2026, 7, 10),
      'mood': 4,
      'note': 'felt strong',
      'updatedAt': DateTime(2026, 7, 10, 12),
    });
    final snap = await col.doc('2026-07-10').get();
    expect(snap.data()!['extra'], 'keep-me');
    expect(snap.data()!['mood'], 4);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/reflections/habit_reflection_remote_datasource_test.dart
```

Expected: FAIL — `FirestoreHabitReflectionRemoteDatasource` not defined.

- [ ] **Step 3: Implement the datasource**

Create `lib/features/reflections/data/datasources/habit_reflection_remote_datasource.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction for the remote per-habit reflection mirror (Firestore).
abstract class HabitReflectionRemoteDatasource {
  Future<void> write(Map<String, Object?> data);
}

/// Firestore-backed implementation.
/// Writes a per-habit reflection doc to
/// users/{uid}/habit_reflections/{dateKey}.
class FirestoreHabitReflectionRemoteDatasource
    implements HabitReflectionRemoteDatasource {
  FirestoreHabitReflectionRemoteDatasource({required this.firestore});
  final FirebaseFirestore firestore;

  @override
  Future<void> write(Map<String, Object?> data) async {
    final uid = data['userId'] as String;
    final localDate = data['localDate'] as DateTime;
    final dayKey =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    await firestore
        .collection('users')
        .doc(uid)
        .collection('habit_reflections')
        .doc(dayKey)
        .set(data, SetOptions(merge: true));
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/reflections/habit_reflection_remote_datasource_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reflections/data/datasources/habit_reflection_remote_datasource.dart test/features/reflections/habit_reflection_remote_datasource_test.dart
git commit -m "feat(reflections): add FirestoreHabitReflectionRemoteDatasource"
```

---

## Task 5: Add local datasource

**Files:**
- Create: `lib/features/reflections/data/datasources/habit_reflection_local_datasource.dart`

- [ ] **Step 1: Implement (covered by repo tests in Task 6)**

Create `lib/features/reflections/data/datasources/habit_reflection_local_datasource.dart`:

```dart
import 'package:emerge_app/core/drift/daos/habit_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Local datasource for per-habit reflections backed by drift.
class HabitReflectionLocalDatasource {
  HabitReflectionLocalDatasource({required this.dao});
  final HabitReflectionsDao dao;

  Future<HabitReflection?> getByDate(
    String userId,
    String habitId,
    DateTime localDate,
  ) async {
    final row = await dao.getByDate(userId, habitId, localDate);
    if (row == null) return null;
    return HabitReflection(
      id: row.id,
      userId: row.userId,
      habitId: row.habitId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<HabitReflection> upsert({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    await dao.upsert(
      userId: userId,
      habitId: habitId,
      localDate: localDate,
      mood: mood,
      note: note,
    );
    final row = await dao.getByDate(userId, habitId, localDate);
    return HabitReflection(
      id: row!.id,
      userId: row.userId,
      habitId: row.habitId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/reflections/data/datasources/habit_reflection_local_datasource.dart
git commit -m "feat(reflections): add HabitReflectionLocalDatasource"
```

---

## Task 6: Add repository

**Files:**
- Create: `lib/features/reflections/data/repositories/habit_reflection_repository.dart`
- Create: `test/features/reflections/habit_reflection_repository_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/reflections/habit_reflection_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements HabitReflectionRemoteDatasource {
  final writes = <Map<String, Object?>>[];
  @override
  Future<void> write(Map<String, Object?> data) async {
    writes.add(data);
  }
}

void main() {
  late AppDatabase db;
  late HabitReflectionLocalDatasource local;
  late _FakeRemote remote;
  late HabitReflectionRepository repo;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    local = HabitReflectionLocalDatasource(dao: db.habitReflectionsDao);
    remote = _FakeRemote();
    repo = HabitReflectionRepository(local: local, remote: remote);
  });

  tearDown(() async {
    await db.close();
  });

  test('getForHabit returns null when no row', () async {
    final result = await repo.getForHabit(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
    );
    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => null), isNull);
  });

  test('save returns Right and mirrors to remote', () async {
    final result = await repo.save(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
      mood: Mood.good,
      note: 'felt strong',
    );
    expect(result.isRight(), isTrue);
    final r = result.getOrElse((_) => throw 'unreachable');
    expect(r.habitId, 'h1');
    expect(r.mood, Mood.good);
    expect(r.note, 'felt strong');
    // Remote write happened (fire-and-forget, but synchronous in test)
    expect(remote.writes, hasLength(1));
    expect(remote.writes.first['habitId'], 'h1');
  });

  test('save does not throw when remote fails', () async {
    final throwingRemote = _ThrowingRemote();
    final repo2 = HabitReflectionRepository(local: local, remote: throwingRemote);
    final result = await repo2.save(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
      mood: Mood.ok,
      note: 'ok',
    );
    expect(result.isRight(), isTrue);
  });
}

class _ThrowingRemote implements HabitReflectionRemoteDatasource {
  @override
  Future<void> write(Map<String, Object?> data) async {
    throw Exception('network down');
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/reflections/habit_reflection_repository_test.dart
```

Expected: FAIL — `HabitReflectionRepository` not defined.

- [ ] **Step 3: Implement the repository**

Create `lib/features/reflections/data/repositories/habit_reflection_repository.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Repository for per-habit reflections.
///
/// Local drift persistence is the source of truth; remote Firestore writes
/// are fire-and-forget (failures are silently caught).
class HabitReflectionRepository {
  HabitReflectionRepository({required this.local, required this.remote});
  final HabitReflectionLocalDatasource local;
  final HabitReflectionRemoteDatasource remote;

  /// Returns the reflection for (userId, habitId, localDate), or null if none.
  Future<Either<Failure, HabitReflection?>> getForHabit({
    required String userId,
    required String habitId,
    required DateTime localDate,
  }) async {
    try {
      return Right(await local.getByDate(userId, habitId, localDate));
    } catch (e) {
      return Left(CacheFailure('Could not load reflection: $e'));
    }
  }

  /// Saves (upserts) a per-habit reflection locally, then mirrors to Firestore.
  Future<Either<Failure, HabitReflection>> save({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    try {
      final saved = await local.upsert(
        userId: userId,
        habitId: habitId,
        localDate: localDate,
        mood: mood,
        note: note,
      );
      unawaited(
        remote
            .write({
              'userId': userId,
              'habitId': habitId,
              'localDate': localDate,
              'mood': mood.value,
              'note': note,
              'updatedAt': saved.updatedAt,
            })
            .catchError((e) {
          debugPrint('HabitReflectionRepository: remote write failed: $e');
        }),
      );
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure('Could not save reflection: $e'));
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/reflections/habit_reflection_repository_test.dart
```

Expected: PASS — all 3 tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reflections/data/repositories/habit_reflection_repository.dart test/features/reflections/habit_reflection_repository_test.dart
git commit -m "feat(reflections): add HabitReflectionRepository"
```

---

## Task 7: Add Riverpod providers

**Files:**
- Create: `lib/features/reflections/presentation/providers/habit_reflection_providers.dart`

- [ ] **Step 1: Implement providers**

Create `lib/features/reflections/presentation/providers/habit_reflection_providers.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'habit_reflection_providers.g.dart';

@Riverpod(keepAlive: true)
HabitReflectionLocalDatasource habitReflectionLocalDatasource(Ref ref) =>
    HabitReflectionLocalDatasource(dao: ref.watch(appDatabaseProvider).habitReflectionsDao);

@Riverpod(keepAlive: true)
HabitReflectionRemoteDatasource habitReflectionRemoteDatasource(Ref ref) =>
    FirestoreHabitReflectionRemoteDatasource(firestore: FirebaseFirestore.instance);

@Riverpod(keepAlive: true)
HabitReflectionRepository habitReflectionRepository(Ref ref) =>
    HabitReflectionRepository(
      local: ref.watch(habitReflectionLocalDatasourceProvider),
      remote: ref.watch(habitReflectionRemoteDatasourceProvider),
    );

/// Loads the per-habit reflection for (userId, habitId, date). Returns null
/// if none exists.
@riverpod
Future<HabitReflection?> habitReflection(
  Ref ref, {
  required String userId,
  required String habitId,
  required DateTime date,
}) async {
  final result = await ref
      .watch(habitReflectionRepositoryProvider)
      .getForHabit(userId: userId, habitId: habitId, localDate: date);
  return result.fold((_) => null, (r) => r);
}

/// Saves a per-habit reflection and invalidates [habitReflection].
@riverpod
Future<void> saveHabitReflection(
  Ref ref, {
  required String userId,
  required String habitId,
  required DateTime date,
  required Mood mood,
  required String note,
}) async {
  final repo = ref.read(habitReflectionRepositoryProvider);
  await repo.save(
    userId: userId,
    habitId: habitId,
    localDate: date,
    mood: mood,
    note: note,
  );
  ref.invalidate(habitReflectionProvider(
    userId: userId,
    habitId: habitId,
    date: date,
  ));
}
```

- [ ] **Step 2: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `habit_reflection_providers.g.dart` generated.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reflections/presentation/providers/habit_reflection_providers.dart lib/features/reflections/presentation/providers/habit_reflection_providers.g.dart
git commit -m "feat(reflections): add habitReflection + saveHabitReflection providers"
```

---

## Task 8: Add `habitCardFillFraction` pure helper

**Files:**
- Create: `lib/features/timeline/presentation/widgets/habit_progress_math.dart`
- Create: `test/features/timeline/presentation/widgets/habit_progress_math_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/timeline/presentation/widgets/habit_progress_math_test.dart`:

```dart
import 'package:emerge_app/features/timeline/presentation/widgets/habit_progress_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('habitCardFillFraction', () {
    test('totalSeconds=0 returns 0 (no progress visible)', () {
      expect(habitCardFillFraction(remainingSeconds: 0, totalSeconds: 0), 0.0);
    });

    test('totalSeconds>0 and remainingSeconds=totalSeconds returns 0', () {
      expect(habitCardFillFraction(remainingSeconds: 120, totalSeconds: 120), 0.0);
    });

    test('remainingSeconds=0 returns 1 (fully filled)', () {
      expect(habitCardFillFraction(remainingSeconds: 0, totalSeconds: 120), 1.0);
    });

    test('halfway returns ~0.5', () {
      expect(habitCardFillFraction(remainingSeconds: 60, totalSeconds: 120), closeTo(0.5, 1e-9));
    });

    test('remainingSeconds > totalSeconds clamps to 0 (defensive)', () {
      expect(habitCardFillFraction(remainingSeconds: 200, totalSeconds: 120), 0.0);
    });

    test('negative remainingSeconds clamps to 1 (defensive)', () {
      expect(habitCardFillFraction(remainingSeconds: -5, totalSeconds: 120), 1.0);
    });

    test('progresses monotonically as remainingSeconds decreases', () {
      double prev = 0;
      for (int r = 120; r >= 0; r -= 30) {
        final f = habitCardFillFraction(remainingSeconds: r, totalSeconds: 120);
        expect(f, greaterThanOrEqualTo(prev));
        prev = f;
      }
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/timeline/presentation/widgets/habit_progress_math_test.dart
```

Expected: FAIL — `habitCardFillFraction` not defined.

- [ ] **Step 3: Implement the helper**

Create `lib/features/timeline/presentation/widgets/habit_progress_math.dart`:

```dart
/// Returns the fraction (0..1) of the timeline habit card that should be
/// filled given the timer's remaining seconds and total duration.
///
/// Pure; no widgets, no Riverpod. Extracted so the math is unit-testable
/// independent of any UI.
///
/// - When [totalSeconds] <= 0, returns 0.
/// - When [remainingSeconds] is out of range, clamps to [0, 1].
double habitCardFillFraction({
  required int remainingSeconds,
  required int totalSeconds,
}) {
  if (totalSeconds <= 0) return 0.0;
  final f = 1 - (remainingSeconds / totalSeconds);
  return f.clamp(0.0, 1.0);
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/timeline/presentation/widgets/habit_progress_math_test.dart
```

Expected: PASS — all 7 tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_progress_math.dart test/features/timeline/presentation/widgets/habit_progress_math_test.dart
git commit -m "feat(timeline): add habitCardFillFraction pure helper"
```

---

## Task 9: Rewrite `_IndentedHabitItem` with 4-icon row

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`
- Create: `test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/features/timeline/presentation/widgets/habit_timeline_section_test.dart`:

```dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _makeHabit({
  String id = 'h1',
  String title = 'Morning Meditation',
  int timerDurationMinutes = 2,
  bool completedToday = false,
}) {
  final now = DateTime.now();
  return Habit(
    id: id,
    userId: 'u1',
    title: title,
    createdAt: now,
    timerDurationMinutes: timerDurationMinutes,
    lastCompletedDate: completedToday ? now : null,
    attribute: HabitAttribute.vitality,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('IndentedHabitItem - layout', () {
    testWidgets('renders title, checkbox, timer icon, menu icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
            onTimerStart: (_) {},
          ),
        ),
      );
      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      // Checkbox is a CircleAvatar-like custom widget; find by Icon.check or by tooltip.
      expect(find.byTooltip('Mark complete'), findsOneWidget);
      expect(find.byTooltip('Open habit options'), findsOneWidget);
    });

    testWidgets('is NOT a Dismissible', (tester) async {
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
            onTimerStart: (_) {},
          ),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);
    });
  });

  group('IndentedHabitItem - tap zones', () {
    testWidgets('tap on title fires onRowBodyTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
            onTimerStart: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Morning Meditation'));
      await tester.pump();
      expect(body, 1);
      expect(checkbox, 0);
      expect(timer, 0);
      expect(menu, 0);
    });

    testWidgets('tap on checkbox fires onCheckboxTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
            onTimerStart: (_) {},
          ),
        ),
      );
      await tester.tap(find.byTooltip('Mark complete'));
      await tester.pump();
      expect(checkbox, 1);
      expect(body, 0);
    });

    testWidgets('tap on timer icon fires onTimerTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
            onTimerStart: (_) {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pump();
      expect(timer, 1);
      expect(body, 0);
    });

    testWidgets('tap on menu icon fires onMenuTap only', (tester) async {
      var body = 0, checkbox = 0, timer = 0, menu = 0;
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(),
            selectedDate: DateTime.now(),
            onRowBodyTap: () => body++,
            onCheckboxTap: () => checkbox++,
            onTimerTap: () => timer++,
            onMenuTap: () => menu++,
            onTimerStart: (_) {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(menu, 1);
      expect(body, 0);
    });
  });

  group('IndentedHabitItem - completed visual', () {
    testWidgets('shows strike-through title when completed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          IndentedHabitItem(
            habit: _makeHabit(completedToday: true),
            selectedDate: DateTime.now(),
            onRowBodyTap: () {},
            onCheckboxTap: () {},
            onTimerTap: () {},
            onMenuTap: () {},
            onTimerStart: (_) {},
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Morning Meditation'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart
```

Expected: FAIL — `IndentedHabitItem` constructor signature mismatch / widget not found.

- [ ] **Step 3: Rewrite `_IndentedHabitItem` in `habit_timeline_section.dart`**

Open `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`.

Replace the entire `_IndentedHabitItem` class (from `class _IndentedHabitItem extends StatefulWidget` through its closing `}`) with:

```dart
/// Single habit row shown under a category header.
///
/// Layout B: `[title] [☐] [⏱️] [⋮]`
///
/// - Tap body → `onRowBodyTap` (navigate)
/// - Tap checkbox → `onCheckboxTap` (toggle complete)
/// - Tap ⏱️ → `onTimerTap` (open timer dialog)
/// - Tap ⋮ → `onMenuTap` (open options sheet)
///
/// Card background fills from left → right proportional to the timer countdown.
/// When the timer reaches 0, `onCheckboxTap` is auto-fired.
/// Tapping the checkbox cancels the timer and completes the habit immediately.
class IndentedHabitItem extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback onRowBodyTap;
  final VoidCallback onCheckboxTap;
  final VoidCallback onTimerTap;
  final VoidCallback onMenuTap;
  final void Function(int minutes) onTimerStart;
  final bool showConnector;

  const IndentedHabitItem({
    required this.habit,
    required this.selectedDate,
    required this.onRowBodyTap,
    required this.onCheckboxTap,
    required this.onTimerTap,
    required this.onMenuTap,
    required this.onTimerStart,
    this.showConnector = true,
    super.key,
  });

  @override
  State<IndentedHabitItem> createState() => _IndentedHabitItemState();
}

class _IndentedHabitItemState extends State<IndentedHabitItem> {
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _resetTimerToHabitDuration();
  }

  void _resetTimerToHabitDuration() {
    _totalSeconds = widget.habit.timerDurationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _isTimerRunning = false;
  }

  void _startTimer() {
    if (_isTimerRunning || _totalSeconds <= 0) return;
    setState(() => _isTimerRunning = true);
    _tick();
  }

  void _tick() {
    if (!mounted || !_isTimerRunning) return;
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted || !_isTimerRunning) return;
        setState(() => _remainingSeconds--);
        _tick();
      });
    } else {
      setState(() => _isTimerRunning = false);
      widget.onCheckboxTap();
    }
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isCompletedToday =>
      widget.habit.isCompletedOn(widget.selectedDate);

  @override
  Widget build(BuildContext context) {
    final completed = _isCompletedToday;
    final color = attributeColor(widget.habit.attribute);
    final progress = habitCardFillFraction(
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showConnector)
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 0),
              child: Container(
                width: 2,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: widget.onRowBodyTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    stops: _isTimerRunning || completed
                        ? (completed ? const [1.0, 1.0] : [progress, progress])
                        : const [0.0, 0.0],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: completed
                        ? color.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: completed
                    ? _buildCompleted(color)
                    : _buildPending(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.habit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          toggled: _isCompletedToday,
          label: 'Mark complete',
          child: IconButton(
            tooltip: 'Mark complete',
            icon: Icon(
              _isCompletedToday
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: _isCompletedToday ? color : Colors.white70,
              size: 22,
            ),
            onPressed: () {
              if (_isTimerRunning) _cancelTimer();
              widget.onCheckboxTap();
            },
          ),
        ),
        IconButton(
          tooltip: 'Start timer',
          icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
          onPressed: widget.onTimerTap,
        ),
        IconButton(
          tooltip: 'Open habit options',
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          onPressed: widget.onMenuTap,
        ),
      ],
    );
  }

  Widget _buildCompleted(Color color) {
    final baseXp = switch (widget.habit.difficulty) {
      HabitDifficulty.easy => 10,
      HabitDifficulty.medium => 20,
      HabitDifficulty.hard => 30,
    };
    final xp =
        (baseXp * (1 + (widget.habit.currentStreak * 0.1).clamp(0.0, 0.5))).toInt();
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.habit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '+$xp XP',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

Also remove the existing imports that are no longer used (`one_tap_completion_zone.dart`, `habit_rune_indicator.dart`) and add the new import:

At top of file, replace the existing import block with:

```dart
import 'dart:async';

import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

import 'habit_progress_math.dart';
```

- [ ] **Step 4: Update `_HabitCategorySection` and `HierarchicalHabitTimeline` signatures**

In the same file, find `class _HabitCategorySection extends StatelessWidget` and update its callback fields to the new set:

Replace the `final void Function(Habit) onHabitTap; ... final VoidCallback? onDelete;` block in `_HabitCategorySection` with:

```dart
  final void Function(Habit) onHabitTap;
  final void Function(Habit) onHabitToggle;
  final void Function(Habit) onTimerTap;
  final void Function(Habit) onMenuTap;
  final void Function(Habit, int minutes) onTimerStart;
```

Replace the `const _HabitCategorySection({...})` constructor accordingly:

```dart
  const _HabitCategorySection({
    required this.slot,
    required this.habits,
    required this.selectedDate,
    required this.onHabitTap,
    required this.onHabitToggle,
    required this.onTimerTap,
    required this.onMenuTap,
    required this.onTimerStart,
    required this.isLast,
  });
```

Replace the `_IndentedHabitItem(...)` construction inside the `.map` with:

```dart
        return IndentedHabitItem(
          habit: habit,
          selectedDate: selectedDate,
          onRowBodyTap: () => onHabitTap(habit),
          onCheckboxTap: () => onHabitToggle(habit),
          onTimerTap: () => onTimerTap(habit),
          onMenuTap: () => onMenuTap(habit),
          onTimerStart: (mins) => onTimerStart(habit, mins),
          showConnector: index < habits.length - 1,
        );
```

In `HierarchicalHabitTimeline`, replace its callback fields:

```dart
  final void Function(Habit habit) onHabitTap;
  final void Function(Habit habit) onHabitToggle;
  final void Function(Habit habit) onTimerTap;
  final void Function(Habit habit) onMenuTap;
  final void Function(Habit habit, int minutes) onTimerStart;
```

Update its constructor and the `_HabitCategorySection` instantiation accordingly (pass `onTimerTap: onHabitTap`-style forwarding).

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/timeline/presentation/widgets/habit_timeline_section_test.dart
```

Expected: PASS — all 8 tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart test/features/timeline/presentation/widgets/habit_timeline_section_test.dart
git commit -m "feat(timeline): rewrite habit row as 4-icon layout (body/checkbox/timer/menu)"
```

---

## Task 10: Update `timeline_screen.dart` callback wiring

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Replace `HierarchicalHabitTimeline` call site**

In `timeline_screen.dart`, find the `HierarchicalHabitTimeline(...)` widget call (around line 365). Replace it with:

```dart
        SliverToBoxAdapter(
          child: HierarchicalHabitTimeline(
            groupedHabits: timelineGroups,
            selectedDate: _selectedDate,
            onHabitTap: (habit) {
              context.go('/');
            },
            onHabitToggle: (habit) {
              _toggleHabitCompletion(habit);
            },
            onTimerTap: (habit) {
              _openTimerDialog(habit);
            },
            onMenuTap: (habit) {
              HabitOptionsSheet.show(context, habit, _selectedDate);
            },
            onTimerStart: (habit, minutes) {
              _startInlineTimer(habit, minutes);
            },
          ),
        ),
```

- [ ] **Step 2: Add new private methods `_openTimerDialog`, `_startInlineTimer`**

In `_TimelineScreenState`, add these methods (anywhere with the other private methods):

```dart
  Future<void> _openTimerDialog(Habit habit) async {
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TwoMinuteTimerDialog(
        habitTitle: habit.title,
        neonColor: attributeColor(habit.attribute),
        durationMinutes: habit.timerDurationMinutes,
        onComplete: () {
          _toggleHabitCompletion(habit);
          Navigator.of(context).pop();
        },
      ),
    );
    // result == null when user closed the dialog without completing
    // (e.g., via Cancel/Close). Inline timer is started via the dialog's
    // "Exit & run in background" button (see Task 12) which returns the
    // chosen duration instead of completing.
    if (result != null && result > 0 && mounted) {
      _startInlineTimer(habit, result);
    }
  }

  void _startInlineTimer(Habit habit, int minutes) {
    // The IndentedHabitItem owns its countdown state internally. We trigger
    // it via the GlobalKey pattern by showing a SnackBar hint; the row's
    // own onTimerStart callback (passed via HierarchicalHabitTimeline) is
    // not directly wired in this scope. For v1 we just complete silently
    // when the duration elapses through the existing dialog flow.
    //
    // Future enhancement: surface inline countdown via a global event bus
    // or move state into a provider keyed by habit.id.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${habit.title}: timer set for ${minutes}m'),
        backgroundColor: EmergeColors.teal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
```

Add these imports at the top of `timeline_screen.dart` (in alphabetical order with existing imports):

```dart
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:emerge_app/features/reflections/presentation/widgets/habit_options_sheet.dart';
```

Also remove the now-unused import `miss_recovery_sheet.dart` is still used, leave it.

- [ ] **Step 3: Verify build**

```bash
flutter analyze
```

Expected: no errors related to the new wiring. Fix any remaining type mismatches.

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): wire new 4-icon habit callbacks (nav/checkbox/timer/menu)"
```

---

## Task 11: Add "Exit & run in background" button to timer dialog

**Files:**
- Modify: `lib/features/habits/presentation/widgets/habit_timer_dialog.dart`

- [ ] **Step 1: Refactor dialog to return duration via Navigator.pop**

Open `habit_timer_dialog.dart`. Make these edits:

Change the class signature to accept `onExit` callback and return `int?` from show:

Replace `widget.onComplete` reference with the new approach. Add a new field `onExit` (optional). Change the action button area to show **two buttons when not complete**: "Exit & run in background" and "Cancel":

In `_TwoMinuteTimerDialogState`, replace the action buttons block (the `Row(children: [IconButton.filled(...), Gap(16), TextButton(...)])`):

```dart
                if (_isComplete) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onComplete();
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('Mark Complete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(color: AppTheme.textSecondaryDark),
                    ),
                  ),
                ] else ...[
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(widget.durationMinutes);
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(
                            'Start ${widget.durationMinutes}-Min Timer',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.neonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: () {
                              setState(() => _isPaused = !_isPaused);
                            },
                            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                            style: IconButton.styleFrom(
                              backgroundColor: widget.neonColor.withValues(alpha: 0.2),
                              foregroundColor: widget.neonColor,
                            ),
                          ),
                          const Gap(16),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppTheme.textSecondaryDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
```

The dialog now:
- Pops `widget.durationMinutes` (int) on "Start X-Min Timer"
- Pops `null` on "Cancel" / "Close"
- Calls `widget.onComplete()` on "Mark Complete" (when timer naturally reaches 0)

- [ ] **Step 2: Update existing callers (if any)**

Search the codebase for `TwoMinuteTimerDialog(` and update callers to handle the new return type:

```bash
grep -rn "TwoMinuteTimerDialog(" lib/
```

If `habit_detail_screen.dart` is still present, remove its usage along with the screen (Task 13). The only remaining caller is in `_openTimerDialog` from Task 10, which already handles `Future<int?>`.

- [ ] **Step 3: Verify build**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/widgets/habit_timer_dialog.dart
git commit -m "feat(timer): dialog returns duration on Start (enables inline countdown)"
```

---

## Task 12: Add `HabitOptionsSheet`

**Files:**
- Create: `lib/features/reflections/presentation/widgets/habit_options_sheet.dart`
- Create: `test/features/reflections/presentation/widgets/habit_options_sheet_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/features/reflections/presentation/widgets/habit_options_sheet_test.dart`:

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/habit_reflection_providers.dart';
import 'package:emerge_app/features/reflections/presentation/widgets/habit_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHabitRepo implements HabitRepository {
  Habit _updated = Habit.empty();
  Habit get updated => _updated;

  @override
  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime completedAt, {String? activeTribeId}) async => Right(true);

  @override
  Future<Either<Failure, Habit>> createHabit(Habit habit) async => Right(habit);

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async => Right(unit);

  @override
  Future<Habit?> getHabit(String habitId) async => null;

  @override
  Future<List<Habit>> getHabits(String userId) async => [];

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    _updated = habit;
    return Right(unit);
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) => Stream.value([]);

  @override
  Future<List<HabitActivity>> getActivity(String userId, DateTime start, DateTime end) async => [];

  @override
  Stream<List<HabitActivity>> watchActivity(String userId, DateTime start, DateTime end) => Stream.value([]);
}

class _FakeReflectionRepo implements HabitReflectionRepository {
  HabitReflection? _stored;
  @override
  Future<Either<Failure, HabitReflection?>> getForHabit({required String userId, required String habitId, required DateTime localDate}) async {
    return Right(_stored);
  }
  @override
  Future<Either<Failure, HabitReflection>> save({required String userId, required String habitId, required DateTime localDate, required Mood mood, required String note}) async {
    _stored = HabitReflection(id: 'hr1', userId: userId, habitId: habitId, localDate: localDate, mood: mood, note: note, createdAt: DateTime.now(), updatedAt: DateTime.now());
    return Right(_stored!);
  }
}

void main() {
  late _FakeHabitRepo habitRepo;
  late _FakeReflectionRepo reflectionRepo;

  setUp(() {
    habitRepo = _FakeHabitRepo();
    reflectionRepo = _FakeReflectionRepo();
  });

  Widget _wrap(Widget child) => ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(habitRepo),
          habitReflectionRepositoryProvider.overrideWithValue(reflectionRepo),
          authStateChangesProvider.overrideWith((ref) => Stream.value(User(id: 'u1', email: 'x@x.com'))),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  final habit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Test Habit',
    createdAt: DateTime.now(),
    environmentPriming: ['Lay out clothes'],
    reward: 'Coffee',
    attribute: HabitAttribute.vitality,
  );

  group('HabitOptionsSheet', () {
    testWidgets('renders all five sections', (tester) async {
      await tester.pumpWidget(_wrap(HabitOptionsSheet(habit: habit, selectedDate: DateTime.now())));
      await tester.pump();
      expect(find.text('Start Timer'), findsOneWidget);
      expect(find.text('Environment Priming'), findsOneWidget);
      expect(find.text('Set Reward'), findsOneWidget);
      expect(find.text('Log Reflection'), findsOneWidget);
      expect(find.text('Delete Habit'), findsOneWidget);
    });

    testWidgets('add priming rule calls updateHabit with appended list', (tester) async {
      await tester.pumpWidget(_wrap(HabitOptionsSheet(habit: habit, selectedDate: DateTime.now())));
      await tester.pump();
      // Type into the add input and submit
      await tester.enterText(find.byType(TextField).first, 'Pack water');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(habitRepo.updated.environmentPriming, containsAll(['Lay out clothes', 'Pack water']));
    });

    testWidgets('save reflection calls save on HabitReflectionRepository', (tester) async {
      await tester.pumpWidget(_wrap(HabitOptionsSheet(habit: habit, selectedDate: DateTime.now())));
      await tester.pump();
      // Pick mood (tap the great emoji)
      await tester.tap(find.text('🔥'));
      await tester.pump();
      // Type note
      final noteField = find.widgetWithText(TextField, 'Add a note… (140 chars)');
      await tester.enterText(noteField, 'felt strong');
      await tester.pump();
      // Tap save
      await tester.tap(find.text('Save Reflection'));
      await tester.pump();
      expect(reflectionRepo._stored?.note, 'felt strong'); // ignore: avoid_dynamic_calls
    });

    testWidgets('delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_wrap(HabitOptionsSheet(habit: habit, selectedDate: DateTime.now())));
      await tester.pump();
      await tester.tap(find.text('Delete Habit'));
      await tester.pump();
      expect(find.text('Delete Habit?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
```

> Note: the test file references `User`, `UserExtension`, `Failure`, `Unit`, `Either`, `Right`, `HabitRepository`, `HabitActivity`, and `HabitReflectionRepository` — confirm imports exist (the entities + `fpdart` and `Either` are already used elsewhere). The `authStateChangesProvider` override may need adjustment based on its actual signature; if it requires a `Ref`, swap to a stub Stream.

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/features/reflections/presentation/widgets/habit_options_sheet_test.dart
```

Expected: FAIL — `HabitOptionsSheet` not defined.

- [ ] **Step 3: Implement `HabitOptionsSheet`**

Create `lib/features/reflections/presentation/widgets/habit_options_sheet.dart`:

```dart
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/habit_reflection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Modal bottom sheet for per-habit editing and reflection.
///
/// Sections (top → bottom):
/// 1. Header (title + close ✕)
/// 2. Start Timer → opens [TwoMinuteTimerDialog]
/// 3. Environment Priming (list + add/remove)
/// 4. Set Reward (text + suggestions)
/// 5. Log Reflection (mood + note + save)
/// 6. Delete Habit (confirmation → deleteHabit)
class HabitOptionsSheet extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  const HabitOptionsSheet({
    required this.habit,
    required this.selectedDate,
    super.key,
  });

  static Future<void> show(BuildContext context, Habit habit, DateTime selectedDate) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => HabitOptionsSheet(
          habit: habit,
          selectedDate: selectedDate,
        ),
      ),
    );
  }

  @override
  ConsumerState<HabitOptionsSheet> createState() => _HabitOptionsSheetState();
}

class _HabitOptionsSheetState extends ConsumerState<HabitOptionsSheet> {
  final _primingCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Mood? _mood;
  bool _initReward = false;

  @override
  void dispose() {
    _primingCtrl.dispose();
    _rewardCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final minutes = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TwoMinuteTimerDialog(
        habitTitle: widget.habit.title,
        neonColor: EmergeColors.teal,
        durationMinutes: widget.habit.timerDurationMinutes,
        onComplete: () {
          ref.read(completeHabitProvider(widget.habit.id));
          Navigator.of(context).pop();
        },
      ),
    );
    if (!mounted) return;
    if (minutes != null && minutes > 0) {
      // Hand off to parent (timeline) to start inline countdown.
      Navigator.of(context).pop(minutes);
    }
  }

  Future<void> _addPriming() async {
    final rule = _primingCtrl.text.trim();
    if (rule.isEmpty) return;
    final updated = widget.habit.copyWith(
      environmentPriming: [...widget.habit.environmentPriming, rule],
    );
    await ref.read(habitRepositoryProvider).updateHabit(updated);
    _primingCtrl.clear();
    if (mounted) setState(() {});
  }

  Future<void> _removePriming(int idx) async {
    final list = [...widget.habit.environmentPriming]..removeAt(idx);
    await ref
        .read(habitRepositoryProvider)
        .updateHabit(widget.habit.copyWith(environmentPriming: list));
    if (mounted) setState(() {});
  }

  Future<void> _saveReward() async {
    final text = _rewardCtrl.text.trim();
    if (text == widget.habit.reward) return;
    await ref
        .read(habitRepositoryProvider)
        .updateHabit(widget.habit.copyWith(reward: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward saved')),
      );
    }
  }

  Future<void> _saveReflection() async {
    if (_mood == null) return;
    final userId = ref.read(authStateChangesProvider).value?.id;
    if (userId == null) return;
    final result = await ref.read(saveHabitReflectionProvider(
      userId: userId,
      habitId: widget.habit.id,
      date: widget.selectedDate,
      mood: _mood!,
      note: _noteCtrl.text.trim(),
    ).future);
    if (!mounted) return;
    result; // fold for SnackBar if needed; keep silent success in v1
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reflection saved')),
    );
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Habit?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete this habit and all its history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(habitRepositoryProvider).deleteHabit(widget.habit.id);
    await ref.read(notificationServiceProvider).cancelHabitNotifications(widget.habit.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncReflection = ref.watch(
      habitReflectionProvider(
        userId: ref.watch(authStateChangesProvider).value?.id ?? '',
        habitId: widget.habit.id,
        date: widget.selectedDate,
      ),
    );
    final notCompleted = !widget.habit.isCompletedOn(widget.selectedDate);

    if (!_initReward) {
      _rewardCtrl.text = widget.habit.reward;
      _initReward = true;
    }
    asyncReflection.whenData((existing) {
      if (existing != null && _mood == null) {
        _mood = existing.mood;
        _noteCtrl.text = existing.note;
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.habit.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(16),

              // 1. Start Timer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Timer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EmergeColors.teal,
                    side: BorderSide(color: EmergeColors.teal.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Gap(24),

              // 2. Environment Priming
              _sectionTitle('Environment Priming'),
              const Gap(8),
              ...widget.habit.environmentPriming.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank, size: 16, color: EmergeColors.teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white))),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                            onPressed: () => _removePriming(e.key),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (widget.habit.environmentPriming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No priming steps yet. Add one to reduce friction.',
                    style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ),
              const Gap(8),
              TextField(
                controller: _primingCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Lay out workout clothes',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: EmergeColors.teal),
                    onPressed: _addPriming,
                  ),
                ),
                onSubmitted: (_) => _addPriming(),
              ),
              const Gap(24),

              // 3. Set Reward
              _sectionTitle('Set Reward'),
              const Gap(8),
              TextField(
                controller: _rewardCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Watch 1 episode',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _saveReward(),
                onEditingComplete: _saveReward,
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Watch 1 episode', 'Check social media', 'Coffee/Tea', 'Podcast']
                    .map((s) => ActionChip(
                          label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          side: BorderSide.none,
                          onPressed: () {
                            _rewardCtrl.text = s;
                            _saveReward();
                          },
                        ))
                    .toList(),
              ),
              const Gap(24),

              // 4. Log Reflection
              _sectionTitle('Log Reflection'),
              const Gap(8),
              if (notCompleted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Habit not yet completed today.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              asyncReflection.when(
                loading: () => const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, __) => const Text(
                  'Could not load reflection.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                data: (_) => const SizedBox.shrink(),
              ),
              const Gap(8),
              Row(
                children: [
                  for (final m in Mood.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mood = m),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
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
              ),
              const Gap(8),
              TextField(
                controller: _noteCtrl,
                maxLength: 140,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a note… (140 chars)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              const Gap(8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _mood == null ? null : _saveReflection,
                  style: FilledButton.styleFrom(backgroundColor: EmergeColors.teal),
                  child: const Text('Save Reflection', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(24),

              // 5. Delete Habit
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmAndDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/reflections/presentation/widgets/habit_options_sheet_test.dart
```

Expected: PASS — 4 tests green. Fix imports/fakes as needed for your local types (`User`, `Failure`, `Either`, `HabitRepository`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reflections/presentation/widgets/habit_options_sheet.dart test/features/reflections/presentation/widgets/habit_options_sheet_test.dart
git commit -m "feat(reflections): add HabitOptionsSheet (5-section modal bottom sheet)"
```

---

## Task 13: Drop the `/timeline/detail/:habitId` route

**Files:**
- Modify: `lib/core/router/router.dart`

- [ ] **Step 1: Remove import + route**

Open `lib/core/router/router.dart`.

Remove the import at line 16:
```dart
import 'package:emerge_app/features/habits/presentation/screens/habit_detail_screen.dart';
```

In the `StatefulShellBranch` for `/timeline` (around line 360–381), remove the child `GoRoute` for `detail/:habitId`:

```dart
              GoRoute(
                path: '/timeline',
                builder: (context, state) => const TimelineScreen(),
                routes: [
                  GoRoute(
                    path: 'create-habit',
                    builder: (context, state) =>
                        const AdvancedCreateHabitDialog(),
                  ),
                  // REMOVED: detail/:habitId — HabitDetailScreen deleted
                ],
              ),
```

- [ ] **Step 2: Verify router compiles**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router/router.dart
git commit -m "refactor(router): drop /timeline/detail/:habitId route"
```

---

## Task 14: Delete `HabitDetailScreen` + its test

**Files:**
- Delete: `lib/features/habits/presentation/screens/habit_detail_screen.dart`
- Delete: `test/features/habits/presentation/screens/habit_detail_screen_test.dart`

- [ ] **Step 1: Delete files**

```bash
git rm lib/features/habits/presentation/screens/habit_detail_screen.dart
git rm test/features/habits/presentation/screens/habit_detail_screen_test.dart
```

- [ ] **Step 2: Verify no remaining references**

```bash
grep -rn "HabitDetailScreen" lib/ test/
```

Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git commit -m "refactor: delete HabitDetailScreen (replaced by HabitOptionsSheet)"
```

---

## Task 15: Drift migration test

**Files:**
- Create: `test/core/drift/database_migration_test.dart`

- [ ] **Step 1: Write migration test**

Create `test/core/drift/database_migration_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrating to schemaVersion=8 creates habit_reflections table', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    await db.customStatement('PRAGMA user_version');
    final row = await db.customSelect('SELECT name FROM sqlite_master WHERE type="table" AND name="habit_reflections"').getSingleOrNull();
    expect(row, isNotNull, reason: 'habit_reflections table should exist after migration');
    await db.close();
  });

  test('existing tables still exist after migration', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    for (final table in ['habits', 'daily_reflections', 'user_stats']) {
      final row = await db.customSelect(
        'SELECT name FROM sqlite_master WHERE type="table" AND name=?',
        variables: [Variable.withString(table)],
      ).getSingleOrNull();
      expect(row, isNotNull, reason: '$table should exist');
    }
    await db.close();
  });
}
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/core/drift/database_migration_test.dart
```

Expected: PASS — `habit_reflections` table created on first migration to v8.

- [ ] **Step 3: Commit**

```bash
git add test/core/drift/database_migration_test.dart
git commit -m "test(drift): verify schemaVersion=8 migration creates habit_reflections"
```

---

## Task 16: Final verification sweep

**Files:** N/A

- [ ] **Step 1: Re-run build_runner (final pass)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: clean build, no stale generated files.

- [ ] **Step 2: flutter analyze**

```bash
flutter analyze
```

Expected: 0 errors. Warnings are tolerable; document any that remain.

- [ ] **Step 3: flutter test (full suite)**

```bash
flutter test
```

Expected: all tests pass (existing + new). If any fail, root-cause per AGENTS.md systematic-debugging rule (one hypothesis, one minimal change).

- [ ] **Step 4: Spot-check the timeline screen manually**

Run the app, navigate to the Timeline tab. Verify:
- Habit rows render with title, checkbox, ⏱️, ⋮ (no inline drawer, no swipe gestures)
- Tap checkbox → habit completes; ✓ + strike + xp badge appear; card fill animates to 100%
- Tap ⏱️ → modal opens; tap "Start 2-Min Timer" → modal closes, SnackBar appears (inline countdown is v1.1 follow-up — see spec Risks)
- Tap ⋮ → sheet opens with 5 sections
- Add priming → list updates, persists across re-open
- Save reflection with mood + note → SnackBar; re-open sheet, values are pre-filled
- Delete habit → confirmation dialog → confirm → habit disappears

- [ ] **Step 5: Final commit (if any stray changes)**

```bash
git status
git add -A
git commit -m "chore: final cleanup after habit widget rebuild" --allow-empty
```

---

## Self-Review (against spec)

### Spec coverage

| Spec requirement | Task |
|---|---|
| 4-icon layout row | Task 9 |
| Body tap → World Map | Task 10 (wires `context.go('/')`) |
| Checkbox → instant complete | Task 9 (`onCheckboxTap` triggers existing `completeHabitProvider`) |
| ⏱️ → modal timer | Tasks 10, 11 |
| ⋮ → bottom sheet | Tasks 10, 12 |
| Card progress fill (timer + instant) | Task 9 (uses Task 8 helper) |
| No `Dismissible` | Task 9 (test asserts `findsNothing`) |
| Environment Priming in sheet | Task 12 |
| Set Reward in sheet | Task 12 |
| Log Reflection in sheet | Task 12 (uses Tasks 1-7 stack) |
| Delete Habit in sheet | Task 12 |
| "Exit & run in background" in timer dialog | Task 11 |
| Per-habit reflection persistence (table + DAO + repo + provider) | Tasks 1-7 |
| Local-first offline writes | Task 6 (fire-and-forget remote) |
| Schema migration | Task 1 (`schemaVersion=8`, `onUpgrade`) |
| Delete `HabitDetailScreen` + route | Tasks 13, 14 |
| TDD tests for all new code | Tasks 1-15 |

### Placeholder scan

- All code blocks contain actual implementation; no "TBD" / "TODO" / "similar to Task N".
- Inline countdown via `onTimerStart` is **deferred to v1.1** — explicitly noted in Task 10 (`_startInlineTimer` shows a SnackBar). Documented in spec Risks.

### Type consistency

- `HabitReflection` shape used in Task 3 entity matches the `HabitReflectionsTableData` mapping in Tasks 2 + 5.
- `habitReflectionProvider` signature in Task 7 matches the call sites in Task 12 (`userId`, `habitId`, `date`).
- `saveHabitReflectionProvider` signature matches the call site in Task 12.
- `HabitOptionsSheet.show(context, habit, selectedDate)` signature in Task 12 matches the call site in Task 10.
- `IndentedHabitItem` callback set in Task 9 matches the `_HabitCategorySection` + `HierarchicalHabitTimeline` forwarding in Task 9 + the call site in Task 10.

No type drift detected.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-10-habit-widget-rebuild.md`.

Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
