import 'dart:async';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'world_health_provider.g.dart';

/// Provider for the WorldHealthService
@riverpod
WorldHealthService worldHealthService(Ref ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  final habitRepository = ref.watch(habitRepositoryProvider);
  return WorldHealthService(repository, habitRepository);
}

/// Provider that calculates world health on demand
/// Uses the WorldHealthService with caching for efficiency
@riverpod
Future<double> worldHealth(Ref ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user.isEmpty) {
    AppLogger.d('No user logged in, returning default world health');
    return 0.5; // Default neutral health
  }

  final service = ref.watch(worldHealthServiceProvider);
  return service.getWorldHealth(user.id);
}

/// Reactive stream of world health score from UserProfile
@riverpod
Stream<double> worldHealthStream(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null || user.isEmpty) return Stream.value(0.5);

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id).map((profile) {
    return (profile.momentumScore).clamp(0.0, 1.0);
  });
}

/// Reactive stream of world entropy score from UserProfile
@riverpod
Stream<double> worldEntropyStream(Ref ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null || user.isEmpty) return Stream.value(0.0);

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id).map((profile) {
    return (profile.worldState.entropy).clamp(0.0, 1.0);
  });
}
