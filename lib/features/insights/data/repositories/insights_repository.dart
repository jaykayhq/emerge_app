import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/insights/data/repositories/firestore_insights_repository.dart';

abstract class InsightsRepository {
  Future<Recap> getLatestRecap(String userId);
  Future<List<Reflection>> getReflections(String userId);
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return FirestoreInsightsRepository(FirebaseFirestore.instance);
});

final latestRecapProvider = FutureProvider<Recap>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;
  if (userId == null) {
    return const Recap(
      id: 'empty',
      period: 'No Data',
      dateRange: '',
      habitsCompleted: 0,
      perfectDays: 0,
      xpGained: 0,
      focusTime: '0h',
      summary: 'Please sign in.',
      consistencyChange: 0.0,
    );
  }
  return ref.watch(insightsRepositoryProvider).getLatestRecap(userId);
});

final reflectionsProvider = FutureProvider<List<Reflection>>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final userId = userAsync.value?.id;
  if (userId == null) return [];
  return ref.watch(insightsRepositoryProvider).getReflections(userId);
});
