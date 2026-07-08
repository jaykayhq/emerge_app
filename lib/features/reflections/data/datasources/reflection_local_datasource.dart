import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Local datasource for daily reflections backed by drift.
class ReflectionLocalDatasource {
  ReflectionLocalDatasource({required this.dao});
  final DailyReflectionsDao dao;

  Future<DailyReflection?> getByDate(String userId, DateTime localDate) async {
    final row = await dao.getByDate(userId, localDate);
    if (row == null) return null;
    return DailyReflection(
      id: row.id,
      userId: row.userId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<DailyReflection> upsert({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    await dao.upsert(userId: userId, localDate: localDate, mood: mood, note: note);
    final row = await dao.getByDate(userId, localDate);
    return DailyReflection(
      id: row!.id,
      userId: row.userId,
      localDate: row.localDate,
      mood: Mood.fromInt(row.mood),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
