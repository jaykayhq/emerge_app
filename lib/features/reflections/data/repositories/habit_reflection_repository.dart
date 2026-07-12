import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Repository for per-habit reflections.
///
/// Local drift persistence is the source of truth; remote Firestore writes
/// are fire-and-forget (failures are silently caught).
class HabitReflectionRepository {
  HabitReflectionRepository({required this.local, required this.remote});
  final HabitReflectionLocalDatasource local;
  final HabitReflectionRemoteDatasource remote;

  /// Returns the reflection for (userId, habitId, localDate), or null if none.
  Future<Either<Failure, HabitReflection?>> getForHabit({
    required String userId,
    required String habitId,
    required DateTime localDate,
  }) async {
    try {
      return Right(await local.getByDate(userId, habitId, localDate));
    } catch (e) {
      return Left(CacheFailure('Could not load reflection: $e'));
    }
  }

  /// Saves (upserts) a per-habit reflection locally, then mirrors to Firestore.
  Future<Either<Failure, HabitReflection>> save({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    try {
      final saved = await local.upsert(
        userId: userId,
        habitId: habitId,
        localDate: localDate,
        mood: mood,
        note: note,
      );
      unawaited(
        remote
            .write({
              'userId': userId,
              'habitId': habitId,
              'localDate': localDate,
              'mood': mood.value,
              'note': note,
              'updatedAt': saved.updatedAt,
            })
            .catchError((e) {
          debugPrint('HabitReflectionRepository: remote write failed: $e');
        }),
      );
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure('Could not save reflection: $e'));
    }
  }
}
