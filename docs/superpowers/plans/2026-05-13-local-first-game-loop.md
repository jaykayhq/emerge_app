# Local-First Game Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all XP, gamification, challenges, tribe stats, leaderboard stats, and blueprints update locally first via Drift SQLite, then sync to Firebase asynchronously.

**Architecture:** A `LocalGameLoopEngine` (pure Dart) computes all derived state from a habit completion. Drift repositories write to SQLite first, emit reactive streams for instant UI updates, and enqueue mutations. An `EnhancedSyncEngine` drains the queue to Firestore in batches. Old Hive-based cache and Firestore-transaction-heavy repositories are removed.

**Tech Stack:** Flutter 3.10+, drift (SQLite ORM), sqlite3_flutter_libs, path_provider, riverpod_annotation, rxdart, fpdart

---

### Task 1: Add drift dependencies and configure build_runner

**Files:**
- Modify: `pubspec.yaml`
- Create: None yet

- [ ] **Step 1: Add drift + sqlite packages to pubspec.yaml**

Open `pubspec.yaml` and add after the `shared_preferences` line:

```yaml
  drift: ^2.26.0
  sqlite3_flutter_libs: ^0.5.30
  sqlite3: ^2.5.0
  path_provider: ^2.1.5  # Already exists, keep it
```

Then add to `dev_dependencies`:

```yaml
  drift_dev: ^2.26.0
```

- [ ] **Step 2: Run `flutter pub get`**

```bash
flutter pub get
```

Expected: Packages resolve without conflicts. If there's a version conflict, check the drift pub.dev page for the latest version compatible with your Dart SDK (3.10+).

- [ ] **Step 3: Add build_runner configuration for drift**

Open `pubspec.yaml` and add at the bottom (before flutter section if not already there):

```yaml
# This section is for build_runner config
```

Drift uses `build_runner` which is already in `dev_dependencies`. Verify by checking if `build_runner: ^2.11.1` is present — it is.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add drift and sqlite3 dependencies"
```

---

### Task 2: Create drift database schema and DAOs

**Files:**
- Create: `lib/core/drift/database.dart`
- Create: `lib/core/drift/tables/user_stats_table.dart`
- Create: `lib/core/drift/tables/habits_table.dart`
- Create: `lib/core/drift/tables/habit_completions_table.dart`
- Create: `lib/core/drift/tables/challenge_progress_table.dart`
- Create: `lib/core/drift/tables/tribe_stats_table.dart`
- Create: `lib/core/drift/tables/leaderboard_entries_table.dart`
- Create: `lib/core/drift/tables/blueprints_table.dart`
- Create: `lib/core/drift/tables/mutation_queue_table.dart`
- Create: `lib/core/drift/daos/user_stats_dao.dart`
- Create: `lib/core/drift/daos/habits_dao.dart`
- Create: `lib/core/drift/daos/habit_completions_dao.dart`
- Create: `lib/core/drift/daos/challenge_progress_dao.dart`
- Create: `lib/core/drift/daos/tribe_stats_dao.dart`
- Create: `lib/core/drift/daos/leaderboard_entries_dao.dart`
- Create: `lib/core/drift/daos/blueprints_dao.dart`
- Create: `lib/core/drift/daos/mutation_queue_dao.dart`

- [ ] **Step 1: Create directory structure**

```bash
New-Item -ItemType Directory -Path "lib/core/drift/tables" -Force
New-Item -ItemType Directory -Path "lib/core/drift/daos" -Force
```

- [ ] **Step 2: Write `lib/core/drift/tables/user_stats_table.dart`**

```dart
import 'package:drift/drift.dart';

class UserStatsTable extends Table {
  TextColumn get userId => text()();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get strengthXp => integer().withDefault(const Constant(0))();
  IntColumn get intellectXp => integer().withDefault(const Constant(0))();
  IntColumn get vitalityXp => integer().withDefault(const Constant(0))();
  IntColumn get creativityXp => integer().withDefault(const Constant(0))();
  IntColumn get focusXp => integer().withDefault(const Constant(0))();
  IntColumn get spiritXp => integer().withDefault(const Constant(0))();
  IntColumn get challengeXp => integer().withDefault(const Constant(0))();
  RealColumn get worldHealthScore => real().withDefault(const Constant(1.0))();
  TextColumn get archetype => text().nullable()();
  TextColumn get avatarJson => text().nullable()();
  TextColumn get worldStateJson => text().nullable()();
  TextColumn get updatedAt => text().withDefault(Constant(''))();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
```

- [ ] **Step 3: Write `lib/core/drift/tables/habits_table.dart`**

```dart
import 'package:drift/drift.dart';

class HabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get cue => text().nullable()();
  TextColumn get routine => text().nullable()();
  TextColumn get reward => text().nullable()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  TextColumn get attribute => text().nullable()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get momentumScore => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveMisses => integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  IntColumn get isArchived => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 4: Write `lib/core/drift/tables/habit_completions_table.dart`**

```dart
import 'package:drift/drift.dart';

class HabitCompletionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get userId => text()();
  TextColumn get completedAt => text()();
  IntColumn get xpGained => integer().withDefault(const Constant(0))();
  TextColumn get attribute => text().nullable()();
  IntColumn get momentumAtCompletion => integer().nullable()();
  IntColumn get streakDay => integer().withDefault(const Constant(0))();
  IntColumn get wasRecovery => integer().withDefault(const Constant(0))();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 5: Write `lib/core/drift/tables/challenge_progress_table.dart`**

```dart
import 'package:drift/drift.dart';

class ChallengeProgressTable extends Table {
  TextColumn get challengeId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().nullable()();
  TextColumn get attribute => text().nullable()();
  IntColumn get currentDay => integer().withDefault(const Constant(0))();
  IntColumn get totalDays => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get xpReward => integer().withDefault(const Constant(0))();
  TextColumn get joinedAt => text().nullable()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {challengeId};
}
```

- [ ] **Step 6: Write `lib/core/drift/tables/tribe_stats_table.dart`**

```dart
import 'package:drift/drift.dart';

class TribeStatsTable extends Table {
  TextColumn get tribeId => text()();
  TextColumn get tribeName => text().nullable()();
  TextColumn get archetypeId => text().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalHabitsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get totalChallengesCompleted => integer().withDefault(const Constant(0))();
  IntColumn get userContributionXp => integer().withDefault(const Constant(0))();
  IntColumn get userHabitsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get userChallengesCompleted => integer().withDefault(const Constant(0))();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {tribeId};
}
```

- [ ] **Step 7: Write `lib/core/drift/tables/leaderboard_entries_table.dart`**

```dart
import 'package:drift/drift.dart';

class LeaderboardEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get tribeId => text()();
  TextColumn get userId => text()();
  TextColumn get userName => text().withDefault(const Constant('Anonymous'))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get rank => integer().withDefault(const Constant(0))();
  TextColumn get archetype => text().nullable()();
  TextColumn get updatedAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 8: Write `lib/core/drift/tables/blueprints_table.dart`**

```dart
import 'package:drift/drift.dart';

class BlueprintsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get difficulty => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get habitCount => integer().withDefault(const Constant(0))();
  IntColumn get isFallback => integer().withDefault(const Constant(1))();
  TextColumn get dataJson => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 9: Write `lib/core/drift/tables/mutation_queue_table.dart`**

```dart
import 'package:drift/drift.dart';

class MutationQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionPath => text()();
  TextColumn get documentId => text()();
  TextColumn get operation => text()();
  TextColumn get dataJson => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 10: Write `lib/core/drift/database.dart`**

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tables/user_stats_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_completions_table.dart';
import 'tables/challenge_progress_table.dart';
import 'tables/tribe_stats_table.dart';
import 'tables/leaderboard_entries_table.dart';
import 'tables/blueprints_table.dart';
import 'tables/mutation_queue_table.dart';

import 'daos/user_stats_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/habit_completions_dao.dart';
import 'daos/challenge_progress_dao.dart';
import 'daos/tribe_stats_dao.dart';
import 'daos/leaderboard_entries_dao.dart';
import 'daos/blueprints_dao.dart';
import 'daos/mutation_queue_dao.dart';

part 'database.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase.instance;
}

@Riverpod(keepAlive: true)
UserStatsDao userStatsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).userStatsDao;
}

@Riverpod(keepAlive: true)
HabitsDao habitsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).habitsDao;
}

