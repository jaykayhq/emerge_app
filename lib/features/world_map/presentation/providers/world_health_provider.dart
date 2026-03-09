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

/// ENHANCED: Provider that streams the world health value (0.0 to 1.0)
///
/// Now uses the WorldHealthService for sophisticated calculation including:
/// - Last 7 days habit completion rate (70% weight)
/// - Decay penalty for missed days
/// - Streak bonus for consistent activity
///
/// Refreshes every 5 minutes and provides real-time updates as the user's profile changes
final worldHealthStreamProvider = StreamProvider<double>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(userStatsRepositoryProvider);
  final service = ref.watch(worldHealthServiceProvider);

  // Create a stream that combines profile updates with periodic refreshes
  final profileStream = repository.watchUserStats(user.id);

  // Create a periodic refresh stream (every 5 minutes)
  final periodicStream = Stream.periodic(
    const Duration(minutes: 5),
    (_) => user.id,
  ).asyncMap((userId) => repository.getUserStats(userId));

  // Merge both streams and calculate health for each update
  return Stream.merge([
    profileStream,
    periodicStream,
  ]).asyncMap((profile) async {
    // Calculate fresh health using the service
    final health = await service.calculateWorldHealth(profile);
    AppLogger.d('World health updated: ${health.toStringAsFixed(2)}');
    return health.clamp(0.0, 1.0);
  });
});
