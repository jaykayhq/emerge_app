/// Web‑safe stubs for types that providers and repositories outside the drift
/// module need at compile time.
///
/// These types are **never** instantiated on web — every provider returns
/// `null` when `kIsWeb` is true, and the Drift*Repository classes are never
/// constructed on web.

// ---------------------------------------------------------------------------
// Value<T>
// ---------------------------------------------------------------------------
class Value<T> {
  final T? value;
  const Value(this.value);
  const Value.absent() : value = null;
  bool get present => value != null;
}

// ---------------------------------------------------------------------------
// AppDatabase
// ---------------------------------------------------------------------------
class AppDatabase {
  AppDatabase._();
  static AppDatabase? _instance;
  static AppDatabase get instance {
    throw UnsupportedError('AppDatabase not available on web');
  }

  static int get schemaVersion => 2;
  Future<void> clearAll() async {}

  late final UserStatsDao userStatsDao;
  late final HabitsDao habitsDao;
  late final HabitCompletionsDao habitCompletionsDao;
  late final ChallengeProgressDao challengeProgressDao;
  late final TribeStatsDao tribeStatsDao;
  late final LeaderboardEntriesDao leaderboardEntriesDao;
  late final BlueprintsDao blueprintsDao;
  late final MutationQueueDao mutationQueueDao;
  late final TribeActivityDao tribeActivityDao;
}

// ---------------------------------------------------------------------------
// DAO stubs
// ---------------------------------------------------------------------------
class UserStatsDao {
  Future<UserStatsTableData?> getStats(String userId) async => null;
  Stream<UserStatsTableData?> watchStats(String userId) =>
      const Stream.empty();
  Future<void> upsertStats(Object entry) async {}
  Future<void> upsertFromFirebase(String uid, Map<String, dynamic> data) async {}
}

class HabitsDao {
  Future<HabitsTableData?> getHabit(String id) async => null;
  Stream<List<HabitsTableData>> watchHabits(String userId) =>
      const Stream.empty();
}

class HabitCompletionsDao {}
class ChallengeProgressDao {
  Future<List<Object>> getActive(String userId) async => [];
}

class TribeStatsDao {
  Future<TribeStatsTableData?> getStats(String tribeId) async => null;
  Future<List<TribeStatsTableData>> getAll() async => [];
  Stream<List<TribeStatsTableData>> watchAll() => const Stream.empty();
  Future<void> upsertStats(Object companion) async {}
}

class LeaderboardEntriesDao {
  Future<List<Object>> getForTribe(String tribeId) async => [];
  Stream<List<Object>> watchLeaderboard(String clubId) =>
      const Stream.empty();
}

class BlueprintsDao {}
class MutationQueueDao {
  Future<List<MutationQueueTableData>> getAllPending() async => [];
}
class TribeActivityDao {
  Future<void> insertActivity(Object companion) async {}
  Future<List<Object>> getTribeActivity(String tribeId) async => [];
  Stream<List<Object>> watchTribeActivity(String tribeId) =>
      const Stream.empty();
  Stream<List<Object>> watchGlobalActivity() => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Table Data stubs
// ---------------------------------------------------------------------------
class UserStatsTableData {
  final String userId;
  final String? displayName;
  final int totalXp;
  final int level;
  UserStatsTableData({
    required this.userId,
    this.displayName,
    this.totalXp = 0,
    this.level = 1,
  });
}

class HabitsTableData {
  final String id;
  final String userId;
  HabitsTableData({required this.id, required this.userId});
}

class TribeStatsTableData {
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  TribeStatsTableData({
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
  });
}

class MutationQueueTableData {
  MutationQueueTableData();
}

// ---------------------------------------------------------------------------
// Companion stubs
// ---------------------------------------------------------------------------
class TribeStatsTableCompanion {
  TribeStatsTableCompanion({
    Value<String>? tribeId,
    Value<String>? tribeName,
    Value<String>? archetypeId,
    Value<int>? memberCount,
    Value<int>? totalXp,
    Value<int>? totalHabitsCompleted,
    Value<int>? totalChallengesCompleted,
    Value<int>? userContributionXp,
    Value<int>? userHabitsCompleted,
    Value<int>? userChallengesCompleted,
    Value<String>? updatedAt,
  });
}

class TribeActivityTableCompanion {
  TribeActivityTableCompanion({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? userName,
    Value<String>? tribeId,
    Value<String>? type,
    Value<String>? description,
    Value<int>? value,
    Value<String>? timestamp,
  });
}

class MutationQueueTableCompanion {
  MutationQueueTableCompanion();
}

class HabitCompletionsTableCompanion {
  HabitCompletionsTableCompanion();
}