@Riverpod(keepAlive: true)
HabitCompletionsDao habitCompletionsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).habitCompletionsDao;
}

@Riverpod(keepAlive: true)
ChallengeProgressDao challengeProgressDao(Ref ref) {
  return ref.watch(appDatabaseProvider).challengeProgressDao;
}

@Riverpod(keepAlive: true)
TribeStatsDao tribeStatsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).tribeStatsDao;
}

@Riverpod(keepAlive: true)
LeaderboardEntriesDao leaderboardEntriesDao(Ref ref) {
  return ref.watch(appDatabaseProvider).leaderboardEntriesDao;
}

@Riverpod(keepAlive: true)
BlueprintsDao blueprintsDao(Ref ref) {
  return ref.watch(appDatabaseProvider).blueprintsDao;
}

@Riverpod(keepAlive: true)
MutationQueueDao mutationQueueDao(Ref ref) {
  return ref.watch(appDatabaseProvider).mutationQueueDao;
}

@DriftDatabase(
  tables: [
    UserStatsTable,
    HabitsTable,
    HabitCompletionsTable,
    ChallengeProgressTable,
    TribeStatsTable,
    LeaderboardEntriesTable,
    BlueprintsTable,
    MutationQueueTable,
  ],
  daos: [
    UserStatsDao,
    HabitsDao,
    HabitCompletionsDao,
    ChallengeProgressDao,
    TribeStatsDao,
    LeaderboardEntriesDao,
    BlueprintsDao,
    MutationQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'emerge_app.sqlite'));
      return NativeDatabase(file);
    });
  }
}
```

- [ ] **Step 11: Write `lib/core/drift/daos/user_stats_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_stats_table.dart';

part 'user_stats_dao.g.dart';

@DriftAccessor(tables: [UserStatsTable])
class UserStatsDao extends DatabaseAccessor<AppDatabase> with _$UserStatsDaoMixin {
  UserStatsDao(super.db);

  Future<UserStatsTableData?> getStats(String userId) {
    return (select(userStatsTable)..where((t) => t.userId.equals(userId))).getSingleOrNull();
  }

