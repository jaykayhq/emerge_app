import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tribe_activity_table.dart';

part 'tribe_activity_dao.g.dart';

@DriftAccessor(tables: [TribeActivityTable])
class TribeActivityDao extends DatabaseAccessor<AppDatabase>
    with _$TribeActivityDaoMixin {
  TribeActivityDao(super.db);

  Future<void> insertActivity(TribeActivityTableCompanion entry) async {
    await into(tribeActivityTable).insertOnConflictUpdate(entry);
  }

  Stream<List<TribeActivityTableData>> watchGlobalActivity() {
    return (select(tribeActivityTable)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(50))
        .watch();
  }

  Stream<List<TribeActivityTableData>> watchTribeActivity(String tribeId) {
    return (select(tribeActivityTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(50))
        .watch();
  }

  Future<List<TribeActivityTableData>> getTribeActivity(String tribeId) {
    return (select(tribeActivityTable)
          ..where((t) => t.tribeId.equals(tribeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(50))
        .get();
  }

  /// The most recent `habit_complete` activity row for a user+habit.
  ///
  /// The row's `id` IS the Firestore doc id the credit path used for
  /// `global_activities` and `tribes/{tribeId}/activity` (it embeds
  /// `${userId}_${habitId}_<millis>`), and its `tribeId` is the tribe the
  /// credit actually landed on — the undo path uses both to reverse the
  /// social writes exactly.
  Future<TribeActivityTableData?> getLatestHabitCompletion(
    String userId,
    String habitId,
  ) {
    return (select(tribeActivityTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.type.equals('habit_complete') &
                t.id.like('${userId}_${habitId}_%'),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteActivity(String id) async {
    await (delete(tribeActivityTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearSynced() async {
    await (delete(
      tribeActivityTable,
    )..where((t) => t.syncedAt.isNotNull())).go();
  }
}
