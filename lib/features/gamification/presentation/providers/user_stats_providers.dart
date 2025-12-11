import 'dart:async';

import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gamificationServiceProvider = Provider((ref) => GamificationService());

final userStatsStreamProvider = StreamProvider<UserProfile>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value(const UserProfile(uid: ''));

  final repository = ref.watch(userStatsRepositoryProvider);
  return repository.watchUserStats(user.id);
});

final userStatsControllerProvider = Provider((ref) {
  return UserStatsController(ref);
});

class UserStatsController {
  final Ref _ref;
  StreamSubscription? _subscription;

  UserStatsController(this._ref) {
    _init();
  }

  void _init() {
    _subscription = EventBus().on<HabitCompleted>().listen((event) async {
      await _handleHabitCompletion(event);
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _handleHabitCompletion(HabitCompleted event) async {
    final habitRepository = _ref.read(habitRepositoryProvider);
    final habit = await habitRepository.getHabit(event.habitId);

    if (habit != null) {
      await awardXpForHabit(habit);
    }
  }

  Future<void> awardXpForHabit(Habit habit) async {
    final userAsync = _ref.read(authStateChangesProvider);
    final user = userAsync.value;
    if (user == null) return;

    final repository = _ref.read(userStatsRepositoryProvider);
    final service = _ref.read(gamificationServiceProvider);

    // Fetch current stats (or use what's in the stream if available/fresh)
    final currentProfile = await repository.getUserStats(user.id);

    final xpGain = service.calculateXpGain(habit);
    final newStats = service.addXp(
      currentProfile.avatarStats,
      xpGain,
      habit.attribute,
    );

    // Check for level up
    if (newStats.level > currentProfile.avatarStats.level) {
      // Trigger level up celebration/notification
      // In a real app, this would trigger a dialog or overlay
      debugPrint('Level Up! New Level: ${newStats.level}');
      // Ideally, expose a stream or state that the UI listens to for showing a dialog/confetti.
    }

    // Update World State (reduce entropy on completion)
    final newWorldState = service.reduceEntropy(currentProfile.worldState, 0.1);

    final updatedProfile = currentProfile.copyWith(
      avatarStats: newStats,
      worldState: newWorldState,
    );

    await repository.saveUserStats(updatedProfile);
  }
}