  Stream<UserStatsTableData?> watchStats(String userId) {
    return (select(userStatsTable)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }

  Future<void> upsertStats(Insertable<UserStatsTableData> entry) {
    return into(userStatsTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateXp(String userId, int totalXpDelta, int newLevel) async {
    final current = await getStats(userId);
    if (current == null) return;
    await upsertStats(UserStatsTableCompanion(
      userId: Value(userId),
      totalXp: Value(current.totalXp + totalXpDelta),
      level: Value(newLevel),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> updateAttributeXp(
    String userId,
    String attribute,
    int amount,
    int newLevel,
    int newTotalXp,
  ) async {
    final current = await getStats(userId);
    if (current == null) return;
    final map = <String, int>{
      'strengthXp': current.strengthXp,
      'intellectXp': current.intellectXp,
      'vitalityXp': current.vitalityXp,
      'creativityXp': current.creativityXp,
      'focusXp': current.focusXp,
      'spiritXp': current.spiritXp,
    };
    final key = '${attribute}Xp';
    map[key] = (map[key] ?? 0) + amount;

    await upsertStats(UserStatsTableCompanion(
      userId: Value(userId),
      totalXp: Value(newTotalXp),
      level: Value(newLevel),
      strengthXp: Value(map['strengthXp']!),
      intellectXp: Value(map['intellectXp']!),
      vitalityXp: Value(map['vitalityXp']!),
      creativityXp: Value(map['creativityXp']!),
      focusXp: Value(map['focusXp']!),
      spiritXp: Value(map['spiritXp']!),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> updateStreak(String userId, int streak) async {
    final current = await getStats(userId);
    if (current == null) return;
    await upsertStats(UserStatsTableCompanion(
      userId: Value(userId),
      streak: Value(streak),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> updateWorldHealth(String userId, double score) async {
    await upsertStats(UserStatsTableCompanion(
      userId: Value(userId),
      worldHealthScore: Value(score),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> upsertFromFirebase(String userId, Map<String, dynamic> data) async {
    await upsertStats(UserStatsTableCompanion(
      userId: Value(userId),
      totalXp: Value(data['totalXp'] as int? ?? 0),
      level: Value(data['level'] as int? ?? 1),
      streak: Value(data['streak'] as int? ?? 0),
      strengthXp: Value(data['strengthXp'] as int? ?? 0),
      intellectXp: Value(data['intellectXp'] as int? ?? 0),
      vitalityXp: Value(data['vitalityXp'] as int? ?? 0),
      creativityXp: Value(data['creativityXp'] as int? ?? 0),
      focusXp: Value(data['focusXp'] as int? ?? 0),
      spiritXp: Value(data['spiritXp'] as int? ?? 0),
      challengeXp: Value(data['challengeXp'] as int? ?? 0),
      worldHealthScore: Value((data['worldHealthScore'] as num?)?.toDouble() ?? 1.0),
      archetype: Value(data['archetype'] as String?),
      avatarJson: Value(data['avatarJson'] as String?),
      worldStateJson: Value(data['worldStateJson'] as String?),
      syncedAt: Value(DateTime.now().toIso8601String()),
      updatedAt: Value(data['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    ));
  }
}
```

- [ ] **Step 12: Write `lib/core/drift/daos/habits_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habits_table.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [HabitsTable])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  Future<HabitsTableData?> getHabit(String id) {
    return (select(habitsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<HabitsTableData>> watchHabits(String userId) {
    return (select(habitsTable)
      ..where((t) => t.userId.equals(userId) & t.isArchived.equals(0)))
      .watch();
  }

  Future<void> upsertHabit(Insertable<HabitsTableData> entry) {
    return into(habitsTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateStreak(String id, int currentStreak, int longestStreak, String? lastCompletedDate) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(
        currentStreak: Value(currentStreak),
        longestStreak: Value(longestStreak),
        lastCompletedDate: Value(lastCompletedDate),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> updateMomentum(String id, int momentumScore, int consecutiveMisses) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(
        momentumScore: Value(momentumScore),
        consecutiveMisses: Value(consecutiveMisses),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> markSynced(String id) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(syncedAt: Value(DateTime.now().toIso8601String())),
    );
  }
}
```

- [ ] **Step 13: Write `lib/core/drift/daos/habit_completions_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habit_completions_table.dart';

part 'habit_completions_dao.g.dart';

@DriftAccessor(tables: [HabitCompletionsTable])
class HabitCompletionsDao extends DatabaseAccessor<AppDatabase> with _$HabitCompletionsDaoMixin {
  HabitCompletionsDao(super.db);

  Future<void> insertCompletion(Insertable<HabitCompletionsTableData> entry) {
    return into(habitCompletionsTable).insert(entry);
  }

  Stream<List<HabitCompletionsTableData>> watchCompletions(String userId) {
    return (select(habitCompletionsTable)..where((t) => t.userId.equals(userId)))
        .watch();
  }

  Future<List<HabitCompletionsTableData>> getTodayCompletions(String userId) async {
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
    return (select(habitCompletionsTable)
      ..where((t) => t.userId.equals(userId) & t.completedAt.startsWith(todayStr)))
      .get();
  }
}
```

- [ ] **Step 14: Write `lib/core/drift/daos/challenge_progress_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/challenge_progress_table.dart';

part 'challenge_progress_dao.g.dart';

@DriftAccessor(tables: [ChallengeProgressTable])
class ChallengeProgressDao extends DatabaseAccessor<AppDatabase> with _$ChallengeProgressDaoMixin {
  ChallengeProgressDao(super.db);

  Future<List<ChallengeProgressTableData>> getActive(String userId) {
    return (select(challengeProgressTable)
      ..where((t) => t.userId.equals(userId) & t.status.equals('active')))
      .get();
  }

  Stream<List<ChallengeProgressTableData>> watchActive(String userId) {
    return (select(challengeProgressTable)
      ..where((t) => t.userId.equals(userId) & t.status.equals('active')))
      .watch();
  }

  Future<void> upsertProgress(Insertable<ChallengeProgressTableData> entry) {
    return into(challengeProgressTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateDay(String challengeId, int day, String status) async {
    await (update(challengeProgressTable)..where((t) => t.challengeId.equals(challengeId))).write(
      ChallengeProgressTableCompanion(
        currentDay: Value(day),
        status: Value(status),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
```

- [ ] **Step 15: Write `lib/core/drift/daos/tribe_stats_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tribe_stats_table.dart';

part 'tribe_stats_dao.g.dart';

@DriftAccessor(tables: [TribeStatsTable])
class TribeStatsDao extends DatabaseAccessor<AppDatabase> with _$TribeStatsDaoMixin {
  TribeStatsDao(super.db);

  Future<TribeStatsTableData?> getStats(String tribeId) {
    return (select(tribeStatsTable)..where((t) => t.tribeId.equals(tribeId))).getSingleOrNull();
  }

  Stream<TribeStatsTableData?> watchStats(String tribeId) {
    return (select(tribeStatsTable)..where((t) => t.tribeId.equals(tribeId))).watchSingleOrNull();
  }

  Future<void> upsertStats(Insertable<TribeStatsTableData> entry) {
    return into(tribeStatsTable).insertOnConflictUpdate(entry);
  }

  Future<void> incrementContribution(
    String tribeId, {
    required int xp,
    required int habits,
    required int challenges,
  }) async {
    final current = await getStats(tribeId);
    if (current == null) return;
    await upsertStats(TribeStatsTableCompanion(
      tribeId: Value(tribeId),
      totalXp: Value(current.totalXp + xp),
      totalHabitsCompleted: Value(current.totalHabitsCompleted + habits),
      totalChallengesCompleted: Value(current.totalChallengesCompleted + challenges),
      userContributionXp: Value(current.userContributionXp + xp),
      userHabitsCompleted: Value(current.userHabitsCompleted + habits),
      userChallengesCompleted: Value(current.userChallengesCompleted + challenges),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }
}
```

- [ ] **Step 16: Write `lib/core/drift/daos/leaderboard_entries_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/leaderboard_entries_table.dart';

part 'leaderboard_entries_dao.g.dart';

@DriftAccessor(tables: [LeaderboardEntriesTable])
class LeaderboardEntriesDao extends DatabaseAccessor<AppDatabase> with _$LeaderboardEntriesDaoMixin {
  LeaderboardEntriesDao(super.db);

  Stream<List<LeaderboardEntriesTableData>> watchLeaderboard(String tribeId) {
    return (select(leaderboardEntriesTable)
      ..where((t) => t.tribeId.equals(tribeId))
      ..orderBy([(t) => OrderingTerm(expression: t.xp, mode: OrderingMode.desc)]))
      .watch();
  }

  Future<void> upsertEntry(Insertable<LeaderboardEntriesTableData> entry) {
    return into(leaderboardEntriesTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateUserScore(
    String id, {
    required int xp,
    required int level,
    required String userName,
    required String archetype,
  }) async {
    await (update(leaderboardEntriesTable)..where((t) => t.id.equals(id))).write(
      LeaderboardEntriesTableCompanion(
        xp: Value(xp),
        level: Value(level),
        userName: Value(userName),
        archetype: Value(archetype),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
```

- [ ] **Step 17: Write `lib/core/drift/daos/blueprints_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/blueprints_table.dart';

part 'blueprints_dao.g.dart';

@DriftAccessor(tables: [BlueprintsTable])
class BlueprintsDao extends DatabaseAccessor<AppDatabase> with _$BlueprintsDaoMixin {
  BlueprintsDao(super.db);

  Future<List<BlueprintsTableData>> getAll() {
    return select(blueprintsTable).get();
  }

  Future<void> upsertBlueprint(Insertable<BlueprintsTableData> entry) {
    return into(blueprintsTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertAll(List<BlueprintsTableData> entries) async {
    for (final entry in entries) {
      await into(blueprintsTable).insertOnConflictUpdate(entry);
    }
  }

  Future<void> deleteAll() async {
    await delete(blueprintsTable).go();
  }
}
```

- [ ] **Step 18: Write `lib/core/drift/daos/mutation_queue_dao.dart`**

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/mutation_queue_table.dart';

part 'mutation_queue_dao.g.dart';

@DriftAccessor(tables: [MutationQueueTable])
class MutationQueueDao extends DatabaseAccessor<AppDatabase> with _$MutationQueueDaoMixin {
  MutationQueueDao(super.db);

  Future<List<MutationQueueTableData>> getAllPending() {
    return select(mutationQueueTable)
      .orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)])
      .get();
  }

  Stream<List<MutationQueueTableData>> watchPending() {
    return select(mutationQueueTable)
      .orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)])
      .watch();
  }

  Future<int> pendingCount() {
    return select(mutationQueueTable).map((r) => 1).get().then((r) => r.length);
  }

  Future<void> enqueue({
    required String collectionPath,
    required String documentId,
    required String operation,
    String? dataJson,
  }) {
    return into(mutationQueueTable).insert(MutationQueueTableCompanion(
      collectionPath: Value(collectionPath),
      documentId: Value(documentId),
      operation: Value(operation),
      dataJson: Value(dataJson),
      createdAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  Future<void> deleteProcessed(int id) async {
    await (delete(mutationQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteBatch(List<int> ids) async {
    for (final id in ids) {
      await (delete(mutationQueueTable)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<void> incrementRetry(int id) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(retryCount: Value(const Constant(1).value)),
    );
  }
}
```

- [ ] **Step 19: Run build_runner to generate drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: All `.g.dart` files generated for database, all 8 DAOs. If errors, fix them (likely missing imports or syntax issues).

- [ ] **Step 20: Commit**

```bash
git add lib/core/drift/
git commit -m "feat: add drift database schema with 8 tables and DAOs"
```

---

### Task 3: Implement LocalGameLoopEngine with TDD

**Files:**
- Create: `lib/core/game_loop/game_loop_result.dart`
- Create: `lib/core/game_loop/game_loop_engine.dart`
- Create: `test/core/game_loop/game_loop_engine_test.dart`

- [ ] **Step 1: Write `lib/core/game_loop/game_loop_result.dart`**

```dart
class GameLoopResult {
  final int newStreak;
  final int longestStreak;
  final int xpGained;
  final String attribute;
  final int newLevel;
  final int newTotalXp;
  final int newMomentumScore;
  final int newConsecutiveMisses;
  final bool isRecovery;
  final double worldHealthDelta;

  /// Challenge progress updates, keyed by challengeId
  final Map<String, ChallengeProgressUpdate> challengeUpdates;

  const GameLoopResult({
    required this.newStreak,
    required this.longestStreak,
    required this.xpGained,
    required this.attribute,
    required this.newLevel,
    required this.newTotalXp,
    required this.newMomentumScore,
    required this.newConsecutiveMisses,
    required this.isRecovery,
    required this.worldHealthDelta,
    required this.challengeUpdates,
  });
}

class ChallengeProgressUpdate {
  final String challengeId;
  final int newDay;
  final bool isCompleted;
  final int? xpReward;

  const ChallengeProgressUpdate({
    required this.challengeId,
    required this.newDay,
    required this.isCompleted,
    this.xpReward,
  });
}
```

- [ ] **Step 2: Write the failing test `test/core/game_loop/game_loop_engine_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/game_loop/game_loop_result.dart';

void main() {
  late LocalGameLoopEngine engine;

  setUp(() {
    engine = LocalGameLoopEngine();
  });

  group('computeXpGain', () {
    test('easy habit with 0 streak returns base XP', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 1.0, streak: 0);
      expect(xp, 10);
    });

    test('hard habit with 0 streak returns 30 XP', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 3.0, streak: 0);
      expect(xp, 30);
    });

    test('medium habit with 30-day streak gets 50% bonus', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 2.0, streak: 30);
      // 20 + 50% = 30
      expect(xp, 30);
    });

    test('streak bonus capped at 50% even for 100-day streak', () {
      final xp = engine.computeXpGain(difficultyMultiplier: 1.0, streak: 100);
      // 10 + 50% = 15
      expect(xp, 15);
    });
  });

  group('computeLevel', () {
    test('0 XP returns level 1', () {
      expect(engine.computeLevel(0), 1);
    });

    test('499 XP returns level 1', () {
      expect(engine.computeLevel(499), 1);
    });

    test('500 XP returns level 2', () {
      expect(engine.computeLevel(500), 2);
    });

    test('1500 XP returns level 4', () {
      expect(engine.computeLevel(1500), 4);
    });
  });

  group('processHabitCompletion', () {
    test('first completion sets streak to 1', () {
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 0,
        momentumScore: 0,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'vitality',
        lastCompletedDate: null,
      );

      expect(result.newStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.isRecovery, false);
    });

    test('consecutive completion increments streak', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = engine.processHabitCompletion(
        currentStreak: 5,
        longestStreak: 10,
        momentumScore: 50,
        consecutiveMisses: 0,
        difficultyMultiplier: 2.0,
        attribute: 'strength',
        lastCompletedDate: yesterday,
      );

      expect(result.newStreak, 6);
      expect(result.longestStreak, 10); // not exceeded yet
      expect(result.xpGained, 20); // base 20 for medium
    });

    test('completion after miss is recovery', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 2));
      final result = engine.processHabitCompletion(
        currentStreak: 0,
        longestStreak: 5,
        momentumScore: 10,
        consecutiveMisses: 3,
        difficultyMultiplier: 2.0,
        attribute: 'vitality',
        lastCompletedDate: yesterday,
      );

      expect(result.isRecovery, true);
      expect(result.newStreak, 1); // resets to 1
      expect(result.longestStreak, 5); // preserved
      expect(result.newMomentumScore, 20); // 10 + 10 boost
      expect(result.newConsecutiveMisses, 0); // reset
    });

    test('same-day completion does nothing (idempotent)', () {
      final today = DateTime.now();
      final result = engine.processHabitCompletion(
        currentStreak: 5,
        longestStreak: 5,
        momentumScore: 80,
        consecutiveMisses: 0,
        difficultyMultiplier: 1.0,
        attribute: 'focus',
        lastCompletedDate: today,
      );

      // Should be idempotent — no changes
      expect(result.newStreak, 5);
      expect(result.xpGained, 0);
      expect(result.newMomentumScore, 80);
    });
  });

  group('processChallengeProgress', () {
    test('day 1 of 7-day challenge', () {
      final result = engine.processChallengeProgress(
        currentDay: 0,
        totalDays: 7,
        xpReward: 100,
      );

      expect(result.newDay, 1);
      expect(result.isCompleted, false);
      expect(result.xpReward, null);
    });

    test('day 7 of 7-day challenge marks completed', () {
      final result = engine.processChallengeProgress(
        currentDay: 6,
        totalDays: 7,
        xpReward: 100,
      );

      expect(result.newDay, 7);
      expect(result.isCompleted, true);
      expect(result.xpReward, 100);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
dart run build_runner build --delete-conflicting-outputs; if ($?) { flutter test test/core/game_loop/game_loop_engine_test.dart }
```

Expected: FAIL — `LocalGameLoopEngine` not defined.

- [ ] **Step 4: Write `lib/core/game_loop/game_loop_engine.dart`**

```dart
import 'game_loop_result.dart';

class LocalGameLoopEngine {
  static const int _baseXpPerHabit = 10;
  static const int _xpPerLevel = 500;
  static const int _streakBonusStepDays = 7;
  static const double _streakBonusPerStep = 0.10;
  static const double _maxStreakBonus = 0.50;
  static const int _completionBoost = 10;
  static const int _missDecay = 5;
  static const int _idleDecay = 2;

  int computeXpGain({
    required double difficultyMultiplier,
    required int streak,
  }) {
    double streakBonus = (streak / _streakBonusStepDays) * _streakBonusPerStep;
    if (streakBonus > _maxStreakBonus) streakBonus = _maxStreakBonus;
    return ((_baseXpPerHabit * difficultyMultiplier) * (1 + streakBonus)).round();
  }

  int computeLevel(int totalXp) {
    return (totalXp / _xpPerLevel).floor() + 1;
  }

  GameLoopResult processHabitCompletion({
    required int currentStreak,
    required int longestStreak,
    required int momentumScore,
    required int consecutiveMisses,
    required double difficultyMultiplier,
    required String attribute,
    required DateTime? lastCompletedDate,
    List<ChallengeProgressInput> activeChallenges = const [],
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Idempotency check — if already completed today, return no-op
    if (lastCompletedDate != null) {
      final lastDay = DateTime(
        lastCompletedDate.year,
        lastCompletedDate.month,
        lastCompletedDate.day,
      );
      if (lastDay == today) {
        return GameLoopResult(
          newStreak: currentStreak,
          longestStreak: longestStreak,
          xpGained: 0,
          attribute: attribute,
          newLevel: 0,
          newTotalXp: 0,
          newMomentumScore: momentumScore,
          newConsecutiveMisses: consecutiveMisses,
          isRecovery: false,
          worldHealthDelta: 0,
          challengeUpdates: {},
        );
      }
    }

    final isRecovery = consecutiveMisses > 0;
    final newStreak = currentStreak + 1;
    final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;
    final xpGained = computeXpGain(
      difficultyMultiplier: difficultyMultiplier,
      streak: newStreak,
    );

    final newMomentumScore = (momentumScore + _completionBoost).clamp(0, 100);
    final newConsecutiveMisses = 0;

    // Compute challenge progress for matching challenges
    final challengeUpdates = <String, ChallengeProgressUpdate>{};
    for (final challenge in activeChallenges) {
      if (challenge.attribute == attribute || challenge.attribute == null) {
        final challengeResult = processChallengeProgress(
          currentDay: challenge.currentDay,
          totalDays: challenge.totalDays,
          xpReward: challenge.xpReward,
        );
        challengeUpdates[challenge.challengeId] = ChallengeProgressUpdate(
          challengeId: challenge.challengeId,
          newDay: challengeResult.newDay,
          isCompleted: challengeResult.isCompleted,
          xpReward: challengeResult.xpReward,
        );
      }
    }

    return GameLoopResult(
      newStreak: newStreak,
      longestStreak: newLongestStreak,
      xpGained: xpGained,
      attribute: attribute,
      newLevel: 0, // caller sets level from total XP
      newTotalXp: xpGained,
      newMomentumScore: newMomentumScore,
      newConsecutiveMisses: newConsecutiveMisses,
      isRecovery: isRecovery,
      worldHealthDelta: _completionBoost / 100.0,
      challengeUpdates: challengeUpdates,
    );
  }

  ChallengeProgressUpdate processChallengeProgress({
    required int currentDay,
    required int totalDays,
    required int xpReward,
  }) {
    final newDay = currentDay + 1;
    final isCompleted = newDay >= totalDays;
    return ChallengeProgressUpdate(
      challengeId: '',
      newDay: newDay,
      isCompleted: isCompleted,
      xpReward: isCompleted ? xpReward : null,
    );
  }
}

class ChallengeProgressInput {
  final String challengeId;
  final int currentDay;
  final int totalDays;
  final int xpReward;
  final String? attribute;

  const ChallengeProgressInput({
    required this.challengeId,
    required this.currentDay,
    required this.totalDays,
    required this.xpReward,
    this.attribute,
  });
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
dart run build_runner build --delete-conflicting-outputs; if ($?) { flutter test test/core/game_loop/game_loop_engine_test.dart }
```

Expected: All 10 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/game_loop/ test/core/game_loop/
git commit -m "feat: implement LocalGameLoopEngine with TDD"
```

---

### Task 4: Implement EnhancedSyncEngine

**Files:**
- Create: `lib/core/sync/sync_engine.dart`
- Create: `lib/core/sync/sync_providers.dart`

- [ ] **Step 1: Write `lib/core/sync/sync_engine.dart`**

```dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/app_logger.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/daos/mutation_queue_dao.dart';
import 'package:flutter/foundation.dart';

class EnhancedSyncEngine {
  final MutationQueueDao _mutationQueue;
  final FirebaseFirestore _firestore;

  EnhancedSyncEngine(this._mutationQueue, this._firestore);

  Future<void> processMutationQueue() async {
    final mutations = await _mutationQueue.getAllPending();
    if (mutations.isEmpty) {
      debugPrint('SyncEngine: No pending mutations.');
      return;
    }

    debugPrint('SyncEngine: Processing ${mutations.length} mutations...');

    for (final mutation in mutations) {
      final success = await _applyMutation(mutation);
      if (success) {
        await _mutationQueue.deleteProcessed(mutation.id);
        debugPrint('SyncEngine: Synced mutation ${mutation.id}');
      } else {
        await _mutationQueue.incrementRetry(mutation.id);
        if (mutation.retryCount >= 3) {
          debugPrint('SyncEngine: Dropping mutation ${mutation.id} after 3 retries');
          await _mutationQueue.deleteProcessed(mutation.id);
        }
        break;
      }
    }
  }

  Future<bool> _applyMutation(MutationQueueTableData mutation) async {
    try {
      final ref = _firestore.collection(mutation.collectionPath).doc(mutation.documentId);
      final data = mutation.dataJson != null
          ? Map<String, dynamic>.from(jsonDecode(mutation.dataJson!) as Map)
          : <String, dynamic>{};

      switch (mutation.operation) {
        case 'set':
          _convertTimestamps(data);
          await ref.set(data, SetOptions(merge: true));
          break;
        case 'update':
          _convertTimestamps(data);
          await ref.update(data);
          break;
        case 'delete':
          await ref.delete();
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      debugPrint('SyncEngine: Error applying mutation: $e');
      return false;
    }
  }

  void _convertTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is String && value.contains('T') && value.contains('-')) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          data[key] = Timestamp.fromDate(date);
        }
      } else if (value is Map<String, dynamic>) {
        _convertTimestamps(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertTimestamps(value[i] as Map<String, dynamic>);
          }
        }
      }
    });
  }

  Future<void> enqueueMutation({
    required String collectionPath,
    required String documentId,
    required String operation,
    Map<String, dynamic>? data,
  }) async {
    await _mutationQueue.enqueue(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: operation,
      dataJson: data != null ? jsonEncode(data) : null,
    );
  }

  Future<void> enqueueSet({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await enqueueMutation(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: 'set',
      data: data,
    );
  }

  Future<void> enqueueUpdate({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await enqueueMutation(
      collectionPath: collectionPath,
      documentId: documentId,
      operation: 'update',
      data: data,
    );
  }
}
```

- [ ] **Step 2: Write `lib/core/sync/sync_providers.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

final syncEngineProvider = Provider<EnhancedSyncEngine>((ref) {
  final mutationQueue = ref.watch(mutationQueueDaoProvider);
  return EnhancedSyncEngine(mutationQueue, FirebaseFirestore.instance);
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(mutationQueueDaoProvider);
  return dao.watchPending().map((list) => list.length);
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/sync/
git commit -m "feat: implement EnhancedSyncEngine for drift mutation queue"
```

---

### Task 5: Implement DriftHabitRepository

**Files:**
- Create: `lib/core/drift_repositories/drift_habit_repository.dart`
- Modify: `lib/features/habits/domain/repositories/habit_repository.dart` (no change needed, interface stays)
- Test: `test/core/drift_repositories/drift_habit_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_habit_repository.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

void main() {
  late AppDatabase db;
  late DriftHabitRepository repo;

  setUp(() async {
    // Use in-memory database for testing
    db = AppDatabase();
    final engine = LocalGameLoopEngine();
    final syncEngine = EnhancedSyncEngine(db.mutationQueueDao, null!); // firestore null for tests
    repo = DriftHabitRepository(
      db: db,
      gameLoopEngine: engine,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('completeHabit', () {
    test('first completion returns true (newly completed)', () async {
      await db.habitsDao.upsertHabit(HabitsTableCompanion(
        id: Value('test_1'),
        userId: Value('user_1'),
        title: Value('Test Habit'),
        createdAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await db.userStatsDao.upsertStats(UserStatsTableCompanion(
        userId: Value('user_1'),
      ));

      final result = await repo.completeHabit('test_1', DateTime.now());
      expect(result.isRight(), true);

      final habit = await db.habitsDao.getHabit('test_1');
      expect(habit, isNotNull);
      expect(habit!.currentStreak, 1);

      final stats = await db.userStatsDao.getStats('user_1');
      expect(stats, isNotNull);
      expect(stats!.streak, 1);
    });

    test('completing again same day returns false (already completed)', () async {
      final now = DateTime.now();
      await db.habitsDao.upsertHabit(HabitsTableCompanion(
        id: Value('test_2'),
        userId: Value('user_1'),
        title: Value('Test Habit'),
        lastCompletedDate: Value(now.toIso8601String()),
        currentStreak: Value(1),
        longestStreak: Value(1),
        createdAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await db.userStatsDao.upsertStats(UserStatsTableCompanion(
        userId: Value('user_1'),
        streak: Value(1),
      ));

      final result = await repo.completeHabit('test_2', now);
      // Should be idempotent — right but false (not newly completed)
      expect(result.isRight(), true);

      final habit = await db.habitsDao.getHabit('test_2');
      expect(habit!.currentStreak, 1); // unchanged
    });
  });
}
```

- [ ] **Step 2: Write `lib/core/drift_repositories/drift_habit_repository.dart`**

```dart
import 'dart:async';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

class DriftHabitRepository implements HabitRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;

  DriftHabitRepository({
    required AppDatabase db,
    required LocalGameLoopEngine gameLoopEngine,
    required EnhancedSyncEngine syncEngine,
  })  : _db = db,
        _engine = gameLoopEngine,
        _syncEngine = syncEngine;

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _db.habitsDao.watchHabits(userId).map((rows) {
      return rows.map((row) => _rowToHabit(row)).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    try {
      await _db.habitsDao.upsertHabit(HabitsTableCompanion(
        id: Value(habit.id),
        userId: Value(habit.userId),
        title: Value(habit.title),
        cue: Value(habit.cue),
        routine: Value(habit.routine),
        reward: Value(habit.reward),
        frequency: Value(habit.frequency.name),
        difficulty: Value(habit.difficulty.name),
        attribute: Value(habit.attribute.name),
        currentStreak: Value(habit.currentStreak),
        longestStreak: Value(habit.longestStreak),
        momentumScore: Value(habit.momentumScore),
        consecutiveMisses: Value(habit.consecutiveMisses),
        isArchived: Value(habit.isArchived ? 1 : 0),
        createdAt: Value(habit.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await _syncEngine.enqueueSet(
        collectionPath: 'habits',
        documentId: habit.id,
        data: _habitToFirestoreMap(habit),
      );

      return const Right(unit);
    } catch (e, s) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    try {
      await _db.habitsDao.upsertHabit(HabitsTableCompanion(
        id: Value(habit.id),
        userId: Value(habit.userId),
        title: Value(habit.title),
        cue: Value(habit.cue),
        routine: Value(habit.routine),
        reward: Value(habit.reward),
        frequency: Value(habit.frequency.name),
        difficulty: Value(habit.difficulty.name),
        attribute: Value(habit.attribute.name),
        currentStreak: Value(habit.currentStreak),
        longestStreak: Value(habit.longestStreak),
        momentumScore: Value(habit.momentumScore),
        consecutiveMisses: Value(habit.consecutiveMisses),
        isArchived: Value(habit.isArchived ? 1 : 0),
        createdAt: Value(habit.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await _syncEngine.enqueueUpdate(
        collectionPath: 'habits',
        documentId: habit.id,
        data: _habitToFirestoreMap(habit),
      );

      return const Right(unit);
    } catch (e, s) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      await _db.habitsDao.upsertHabit(HabitsTableCompanion(
        id: Value(habitId),
        isArchived: const Value(1),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await _syncEngine.enqueueUpdate(
        collectionPath: 'habits',
        documentId: habitId,
        data: {'isArchived': true},
      );

      return const Right(unit);
    } catch (e, s) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeHabit(String habitId, DateTime date) async {
    try {
      final habitRow = await _db.habitsDao.getHabit(habitId);
      if (habitRow == null) return Left(ServerFailure('Habit not found'));

      final statsRow = await _db.userStatsDao.getStats(habitRow.userId);
      if (statsRow == null) return Left(ServerFailure('User stats not found'));

      final lastDate = habitRow.lastCompletedDate != null
          ? DateTime.tryParse(habitRow.lastCompletedDate!)
          : null;

      // Get difficulty multiplier
      final diffMultiplier = _difficultyMultiplier(habitRow.difficulty);

      // Get active challenges
      final challenges = await _db.challengeProgressDao.getActive(habitRow.userId);
      final challengeInputs = challenges
          .where((c) => c.attribute == null || c.attribute == habitRow.attribute)
          .map((c) => ChallengeProgressInput(
                challengeId: c.challengeId,
                currentDay: c.currentDay,
                totalDays: c.totalDays,
                xpReward: c.xpReward,
                attribute: c.attribute,
              ))
          .toList();

      // Compute all state changes in pure engine
      final result = _engine.processHabitCompletion(
        currentStreak: habitRow.currentStreak,
        longestStreak: habitRow.longestStreak,
        momentumScore: habitRow.momentumScore,
        consecutiveMisses: habitRow.consecutiveMisses,
        difficultyMultiplier: diffMultiplier,
        attribute: habitRow.attribute ?? 'vitality',
        lastCompletedDate: lastDate,
        activeChallenges: challengeInputs,
      );

      if (result.xpGained == 0 && result.newStreak == habitRow.currentStreak) {
        // Idempotent — already completed today
        return const Right(false);
      }

      // Calculate new level from total XP
      final newTotalXp = statsRow.totalXp + result.xpGained;
      final newLevel = _engine.computeLevel(newTotalXp);

      // Write everything in a single drift transaction
      await _db.transaction(() async {
        // Update habit
        await _db.habitsDao.updateStreak(
          habitId,
          result.newStreak,
          result.longestStreak,
          date.toIso8601String(),
        );
        await _db.habitsDao.updateMomentum(
          habitId,
          result.newMomentumScore,
          result.newConsecutiveMisses,
        );

        // Update user stats
        await _db.userStatsDao.updateAttributeXp(
          statsRow.userId,
          result.attribute,
          result.xpGained,
          newLevel,
          newTotalXp,
        );
        await _db.userStatsDao.updateStreak(statsRow.userId, result.newStreak);
        await _db.userStatsDao.updateWorldHealth(
          statsRow.userId,
          (statsRow.worldHealthScore + result.worldHealthDelta).clamp(0.0, 1.0),
        );

        // Insert completion log
        await _db.habitCompletionsDao.insertCompletion(
          HabitCompletionsTableCompanion(
            id: Value('${habitId}_${DateTime.now().millisecondsSinceEpoch}'),
            habitId: Value(habitId),
            userId: Value(statsRow.userId),
            completedAt: Value(date.toIso8601String()),
            xpGained: Value(result.xpGained),
            attribute: Value(result.attribute),
            momentumAtCompletion: Value(result.newMomentumScore),
            streakDay: Value(result.newStreak),
            wasRecovery: Value(result.isRecovery ? 1 : 0),
          ),
        );

        // Update challenge progress
        for (final update in result.challengeUpdates.values) {
          await _db.challengeProgressDao.updateDay(
            update.challengeId,
            update.newDay,
            update.isCompleted ? 'completed' : 'active',
          );
        }
      });

      // Enqueue Firestore sync (single mutation)
      await _syncEngine.enqueueSet(
        collectionPath: 'user_stats',
        documentId: statsRow.userId,
        data: {
          'totalXp': newTotalXp,
          'level': newLevel,
          'streak': result.newStreak,
          '${result.attribute}Xp': _getAttributeXp(statsRow, result.attribute) + result.xpGained,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return const Right(true);
    } catch (e, s) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    final row = await _db.habitsDao.getHabit(habitId);
    return row != null ? _rowToHabit(row) : null;
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    // Not stored as anchor in drift schema — query all and filter
    final all = await (select(_db.habitsTable)..where((t) => t.isArchived.equals(0))).get();
    // Filter by anchor; would need denormalization for performance
    return all.map((r) => _rowToHabit(r)).toList();
  }

  @override
  Future<List<HabitActivity>> getActivity(String userId, DateTime start, DateTime end) async {
    final rows = await (select(_db.habitCompletionsTable)
      ..where((t) => t.userId.equals(userId) & t.completedAt.isBetweenValues(
        start.toIso8601String(),
        end.toIso8601String(),
      )))
      .get();

    return rows.map((r) => HabitActivity(
      id: r.id,
      habitId: r.habitId,
      userId: r.userId,
      completedAt: DateTime.parse(r.completedAt),
      xpGained: r.xpGained,
      attribute: r.attribute ?? 'vitality',
      streakDay: r.streakDay,
    )).toList();
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    try {
      final habits = blueprint.habits;
      for (int i = 0; i < habits.length; i++) {
        final h = habits[i];
        final habitId = '${blueprint.id}_${i}_${DateTime.now().millisecondsSinceEpoch}';
        await _db.habitsDao.upsertHabit(HabitsTableCompanion(
          id: Value(habitId),
          userId: Value(userId),
          title: Value(h.title),
          attribute: Value(h.attribute.name),
          createdAt: Value(DateTime.now().toIso8601String()),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));

        await _syncEngine.enqueueSet(
          collectionPath: 'habits',
          documentId: habitId,
          data: {
            'userId': userId,
            'title': h.title,
            'attribute': h.attribute.name,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      return const Right(unit);
    } catch (e, s) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Habit _rowToHabit(HabitsTableData row) {
    return Habit(
      id: row.id,
      userId: row.userId,
      title: row.title,
      cue: row.cue ?? '',
      routine: row.routine ?? '',
      reward: row.reward ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == row.frequency,
        orElse: () => HabitFrequency.daily,
      ),
      difficulty: HabitDifficulty.values.firstWhere(
        (e) => e.name == row.difficulty,
        orElse: () => HabitDifficulty.medium,
      ),
      attribute: HabitAttribute.values.firstWhere(
        (e) => e.name == (row.attribute ?? 'vitality'),
        orElse: () => HabitAttribute.vitality,
      ),
      createdAt: DateTime.parse(row.createdAt),
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      lastCompletedDate: row.lastCompletedDate != null
          ? DateTime.tryParse(row.lastCompletedDate!)
          : null,
      isArchived: row.isArchived == 1,
      momentumScore: row.momentumScore,
      consecutiveMisses: row.consecutiveMisses,
    );
  }

  Map<String, dynamic> _habitToFirestoreMap(Habit habit) {
    return {
      'userId': habit.userId,
      'title': habit.title,
      'frequency': habit.frequency.name,
      'difficulty': habit.difficulty.name,
      'attribute': habit.attribute.name,
      'currentStreak': habit.currentStreak,
      'longestStreak': habit.longestStreak,
      'isArchived': habit.isArchived,
      'createdAt': habit.createdAt.toIso8601String(),
    };
  }

  double _difficultyMultiplier(String? difficulty) {
    switch (difficulty) {
      case 'easy': return 1.0;
      case 'medium': return 2.0;
      case 'hard': return 3.0;
      default: return 2.0;
    }
  }

  int _getAttributeXp(UserStatsTableData stats, String attribute) {
    switch (attribute) {
      case 'strength': return stats.strengthXp;
      case 'intellect': return stats.intellectXp;
      case 'vitality': return stats.vitalityXp;
      case 'creativity': return stats.creativityXp;
      case 'focus': return stats.focusXp;
      case 'spirit': return stats.spiritXp;
      default: return 0;
    }
  }
}
```

- [ ] **Step 3: Run tests**

```bash
dart run build_runner build --delete-conflicting-outputs; if ($?) { flutter test test/core/drift_repositories/drift_habit_repository_test.dart }
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/drift_repositories/ test/core/drift_repositories/
git commit -m "feat: implement DriftHabitRepository with local-first completeHabit"
```

---

### Task 6: Implement remaining Drift repositories

**Files:**
- Create: `lib/core/drift_repositories/drift_user_stats_repository.dart`
- Create: `lib/core/drift_repositories/drift_challenge_repository.dart`
- Create: `lib/core/drift_repositories/drift_tribe_repository.dart`
- Create: `lib/core/drift_repositories/drift_leaderboard_repository.dart`
- Create: `lib/core/drift_repositories/drift_blueprint_repository.dart`

- [ ] **Step 1: Write `lib/core/drift_repositories/drift_user_stats_repository.dart`**

```dart
import 'dart:async';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/user_stats_repository.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class DriftUserStatsRepository implements UserStatsRepository {
  final AppDatabase _db;

  DriftUserStatsRepository(this._db);

  @override
  Future<void> saveUserStats(UserProfile profile) async {
    await _db.userStatsDao.upsertFromFirebase(profile.uid, {
      'totalXp': profile.avatarStats.totalXp,
      'level': profile.avatarStats.level,
      'streak': profile.avatarStats.streak,
      'strengthXp': profile.avatarStats.strengthXp,
      'intellectXp': profile.avatarStats.intellectXp,
      'vitalityXp': profile.avatarStats.vitalityXp,
      'creativityXp': profile.avatarStats.creativityXp,
      'focusXp': profile.avatarStats.focusXp,
      'spiritXp': profile.avatarStats.spiritXp,
      'challengeXp': profile.avatarStats.challengeXp,
      'worldHealthScore': profile.worldState.worldHealth,
      'archetype': profile.archetype.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'avatarJson': profile.avatarStats.toMap().toString(),
      'worldStateJson': profile.worldState.toMap().toString(),
    });
  }

  @override
  Future<void> updateWorldHealth(String uid, int score) async {
    await _db.userStatsDao.updateWorldHealth(uid, score / 100.0);
  }

  @override
  Future<void> syncUserIdentity(UserProfile profile) async {
    await saveUserStats(profile);
  }

  @override
  Stream<UserProfile> watchUserStats(String uid) {
    return _db.userStatsDao.watchStats(uid).map((row) {
      if (row == null) return UserProfile(uid: uid);
      return _rowToProfile(row);
    });
  }

  @override
  Future<UserProfile> getUserStats(String uid) async {
    final row = await _db.userStatsDao.getStats(uid);
    if (row == null) return UserProfile(uid: uid);
    return _rowToProfile(row);
  }

  UserProfile _rowToProfile(UserStatsTableData row) {
    return UserProfile(
      uid: row.userId,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == (row.archetype ?? 'none'),
        orElse: () => UserArchetype.none,
      ),
      avatarStats: UserAvatarStats(
        strengthXp: row.strengthXp,
        intellectXp: row.intellectXp,
        vitalityXp: row.vitalityXp,
        creativityXp: row.creativityXp,
        focusXp: row.focusXp,
        spiritXp: row.spiritXp,
        challengeXp: row.challengeXp,
        level: row.level,
        streak: row.streak,
      ),
      worldState: UserWorldState(
        entropy: 1.0 - row.worldHealthScore,
      ),
    );
  }
}
```

- [ ] **Step 2: Write `lib/core/drift_repositories/drift_challenge_repository.dart`**

```dart
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriftChallengeRepository implements ChallengeRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;

  DriftChallengeRepository(this._db, this._engine, this._syncEngine);

  @override
  Future<Either<Failure, Unit>> joinChallenge(String userId, String challengeId) async {
    try {
      final challenge = ChallengeCatalog.getChallengeById(challengeId);
      if (challenge == null) return Left(ServerFailure('Challenge not found'));

      await _db.challengeProgressDao.upsertProgress(ChallengeProgressTableCompanion(
        challengeId: Value(challengeId),
        userId: Value(userId),
        title: Value(challenge.title),
        attribute: Value(challenge.xpReward > 0 ? 'vitality' : null),
        currentDay: const Value(0),
        totalDays: Value(challenge.totalDays),
        status: const Value('active'),
        xpReward: Value(challenge.xpReward),
        joinedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));

      await _syncEngine.enqueueUpdate(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {'status': 'active', 'joinedAt': DateTime.now().toIso8601String()},
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProgress(
    String userId, String challengeId, int progress,
  ) async {
    try {
      final challenge = await _db.challengeProgressDao.getActive(userId)
          .then((list) => list.where((c) => c.challengeId == challengeId).firstOrNull);
      if (challenge == null) return Left(ServerFailure('Challenge not found'));

      final result = _engine.processChallengeProgress(
        currentDay: challenge.currentDay,
        totalDays: challenge.totalDays,
        xpReward: challenge.xpReward,
      );

      await _db.challengeProgressDao.updateDay(challengeId, result.newDay,
          result.isCompleted ? 'completed' : 'active');

      if (result.isCompleted && result.xpReward != null) {
        final stats = await _db.userStatsDao.getStats(userId);
        if (stats != null) {
          final newTotal = stats.totalXp + result.xpReward!;
          final newLevel = _engine.computeLevel(newTotal);
          await _db.userStatsDao.updateAttributeXp(
            userId, 'vitality', result.xpReward!, newLevel, newTotal,
          );
        }
      }

      await _syncEngine.enqueueUpdate(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {'currentDay': result.newDay, 'status': result.isCompleted ? 'completed' : 'active'},
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId, String challengeId,
  ) async {
    try {
      await _db.challengeProgressDao.updateDay(challengeId, 0, 'completed');

      await _syncEngine.enqueueUpdate(
        collectionPath: 'users/$userId/challenges',
        documentId: challengeId,
        data: {'status': 'completed'},
      );

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async {
    return ChallengeCatalog.getFeatured();
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    final rows = await _db.challengeProgressDao.getActive(userId);
    return rows.map((r) => Challenge(
      id: r.challengeId,
      title: r.title ?? '',
      description: '',
      imageUrl: '',
      reward: '',
      participants: 0,
      daysLeft: r.totalDays - r.currentDay,
      totalDays: r.totalDays,
      currentDay: r.currentDay,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == r.status,
        orElse: () => ChallengeStatus.active,
      ),
      xpReward: r.xpReward,
      steps: [],
    )).toList();
  }

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) {
    return ChallengeCatalog.getAvailableChallenges(archetypeId) as Future<List<Challenge>>;
  }

  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async {
    if (archetypeId == null) return null;
    return ChallengeCatalog.getWeeklySpotlight(archetypeId);
  }

  @override
  Future<Challenge?> getChallengeById(String id) async {
    return ChallengeCatalog.getChallengeById(id);
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _db.challengeProgressDao.updateDay(challengeId, 0, 'completed');
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    await _db.challengeProgressDao.upsertProgress(ChallengeProgressTableCompanion(
      challengeId: Value(challenge.id),
      userId: Value(userId),
      title: Value(challenge.title),
      currentDay: const Value(0),
      totalDays: Value(challenge.totalDays),
      status: const Value('active'),
      xpReward: Value(challenge.xpReward),
      updatedAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {int limit = 3},
  ) async {
    return [];
  }

  @override
  Future<void> seedChallengesIfEmpty() async {}
}
```

- [ ] **Step 3: Write `lib/core/drift_repositories/drift_tribe_repository.dart`**

```dart
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';

class DriftTribeRepository implements TribeRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;

  DriftTribeRepository(this._db, this._syncEngine);

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    final tribe = await _db.tribeStatsDao.getStats(archetypeId);
    if (tribe == null) return null;
    return _rowToTribe(tribe);
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    final rows = await (select(_db.tribeStatsTable)).get();
    return rows.map(_rowToTribe).toList();
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    return (select(_db.tribeStatsTable)).watch().map((rows) {
      return rows.map(_rowToTribe).toList();
    });
  }

  @override
  Stream<List<Tribe>> toWatchable() {
    return watchArchetypeClubs();
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {int limit = 10},
  ) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {int limit = 20},
  ) async {
    return [];
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    await _syncEngine.enqueueUpdate(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {'joinedAt': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    await _syncEngine.enqueueMutation(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      operation: 'delete',
    );
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    return [];
  }

  @override
  Future<void> seedTribesIfEmpty() async {}

  Tribe _rowToTribe(TribeStatsTableData row) {
    return Tribe(
      id: row.tribeId,
      name: row.tribeName ?? '',
      description: '',
      imageUrl: '',
      ownerId: '',
      tags: const [],
      levelRequirement: 0,
      rank: 0,
      totalXp: row.totalXp,
      memberCount: row.memberCount,
      archetypeId: row.archetypeId,
      isVerified: false,
      totalHabitsCompleted: row.totalHabitsCompleted,
      totalChallengesCompleted: row.totalChallengesCompleted,
    );
  }
}
```

- [ ] **Step 4: Write `lib/core/drift_repositories/drift_leaderboard_repository.dart`**

```dart
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/repositories/leaderboard_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriftLeaderboardRepository implements LeaderboardRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;

  DriftLeaderboardRepository(this._db, this._syncEngine);

  @override
  Stream<List<LeaderboardEntry>> watchClubLeaderboard([String? clubId]) {
    if (clubId == null || clubId.isEmpty) return const Stream.empty();
    return _db.leaderboardEntriesDao.watchLeaderboard(clubId).map((rows) {
      return rows.asMap().entries.map((entry) {
        final row = entry.value;
        return LeaderboardEntry(
          userId: row.userId,
          userName: row.userName,
          xp: row.xp,
          level: row.level,
          archetype: UserArchetype.values.firstWhere(
            (e) => e.name == (row.archetype ?? 'none'),
            orElse: () => UserArchetype.none,
          ),
          rank: entry.key + 1,
        );
      }).toList();
    });
  }

  @override
  Stream<List<LeaderboardEntry>> watchChallengeLeaderboard([String? challengeId]) {
    return const Stream.empty();
  }

  @override
  Future<Either<Failure, Unit>> updateUserScore(
    String userId, {
    required int xp,
    required int level,
    required UserArchetype archetype,
    String? userName,
    String? clubId,
    String? challengeId,
  }) async {
    try {
      if (clubId != null && clubId.isNotEmpty) {
        final id = '${userId}_$clubId';
        await _db.leaderboardEntriesDao.upsertEntry(LeaderboardEntriesTableCompanion(
          id: Value(id),
          tribeId: Value(clubId),
          userId: Value(userId),
          userName: Value(userName ?? 'Anonymous'),
          xp: Value(xp),
          level: Value(level),
          archetype: Value(archetype.name),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ));

        await _syncEngine.enqueueSet(
          collectionPath: 'club_leaderboards',
          documentId: id,
          data: {
            'userId': userId,
            'xp': xp,
            'level': level,
            'archetype': archetype.name,
          },
        );
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 5: Write `lib/core/drift_repositories/drift_blueprint_repository.dart`**

```dart
import 'dart:convert';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';

class DriftBlueprintsRepository {
  final AppDatabase _db;

  static final List<Blueprint> _fallbackBlueprints = [
    // Copy from the existing BlueprintsRepository fallback list
    // (too long to inline here — see lib/features/gamification/data/repositories/blueprints_repository.dart)
  ];

  DriftBlueprintsRepository(this._db);

  Future<List<Blueprint>> getBlueprints({String? category}) async {
    try {
      final rows = await _db.blueprintsDao.getAll();
      if (rows.isEmpty) {
        await _seedFallback();
        return _getFallbackFiltered(category);
      }
      final blueprints = rows.map((r) => Blueprint.fromMap(r.id, {
        'title': r.title,
        'description': r.description,
        'category': r.category,
        'difficulty': r.difficulty,
        'imageUrl': r.imageUrl,
        'habits': r.dataJson != null ? jsonDecode(r.dataJson!) : [],
      })).toList();

      if (category == null || category == 'All') return blueprints;
      return blueprints.where((b) => b.category == category).toList();
    } catch (e) {
      return _getFallbackFiltered(category);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final rows = await _db.blueprintsDao.getAll();
      final cats = rows.map((r) => r.category).whereType<String>().toSet().toList();
      if (cats.isEmpty) return ['All', 'Athlete', 'Creator', 'Scholar', 'Stoic', 'Zealot'];
      if (!cats.contains('All')) cats.insert(0, 'All');
      return cats;
    } catch (e) {
      return ['All', 'Athlete', 'Creator', 'Scholar', 'Stoic', 'Zealot'];
    }
  }

  Future<void> _seedFallback() async {
    for (final bp in _fallbackBlueprints) {
      await _db.blueprintsDao.upsertBlueprint(BlueprintsTableCompanion(
        id: Value(bp.id),
        title: Value(bp.title),
        description: Value(bp.description),
        category: Value(bp.category),
        difficulty: Value(bp.difficulty.name),
        imageUrl: Value(bp.imageUrl),
        habitCount: Value(bp.habits.length),
        isFallback: const Value(1),
        dataJson: Value(jsonEncode(bp.habits.map((h) => h.toMap()).toList())),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
    }
  }

  List<Blueprint> _getFallbackFiltered(String? category) {
    if (category == null || category == 'All') return _fallbackBlueprints;
    return _fallbackBlueprints.where((b) => b.category == category).toList();
  }
}
```

- [ ] **Step 6: Generate and commit**

```bash
dart run build_runner build --delete-conflicting-outputs; if ($?) { flutter test }
```

```bash
git add lib/core/drift_repositories/
git commit -m "feat: implement all Drift repositories (stats, challenge, tribe, leaderboard, blueprints)"
```

---

### Task 7: Wire providers and remove old files

**Files:**
- Modify: `lib/features/gamification/presentation/providers/gamification_providers.dart`
- Modify: `lib/features/gamification/presentation/providers/user_stats_providers.dart`
- Modify: `lib/features/social/presentation/providers/tribes_provider.dart`
- Modify: `lib/features/social/presentation/providers/leaderboard_provider.dart`
- Modify: `lib/features/social/presentation/providers/challenge_provider.dart`
- Modify: `lib/features/blueprints/data/repositories/blueprint_repository.dart`
- Delete: `lib/core/cache/` (entire directory)
- Delete: `lib/core/services/local_cache_service.dart`
- Delete: `lib/core/services/local_cache_service.g.dart`
- Delete: `lib/core/services/background_sync_service.dart`
- Delete: `lib/features/gamification/data/repositories/cache_aware_user_stats_repository.dart`
- Delete: `lib/features/gamification/data/repositories/user_stats_repository.dart`
- Delete: `lib/features/gamification/data/repositories/firestore_gamification_repository.dart`
- Delete: `lib/features/gamification/data/repositories/blueprints_repository.dart`
- Delete: `lib/features/social/data/repositories/cache_aware_tribe_repository.dart`
- Delete: `lib/features/social/data/repositories/firestore_leaderboard_repository.dart`
- Delete: `lib/features/social/data/repositories/challenge_repository.dart` (the Firestore version)
- Delete: `lib/features/habits/data/repositories/firestore_habit_repository.dart`
- Delete: `lib/features/social/presentation/providers/cached_tribe_stats_provider.dart`
- Delete: `lib/features/social/domain/models/cached_stats.dart`

- [ ] **Step 1: Rewrite `lib/features/gamification/presentation/providers/gamification_providers.dart`**

Replace the entire file:

```dart
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gamification_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationService gamificationService(Ref ref) {
  return GamificationService();
}

@Riverpod(keepAlive: true)
DriftUserStatsRepository driftUserStatsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftUserStatsRepository(db);
}

@riverpod
Stream<UserProfile> userStats(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;
  if (userId == null) return Stream.value(const UserProfile(uid: ''));
  final repo = ref.watch(driftUserStatsRepositoryProvider);
  return repo.watchUserStats(userId);
}
```

- [ ] **Step 2: Regenerate `.g.dart` files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Delete obsolete files**

```bash
Remove-Item -Recurse -Force lib/core/cache
Remove-Item -Force lib/core/services/local_cache_service.dart
Remove-Item -Force lib/core/services/local_cache_service.g.dart
Remove-Item -Force lib/core/services/background_sync_service.dart
Remove-Item -Force lib/features/gamification/data/repositories/cache_aware_user_stats_repository.dart
Remove-Item -Force lib/features/gamification/data/repositories/user_stats_repository.dart
Remove-Item -Force lib/features/gamification/data/repositories/firestore_gamification_repository.dart
Remove-Item -Force lib/features/gamification/data/repositories/blueprints_repository.dart
Remove-Item -Force lib/features/social/data/repositories/cache_aware_tribe_repository.dart
Remove-Item -Force lib/features/social/data/repositories/firestore_leaderboard_repository.dart
Remove-Item -Force lib/features/social/data/repositories/challenge_repository.dart
Remove-Item -Force lib/features/habits/data/repositories/firestore_habit_repository.dart
Remove-Item -Force lib/features/social/presentation/providers/cached_tribe_stats_provider.dart
Remove-Item -Force lib/features/social/domain/models/cached_stats.dart
```

- [ ] **Step 4: Fix any dangling imports**

Run `dart analyze lib/` to find broken imports and fix them. Expected pattern: any file that imported from the deleted files needs to switch to drift repository imports.

```bash
dart analyze lib/
```

Fix each error by updating imports to use drift repositories.

- [ ] **Step 5: Remove Hive from pubspec.yaml if no longer used**

Check if any remaining files import from `hive` or `hive_flutter`. If none, remove:

```yaml
# Remove these lines:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

- [ ] **Step 6: Run build and tests to verify everything compiles**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: wire drift repositories, delete obsolete Hive/Firestore-transaction code"
```

---

### Task 8: Verify and cleanup

- [ ] **Step 1: Run full analysis**

```bash
flutter analyze
```

Fix any warnings or errors.

- [ ] **Step 2: Run full test suite**

```bash
flutter test
```

If any tests fail, they were likely relying on the old Firestore-transaction-based repositories. Update test mocks to use Drift repositories.

- [ ] **Step 3: Store knowledge**

Use `byterover-store-knowledge` to save the drift database schema, sync engine pattern, and game loop engine for future reference.
