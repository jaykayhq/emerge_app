import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habits_table.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [HabitsTable])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  Future<HabitsTableData?> getHabit(String id) {
    return (select(habitsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<HabitsTableData>> watchHabits(String userId) {
    return (select(habitsTable)
      ..where((t) => t.userId.equals(userId) & t.isArchived.equals(0)))
      .watch();
  }

  Future<void> upsertHabit(Insertable<HabitsTableData> entry) {
    return into(habitsTable).insertOnConflictUpdate(entry);
  }

  Future<void> updateStreak(String id, int currentStreak, int longestStreak, String? lastCompletedDate) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(
        currentStreak: Value(currentStreak),
        longestStreak: Value(longestStreak),
        lastCompletedDate: Value(lastCompletedDate),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> updateMomentum(String id, int momentumScore, int consecutiveMisses) async {
    await (update(habitsTable)..where((t) => t.id.equals(id))).write(
      HabitsTableCompanion(
        momentumScore: Value(momentumScore),
        consecutiveMisses: Value(consecutiveMisses),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
