import 'dart:async';

import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_event.dart';
import 'package:emerge_app/features/gamification/domain/services/world_event_engine.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _recentTimestamps = <WorldEventType, DateTime>{};

/// Stream of world events that fire in response to user stat changes.
///
/// Consumed by the world map and Narrator to surface variable rewards.
final worldEventStreamProvider = Provider.autoDispose<Stream<List<WorldEvent>>>(
  (ref) {
    final controller = StreamController<List<WorldEvent>>.broadcast();

    ref.listen<AsyncValue<UserProfile>>(userStatsStreamProvider, (_, next) {
      next.whenData((profile) {
        final stats = UserStats(
          consecutiveActiveDays: _estimateActiveDays(profile),
          currentMomentumScore: (profile.momentumScore * 100).round(),
          level: profile.avatarStats.level,
        );

        final now = DateTime.now();
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: now,
          recentEvents: _recentTimestamps,
        );

        if (events.isNotEmpty) {
          for (final event in events) {
            _recentTimestamps[event.type] = event.firedAt;
          }
          controller.add(events);
        }
      });
    });

    ref.onDispose(controller.close);

    return controller.stream;
  },
);

int _estimateActiveDays(UserProfile profile) {
  if (profile.totalHabitsCompleted == 0) return 0;
  return (profile.totalHabitsCompleted ~/ 3).clamp(1, 365);
}
