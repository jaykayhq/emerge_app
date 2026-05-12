import 'dart:async';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/world_map/domain/services/world_health_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the WorldHealthService
final worldHealthServiceProvider = Provider<WorldHealthService>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  return WorldHealthService(repository);
});

/// Provider that calculates world health on demand
/// Uses the WorldHealthService with caching for efficiency
final worldHealthProvider = FutureProvider<double>((ref) async {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) {
    AppLogger.d('No user logged in, returning default world health');
    return 0.5; // Default neutral health
  }

  final service = ref.watch(worldHealthServiceProvider);
  return service.getWorldHealth(user.id);
});

/// Reactive stream of world health score from UserProfile
final worldHealthStreamProvider = StreamProvider<double>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value(0.5);

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id).map((profile) {
    return (profile.momentumScore).clamp(0.0, 1.0);
  });
});

/// Reactive stream of world entropy score from UserProfile
final worldEntropyStreamProvider = StreamProvider<double>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value(0.0);

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id).map((profile) {
    return (profile.worldState.entropy).clamp(0.0, 1.0);
  });
});
