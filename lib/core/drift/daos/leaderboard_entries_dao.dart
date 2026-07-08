import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/leaderboard_entries_table.dart';

part 'leaderboard_entries_dao.g.dart';

@DriftAccessor(tables: [LeaderboardEntriesTable])
class LeaderboardEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$LeaderboardEntriesDaoMixin {
  LeaderboardEntriesDao(super.db);

  Stream<List<LeaderboardEntriesTableData>> watchLeaderboard(String tribeId) {
    return (select(leaderboardEntriesTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.xp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<LeaderboardEntriesTableData>> getForTribe(String tribeId) {
    return (select(leaderboardEntriesTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.xp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> upsertEntry(Insertable<LeaderboardEntriesTableData> entry) {
    return into(leaderboardEntriesTable).insertOnConflictUpdate(entry);
  }

  Future<void> insertFromData({
    required String id,
    required String tribeId,
    required String userId,
    String userName = 'Anonymous',
    int xp = 0,
    int level = 1,
    String? archetype,
    required String updatedAt,
  }) {
    return into(leaderboardEntriesTable).insertOnConflictUpdate(
      LeaderboardEntriesTableCompanion(
        id: Value(id),
        tribeId: Value(tribeId),
        userId: Value(userId),
        userName: Value(userName),
        xp: Value(xp),
        level: Value(level),
        archetype: Value(archetype),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> updateUserScore(
    String id, {
    required int xp,
    required int level,
    required String userName,
    required String archetype,
  }) async {
    await (update(
      leaderboardEntriesTable,
    )..where((t) => t.id.equals(id))).write(
      LeaderboardEntriesTableCompanion(
        xp: Value(xp),
        level: Value(level),
        userName: Value(userName),
        archetype: Value(archetype),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> incrementXp(
    String id,
    int deltaXp,
    int newLevel, {
    required String userId,
    required String tribeId,
    String userName = 'Anonymous',
    String? archetype,
  }) async {
    final entry = await (select(
      leaderboardEntriesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry != null) {
      await (update(
        leaderboardEntriesTable,
      )..where((t) => t.id.equals(id))).write(
        LeaderboardEntriesTableCompanion(
          xp: Value(entry.xp + deltaXp),
          level: Value(newLevel),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
    } else {
      await insertFromData(
        id: id,
        tribeId: tribeId,
        userId: userId,
        userName: userName,
        xp: deltaXp,
        level: newLevel,
        archetype: archetype,
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }
}
