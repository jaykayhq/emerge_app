import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habit_completions_table.dart';

part 'habit_completions_dao.g.dart';

@DriftAccessor(tables: [HabitCompletionsTable])
class HabitCompletionsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitCompletionsDaoMixin {
  HabitCompletionsDao(super.db);

  Future<void> insertCompletion(Insertable<HabitCompletionsTableData> entry) {
    return into(habitCompletionsTable).insert(entry);
  }

  Future<void> insertFromData({
    required String id,
    required String habitId,
    required String userId,
    required String completedAt,
    int xpGained = 0,
    String? attribute,
    int? momentumAtCompletion,
    int streakDay = 0,
    int wasRecovery = 0,
  }) {
    return into(habitCompletionsTable).insert(
      HabitCompletionsTableCompanion(
        id: Value(id),
        habitId: Value(habitId),
        userId: Value(userId),
        completedAt: Value(completedAt),
        xpGained: Value(xpGained),
        attribute: Value(attribute),
        momentumAtCompletion: Value(momentumAtCompletion),
        streakDay: Value(streakDay),
        wasRecovery: Value(wasRecovery),
      ),
    );
  }

  Future<List<HabitCompletionsTableData>> getBetweenDates(
    String userId,
    String start,
    String end,
  ) {
    return (select(habitCompletionsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.completedAt.isBetweenValues(start, end),
        ))
        .get();
  }

  Stream<List<HabitCompletionsTableData>> watchCompletions(String userId) {
    return (select(
      habitCompletionsTable,
    )..where((t) => t.userId.equals(userId))).watch();
  }

  Future<List<HabitCompletionsTableData>> getTodayCompletions(
    String userId,
  ) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(habitCompletionsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.completedAt.isBetweenValues(
                startOfDay.toIso8601String(),
                endOfDay.toIso8601String(),
              ),
        ))
        .get();
  }
}
