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

  Future<void> updateUserScore(String id, {required int xp, required int level, required String userName, required String archetype}) async {
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
