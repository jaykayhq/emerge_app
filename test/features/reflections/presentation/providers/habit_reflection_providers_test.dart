import 'dart:async';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/habit_reflection_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements HabitReflectionRemoteDatasource {}

class _MockLocalDatasource extends Mock
    implements HabitReflectionLocalDatasource {}

/// Reflection repo whose [HabitReflectionRepository.save] stays pending until
/// the test releases the gate.
class _GateReflectionRepo extends HabitReflectionRepository {
  _GateReflectionRepo()
      : super(
          local: _MockLocalDatasource(),
          remote: _MockRemoteDatasource(),
        );

  final Completer<void> gate = Completer<void>();

  @override
  Future<Either<Failure, HabitReflection?>> getForHabit({
    required String userId,
    required String habitId,
    required DateTime localDate,
  }) async =>
      Right(null);

  @override
  Future<Either<Failure, HabitReflection>> save({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    await gate.future;
    return Right(
      HabitReflection(
        id: 'r1',
        userId: userId,
        habitId: habitId,
        localDate: localDate,
        mood: mood,
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  test(
    'saveHabitReflection completing after the provider is unmounted does not throw',
    () async {
      // Regression: the save provider is auto-dispose. When the caller
      // disappears mid-save (e.g. the options sheet closed), the provider is
      // unmounted before the post-await `ref.invalidate` runs, which threw
      // UnmountedRefException and crashed the app.
      final repo = _GateReflectionRepo();
      final container = ProviderContainer(
        overrides: [
          habitReflectionRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final save = container.read(
        saveHabitReflectionProvider(
          userId: 'u1',
          habitId: 'h1',
          date: DateTime(2026, 8, 7),
          mood: Mood.good,
          note: 'note',
        ).future,
      );

      container.dispose();
      repo.gate.complete();

      await expectLater(save, completes);
    },
  );
}
