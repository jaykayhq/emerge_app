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
