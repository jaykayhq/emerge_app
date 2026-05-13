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

  Future<void> insertFromData({
    required String challengeId,
    required String userId,
    String? title,
    String? attribute,
    int currentDay = 0,
    int totalDays = 1,
    String status = 'active',
    int xpReward = 0,
    String? joinedAt,
    required String updatedAt,
  }) {
    return into(challengeProgressTable).insertOnConflictUpdate(ChallengeProgressTableCompanion(
      challengeId: Value(challengeId),
      userId: Value(userId),
      title: Value(title),
      attribute: Value(attribute),
      currentDay: Value(currentDay),
      totalDays: Value(totalDays),
      status: Value(status),
      xpReward: Value(xpReward),
      joinedAt: Value(joinedAt),
      updatedAt: Value(updatedAt),
    ));
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
