import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_tribe_table.dart';

part 'tribe_membership_dao.g.dart';

@DriftAccessor(tables: [UserTribeTable])
class TribeMembershipDao extends DatabaseAccessor<AppDatabase>
    with _$TribeMembershipDaoMixin {
  TribeMembershipDao(super.db);

  Future<UserTribeTableData?> getMembership(String userId, String tribeId) {
    return (select(userTribeTable)
          ..where((t) => t.userId.equals(userId) & t.tribeId.equals(tribeId)))
        .getSingleOrNull();
  }

  Stream<UserTribeTableData?> watchActiveMembership(String userId) {
    return (select(userTribeTable)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  Future<void> upsertMembership(Insertable<UserTribeTableData> entry) {
    return into(userTribeTable).insertOnConflictUpdate(entry);
  }

  Future<void> deactivateAll(String userId) async {
    await (update(userTribeTable)..where((t) => t.userId.equals(userId))).write(
      const UserTribeTableCompanion(isActive: Value(false)),
    );
  }

  Future<void> removeMembership(String userId, String tribeId) async {
    await (delete(
      userTribeTable,
    )..where((t) => t.userId.equals(userId) & t.tribeId.equals(tribeId))).go();
  }
}
