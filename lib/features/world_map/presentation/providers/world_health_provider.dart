import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that streams the world health value (0.0 to 1.0)
/// World health is calculated as 1.0 - entropy from the user's world state
/// This provides real-time updates as the user's profile changes
final worldHealthStreamProvider = StreamProvider<double>((ref) {
  final statsAsync = ref.watch(userStatsStreamProvider.stream);

  // Transform the user stats stream to extract world health
  return statsAsync.map((profile) {
    // World health is 1.0 - entropy, clamped between 0.0 and 1.0
    return profile.worldState.worldHealth.clamp(0.0, 1.0);
  });
});
