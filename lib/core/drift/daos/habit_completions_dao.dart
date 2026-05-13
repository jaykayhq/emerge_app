import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/habit_completions_table.dart';

part 'habit_completions_dao.g.dart';

@DriftAccessor(tables: [HabitCompletionsTable])
class HabitCompletionsDao extends DatabaseAccessor<AppDatabase> with _$HabitCompletionsDaoMixin {
  HabitCompletionsDao(super.db);

  Future<void> insertCompletion(Insertable<HabitCompletionsTableData> entry) {
    return into(habitCompletionsTable).insert(entry);
  }

  Stream<List<HabitCompletionsTableData>> watchCompletions(String userId) {
    return (select(habitCompletionsTable)..where((t) => t.userId.equals(userId)))
        .watch();
  }

  Future<List<HabitCompletionsTableData>> getTodayCompletions(String userId) async {
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
    return (select(habitCompletionsTable)
      ..where((t) => t.userId.equals(userId) & t.completedAt.startsWith(todayStr)))
      .get();
  }
}
