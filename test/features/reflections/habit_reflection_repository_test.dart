import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements HabitReflectionRemoteDatasource {
  final writes = <Map<String, Object?>>[];
  @override
  Future<void> write(Map<String, Object?> data) async {
    writes.add(data);
  }
}

void main() {
  late AppDatabase db;
  late HabitReflectionLocalDatasource local;
  late _FakeRemote remote;
  late HabitReflectionRepository repo;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    local = HabitReflectionLocalDatasource(dao: db.habitReflectionsDao);
    remote = _FakeRemote();
    repo = HabitReflectionRepository(local: local, remote: remote);
  });

  tearDown(() async {
    await db.close();
  });

  test('getForHabit returns null when no row', () async {
    final result = await repo.getForHabit(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
    );
    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => null), isNull);
  });

  test('save returns Right and mirrors to remote', () async {
    final result = await repo.save(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
      mood: Mood.good,
      note: 'felt strong',
    );
    expect(result.isRight(), isTrue);
    final r = result.getOrElse((_) => throw 'unreachable');
    expect(r.habitId, 'h1');
    expect(r.mood, Mood.good);
    expect(r.note, 'felt strong');
    expect(remote.writes, hasLength(1));
    expect(remote.writes.first['habitId'], 'h1');
  });

  test('save does not throw when remote fails', () async {
    final throwingRemote = _ThrowingRemote();
    final repo2 = HabitReflectionRepository(local: local, remote: throwingRemote);
    final result = await repo2.save(
      userId: 'u1',
      habitId: 'h1',
      localDate: DateTime(2026, 7, 10),
      mood: Mood.ok,
      note: 'ok',
    );
    expect(result.isRight(), isTrue);
  });
}

class _ThrowingRemote implements HabitReflectionRemoteDatasource {
  @override
  Future<void> write(Map<String, Object?> data) async {
    throw Exception('network down');
  }
}
