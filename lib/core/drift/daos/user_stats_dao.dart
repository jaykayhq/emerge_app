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

  Future<void> updateAttributeXp(String userId, String attribute, int amount, int newLevel, int newTotalXp) async {
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
      onboardingProgress: Value(data['onboardingProgress'] as int? ?? 0),
      onboardingCompletedAt: Value(data['onboardingCompletedAt'] as String?),
      syncedAt: Value(DateTime.now().toIso8601String()),
      updatedAt: Value(data['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    ));
  }
}
