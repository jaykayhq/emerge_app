import 'package:emerge_app/core/drift/daos/habit_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Local datasource for per-habit reflections backed by drift.
class HabitReflectionLocalDatasource {
  HabitReflectionLocalDatasource({required this.dao});
  final HabitReflectionsDao dao;

  Future<HabitReflection?> getByDate(
    String userId,
    String habitId,
    DateTime localDate,
  ) async {
    final row = await dao.getByDate(userId, habitId, localDate);
    if (row == null) return null;
    return HabitReflection(
      id: row.id,
      userId: row.userId,
      habitId: row.habitId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<HabitReflection> upsert({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    await dao.upsert(
      userId: userId,
      habitId: habitId,
      localDate: localDate,
      mood: mood,
      note: note,
    );
    final row = await dao.getByDate(userId, habitId, localDate);
    return HabitReflection(
      id: row!.id,
      userId: row.userId,
      habitId: row.habitId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
