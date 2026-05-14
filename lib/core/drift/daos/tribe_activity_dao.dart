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

  Future<void> clearSynced() async {
    await (delete(
      tribeActivityTable,
    )..where((t) => t.syncedAt.isNotNull())).go();
  }
}
