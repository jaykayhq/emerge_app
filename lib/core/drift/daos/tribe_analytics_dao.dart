// lib/core/drift/daos/tribe_analytics_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tribe_analytics_table.dart';

part 'tribe_analytics_dao.g.dart';

@DriftAccessor(tables: [TribeAnalyticsTable])
class TribeAnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$TribeAnalyticsDaoMixin {
  TribeAnalyticsDao(super.db);

  Future<TribeAnalyticsTableData?> getLatest({
    required String userId,
    required String tribeId,
  }) {
    return (select(tribeAnalyticsTable)
          ..where(
            (t) => t.userId.equals(userId) & t.tribeId.equals(tribeId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<TribeAnalyticsTableData?> watchLatest({
    required String userId,
    required String tribeId,
  }) {
    return (select(tribeAnalyticsTable)
          ..where(
            (t) => t.userId.equals(userId) & t.tribeId.equals(tribeId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsertSnapshot({
    required String userId,
    required String tribeId,
    required String date,
    required int memberCount,
    required int totalXp,
    required int totalHabitsCompleted,
    required int totalChallengesCompleted,
    required int activeMembers,
    required int newMembersThisWeek,
  }) {
    return into(tribeAnalyticsTable).insertOnConflictUpdate(
      TribeAnalyticsTableCompanion.insert(
        userId: Value(userId),
        tribeId: tribeId,
        date: date,
        memberCount: Value(memberCount),
        totalXp: Value(totalXp),
        totalHabitsCompleted: Value(totalHabitsCompleted),
        totalChallengesCompleted: Value(totalChallengesCompleted),
        activeMembers: Value(activeMembers),
        newMembersThisWeek: Value(newMembersThisWeek),
      ),
    );
  }
}