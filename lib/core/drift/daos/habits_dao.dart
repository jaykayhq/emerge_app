import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habits_table.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [HabitsTable])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  Future<List<HabitsTableData>> getByAttribute(String attribute) {
    return (select(habitsTable)..where((t) => t.attribute.equals(attribute))).get();
  }

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

  Future<void> insertFromData({
    required String id,
    required String userId,
    required String title,
    String cue = '',
    String routine = '',
    String reward = '',
    String frequency = 'daily',
    String difficulty = 'medium',
    String? attribute,
    int currentStreak = 0,
    int longestStreak = 0,
    int momentumScore = 0,
    int consecutiveMisses = 0,
    int isArchived = 0,
    required String createdAt,
    required String updatedAt,
  }) {
    return into(habitsTable).insertOnConflictUpdate(HabitsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      cue: Value(cue),
      routine: Value(routine),
      reward: Value(reward),
      frequency: Value(frequency),
      difficulty: Value(difficulty),
      attribute: Value(attribute),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      momentumScore: Value(momentumScore),
      consecutiveMisses: Value(consecutiveMisses),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    ));
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
