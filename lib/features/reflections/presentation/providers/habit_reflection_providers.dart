import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';

part 'habit_reflection_providers.g.dart';

@Riverpod(keepAlive: true)
HabitReflectionLocalDatasource habitReflectionLocalDatasource(Ref ref) =>
    HabitReflectionLocalDatasource(dao: ref.watch(appDatabaseProvider).habitReflectionsDao);

@Riverpod(keepAlive: true)
HabitReflectionRemoteDatasource habitReflectionRemoteDatasource(Ref ref) =>
    FirestoreHabitReflectionRemoteDatasource(firestore: FirebaseFirestore.instance);

@Riverpod(keepAlive: true)
HabitReflectionRepository habitReflectionRepository(Ref ref) =>
    HabitReflectionRepository(
      local: ref.watch(habitReflectionLocalDatasourceProvider),
      remote: ref.watch(habitReflectionRemoteDatasourceProvider),
    );

/// Loads the per-habit reflection for (userId, habitId, date). Returns null
/// if none exists.
@riverpod
Future<HabitReflection?> habitReflection(
  Ref ref, {
  required String userId,
  required String habitId,
  required DateTime date,
}) async {
  final result = await ref
      .watch(habitReflectionRepositoryProvider)
      .getForHabit(userId: userId, habitId: habitId, localDate: date);
  return result.fold((_) => null, (r) => r);
}

/// Saves a per-habit reflection and invalidates [habitReflection].
@riverpod
Future<void> saveHabitReflection(
  Ref ref, {
  required String userId,
  required String habitId,
  required DateTime date,
  required Mood mood,
  required String note,
}) async {
  final repo = ref.read(habitReflectionRepositoryProvider);
  await repo.save(
    userId: userId,
    habitId: habitId,
    localDate: date,
    mood: mood,
    note: note,
  );
  ref.invalidate(habitReflectionProvider(
    userId: userId,
    habitId: habitId,
    date: date,
  ));
}
