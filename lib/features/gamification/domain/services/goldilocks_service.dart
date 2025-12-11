import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoldilocksService {
  final RemoteConfigService _remoteConfigService;

  GoldilocksService(this._remoteConfigService);

  /// Analyzes user performance and suggests difficulty adjustments.
  /// Returns a suggestion string or null if no adjustment is needed.
  String? analyzePerformance(List<Habit> habits) {
    if (habits.isEmpty) return null;

    final completedCount = habits.where((h) => h.currentStreak > 0).length;
    final completionRate = completedCount / habits.length;

    final easyThreshold = _remoteConfigService.easyThreshold;
    final hardThreshold = _remoteConfigService.hardThreshold;

    if (completionRate >= easyThreshold) {
      return 'You are crushing it! Consider increasing the difficulty of your habits or adding a new one to stay in the Flow state.';
    } else if (completionRate <= hardThreshold) {
      return 'Struggling to keep up? It might be helpful to lower the difficulty or focus on just one key habit to regain momentum.';
    }

    return null;
  }

  /// Returns a random affirmation based on the user's archetype.
  String getAffirmation(String archetype) {
    final affirmations = _remoteConfigService.getAffirmations(archetype);
    if (affirmations.isEmpty) {
      return 'Keep going. You are building a better version of yourself.';
    }
    return (affirmations..shuffle()).first;
  }
}

final goldilocksServiceProvider = Provider<GoldilocksService>((ref) {
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);
  return GoldilocksService(remoteConfigService);
});
