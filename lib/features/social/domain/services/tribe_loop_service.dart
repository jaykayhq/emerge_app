import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/services/firestore_drift_syncer.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';

class TribeLoopService {
  final SocialActivityService _socialActivity;
  final StreakWatchdog _streakWatchdog;
  final FirestoreDriftSyncer? _driftSyncer;
  StreamSubscription? _subscription;

  static const _streakMilestones = [7, 14, 21, 30, 60, 90];

  TribeLoopService({
    required SocialActivityService socialActivity,
    required StreakWatchdog streakWatchdog,
    FirestoreDriftSyncer? driftSyncer,
  })  : _socialActivity = socialActivity,
        _streakWatchdog = streakWatchdog,
        _driftSyncer = driftSyncer {
    _subscription = EventBus().on<HabitCompleted>().listen(onHabitCompleted);
  }

  void startDriftSync(String tribeId) {
    _driftSyncer?.start(tribeId);
  }

  void stopDriftSync() {
    _driftSyncer?.stop();
  }

  void dispose() {
    _subscription?.cancel();
    _driftSyncer?.stop();
  }

  @visibleForTesting
  Future<void> onHabitCompleted(HabitCompleted event) async {
    final result = event.gameLoopResult;
    final userId = event.userId;

    // 1. Streak milestone → tribe feed
    if (_streakMilestones.contains(result.newStreak)) {
      await _socialActivity.logStreakMilestone(
        userId: userId,
        userName: event.userName,
        archetype: event.archetype ?? '',
        streakDays: result.newStreak,
      );
    }

    // 2. Level up → tribe feed
    if (result.newLevel > event.previousLevel) {
      await _socialActivity.logLevelUp(
        userId: userId,
        userName: event.userName,
        archetype: event.archetype ?? '',
        newLevel: result.newLevel,
        totalXp: result.newTotalXp,
      );
    }

    // 3. Partner miss-detection
    if (event.tribeId != null) {
      await _streakWatchdog.checkPartners(
        userId: userId,
        tribeId: event.tribeId!,
      );
    }
  }
}
