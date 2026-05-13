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

  Future<void> incrementContribution(String tribeId, {required int xp, required int habits, required int challenges}) async {
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
