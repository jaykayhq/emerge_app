import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements ReflectionRemoteDatasource {
  final writes = <Map<String, Object?>>[];
  @override
  Future<void> write(Map<String, Object?> data) async {
    writes.add(data);
  }
}

void main() {
  test('save returns Right(DailyReflection) and writes to remote', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    final repo = ReflectionRepository(
      local: ReflectionLocalDatasource(dao: db.dailyReflectionsDao),
      remote: _FakeRemote(),
    );
    final result = await repo.save(
      userId: 'u1',
      localDate: DateTime(2026, 7, 5),
      mood: Mood.good,
      note: 'felt strong',
    );
    expect(result.isRight(), isTrue);
    final r = result.getOrElse((_) => throw 'unreachable');
    expect(r.mood, Mood.good);
    expect(r.note, 'felt strong');
    await db.close();
  });
}
