import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/daily_reflections_dao.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/reflection_providers.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_reflection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub datasources that don't require drift initialization.
class _StubLocal extends ReflectionLocalDatasource {
  _StubLocal() : super(dao: _StubDao());

  DailyReflection? _existing;

  void setExisting(DailyReflection? r) => _existing = r;

  @override
  Future<DailyReflection?> getByDate(String userId, DateTime localDate) async =>
      _existing;

  @override
  Future<DailyReflection> upsert({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async =>
      DailyReflection(
        id: 'r1',
        userId: userId,
        localDate: localDate,
        mood: mood,
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}

class _StubRemote implements ReflectionRemoteDatasource {
  @override
  Future<void> write(Map<String, Object?> data) async {}
}

class _StubDao extends DailyReflectionsDao {
  _StubDao() : super(_StubDatabase());
}

class _StubDatabase extends AppDatabase {
  _StubDatabase() : super.withExecutor(NativeDatabase.memory());
}

void main() {
  late _StubLocal local;
  late _StubRemote remote;

  setUp(() {
    local = _StubLocal();
    remote = _StubRemote();
  });

  testWidgets('empty state shows emoji row + note input + Save',
      (tester) async {
    local.setExisting(null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reflectionRepositoryProvider.overrideWithValue(
            ReflectionRepository(local: local, remote: remote),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TimelineReflectionCard(
              userId: 'u1',
              date: DateTime(2026, 7, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('How does today feel so far?'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('existing reflection renders collapsed summary',
      (tester) async {
    final existing = DailyReflection(
      id: 'r1',
      userId: 'u1',
      localDate: DateTime(2026, 7, 5),
      mood: Mood.good,
      note: 'morning was tough',
      createdAt: DateTime(2026, 7, 5, 9),
      updatedAt: DateTime(2026, 7, 5, 9),
    );
    local.setExisting(existing);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reflectionRepositoryProvider.overrideWithValue(
            ReflectionRepository(local: local, remote: remote),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TimelineReflectionCard(
              userId: 'u1',
              date: DateTime(2026, 7, 5),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('morning was tough'), findsOneWidget);
  });
}
