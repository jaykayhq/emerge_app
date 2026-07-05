import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';

part 'reflection_providers.g.dart';

@Riverpod(keepAlive: true)
ReflectionLocalDatasource reflectionLocalDatasource(Ref ref) =>
    ReflectionLocalDatasource(dao: ref.watch(appDatabaseProvider).dailyReflectionsDao);

@Riverpod(keepAlive: true)
ReflectionRemoteDatasource reflectionRemoteDatasource(Ref ref) =>
    FirestoreReflectionRemoteDatasource(firestore: FirebaseFirestore.instance);

@Riverpod(keepAlive: true)
ReflectionRepository reflectionRepository(Ref ref) => ReflectionRepository(
      local: ref.watch(reflectionLocalDatasourceProvider),
      remote: ref.watch(reflectionRemoteDatasourceProvider),
    );

/// Loads the reflection for [date] (default = today). Returns null if none.
@riverpod
Future<DailyReflection?> dailyReflection(
  Ref ref, {
  required String userId,
  required DateTime date,
}) async {
  final result = await ref
      .watch(reflectionRepositoryProvider)
      .getForDate(userId: userId, localDate: date);
  return result.fold((_) => null, (r) => r);
}
