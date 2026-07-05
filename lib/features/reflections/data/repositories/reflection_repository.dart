import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

/// Repository for daily reflections.
///
/// Local drift persistence is the source of truth; remote Firestore writes
/// are fire-and-forget (failures are silently caught).
class ReflectionRepository {
  ReflectionRepository({required this.local, required this.remote});
  final ReflectionLocalDatasource local;
  final ReflectionRemoteDatasource remote;

  /// Returns the reflection for (userId, localDate), or null if none.
  Future<Either<Failure, DailyReflection?>> getForDate({
    required String userId,
    required DateTime localDate,
  }) async {
    try {
      return Right(await local.getByDate(userId, localDate));
    } catch (e) {
      return Left(CacheFailure('Could not load reflection: $e'));
    }
  }

  /// Saves (upserts) a daily reflection locally, then mirrors to Firestore.
  Future<Either<Failure, DailyReflection>> save({
    required String userId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    try {
      final saved = await local.upsert(
        userId: userId,
        localDate: localDate,
        mood: mood,
        note: note,
      );
      // Fire-and-forget remote write; failure does not fail the save.
      unawaited(
        remote
            .write({
              'userId': userId,
              'localDate': localDate,
              'mood': mood.value,
              'note': note,
              'updatedAt': saved.updatedAt,
            })
            .catchError((e) {
              // Fire-and-forget: log but don't fail the save
              debugPrint('ReflectionRepository: remote write failed: $e');
            }),
      );
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure('Could not save reflection: $e'));
    }
  }
}
