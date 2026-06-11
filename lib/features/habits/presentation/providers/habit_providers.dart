import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/domain/services/variable_reward_service.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/recap_hub_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_providers.g.dart';

/// Fallback free tier habit limit when Remote Config is unavailable.
const int kDefaultFreeHabitLimit = 5;

class SubscriptionLimitReachedException implements Exception {
  final String message;
  const SubscriptionLimitReachedException(this.message);
}

@riverpod
MomentumService momentumService(Ref ref) => MomentumService();

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final engine = LocalGameLoopEngine();
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final socialService = ref.watch(socialActivityServiceProvider);
  return DriftHabitRepository(
    db: db,
    gameLoopEngine: engine,
    syncEngine: syncEngine,
    socialService: socialService,
  );
}

@riverpod
Stream<List<Habit>> habits(Ref ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user.isEmpty) return Stream.value([]);
      final stream = repository.watchHabits(user.id);

      // Run daily decay logic on first load
      final momentumService = ref.read(momentumServiceProvider);
      stream.first.then((habitsList) async {
        if (!ref.mounted) return;
        try {
          final today = DateTime.now();
          bool hasChanges = false;

          for (final habit in habitsList) {
            if (habit.isArchived) continue;

            final lastCompleted = habit.lastCompletedDate;
            final baseDate = lastCompleted ?? habit.createdAt;

            // Normalize to midnight for accurate calendar day counting
            final todayMidnight = DateTime(today.year, today.month, today.day);
            final baseMidnight = DateTime(
              baseDate.year,
              baseDate.month,
              baseDate.day,
            );
            final calendarDaysDifference = todayMidnight
                .difference(baseMidnight)
                .inDays;

            // If difference is 1, they completed/created it yesterday (no miss yet)
            // If difference is 2+, they missed at least yesterday
            if (calendarDaysDifference >= 2) {
              final missedDays = calendarDaysDifference - 1;
              final decayed = momentumService.applyMultiDayDecay(
                habit,
                missedDays,
              );

              if (decayed.momentumScore != habit.momentumScore ||
                  decayed.consecutiveMisses != habit.consecutiveMisses) {
                await repository.updateHabit(decayed);
                hasChanges = true;
              }
            }
          }

          if (!ref.mounted) return;
          if (hasChanges) {
            final updated = await repository.watchHabits(user.id).first;
            if (ref.mounted) {
              await ref
                  .read(userStatsControllerProvider)
                  .recalculateWorldHealth(updated);
            }
          } else {
            await ref
                .read(userStatsControllerProvider)
                .recalculateWorldHealth(habitsList);
          }
        } catch (e, s) {
          AppLogger.e('Error running daily decay', e, s);
        }
      });

      return stream;
    },
    loading: () => Stream.value([]),
    error: (error, stack) {
      AppLogger.e('Auth error in habits provider', error, stack);
      return Stream.error(error);
    },
  );
}

@riverpod
Future<void> createHabit(Ref ref, Habit habit) async {
  final keepAliveLink = ref.keepAlive();
  try {
    // Check habit limit FIRST (fail fast, no network call).
    // Skip the check for onboarding/anchor habits.
    final isOnboarding =
        habit.identityTags.contains('onboarding') ||
        habit.identityTags.contains('anchor');

    if (!isOnboarding) {
      final repository = ref.read(habitRepositoryProvider);
      final currentHabits = await repository.watchHabits(habit.userId).first;
      if (!ref.mounted) return;
      final filtered = currentHabits.where((h) => !h.isArchived).toList();
      final freeHabitLimit = ref
          .read(remoteConfigServiceProvider)
          .freeHabitLimit;

      debugPrint(
        'createHabit check: ${filtered.length} active habits, limit=$freeHabitLimit',
      );

      if (filtered.length >= freeHabitLimit) {
        // Limit exceeded — check premium (only slow path, rare case)
        final isPremium = await ref.read(isPremiumProvider.future);
        if (!ref.mounted) return;
        if (!isPremium) {
          throw SubscriptionLimitReachedException(
            'You have reached the limit of $freeHabitLimit active habits on the free tier. Upgrade to Premium for unlimited habits!',
          );
        }
      }
    }

    if (!ref.mounted) return;

    final repository = ref.read(habitRepositoryProvider);
    final result = await repository.createHabit(habit);
    if (!ref.mounted) return;

    result.fold(
      (failure) {
        AppLogger.e('Failed to create habit', failure, StackTrace.current);
        throw Exception(failure.message);
      },
      (_) {
        AppLogger.i('Successfully created habit: ${habit.id}');
      },
    );
  } catch (e, s) {
    AppLogger.e('Error in createHabit provider', e, s);
    rethrow;
  } finally {
    keepAliveLink.close();
  }
}

@riverpod
Future<HabitCompletionResult> completeHabit(Ref ref, String habitId) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final repository = ref.read(habitRepositoryProvider);
    final userAsync = ref.read(authStateChangesProvider);
    final userId = userAsync.value?.id;

    final result = await repository.completeHabit(habitId, DateTime.now());

    return await result.fold(
      (failure) async {
        AppLogger.e('Failed to complete habit', failure, StackTrace.current);
        if (ref.mounted) {
          throw Exception(failure.message);
        }
        return const HabitCompletionResult(xpEarned: 0, newStreak: 0);
      },
      (isCompleted) async {
        if (isCompleted) {
          AppLogger.i('Successfully completed habit: $habitId');
          if (userId != null) {
            final habit = await repository.getHabit(habitId);
            if (habit != null) {
              final newStreak = habit.currentStreak + 1;
              final wasRecovery = habit.consecutiveMisses > 0;

              final difficultyMultiplier = switch (habit.difficulty) {
                HabitDifficulty.easy =>
                  GamificationConstants.difficultyEasyMultiplier,
                HabitDifficulty.medium =>
                  GamificationConstants.difficultyMediumMultiplier,
                HabitDifficulty.hard =>
                  GamificationConstants.difficultyHardMultiplier,
              };
              final baseXp =
                  (GamificationConstants.baseXpPerHabit * difficultyMultiplier)
                      .toInt();

              final breakdown = calculateXpBreakdown(
                habit: habit,
                baseXp: baseXp,
                currentStreak: newStreak,
              );
              final xpGained = breakdown.totalXp;

              final isMilestone = VariableRewardService.isStreakMilestone(
                newStreak,
              );

              if (isMilestone) {
                AppLogger.i(
                  'Streak milestone reached: $newStreak days for habit $habitId',
                );
                final milestoneMessage =
                    VariableRewardService.getMilestoneMessage(newStreak);
                AppLogger.i('Milestone message: $milestoneMessage');
                if (ref.mounted) {
                  ref
                      .read(cueNotifierProvider.notifier)
                      .queueMilestoneCue(habit, newStreak);
                }
              }

              AppLogger.i(
                'Habit completed: $habitId. XP: $xpGained, Streak: $newStreak, Milestone: $isMilestone',
              );

              // Invalidate recap cache to refresh stats
              ref.read(recapRefreshCounterProvider.notifier).increment();

              // Recalculate world health after completion
              try {
                final currentHabits = await repository
                    .watchHabits(userId)
                    .first;
                if (ref.mounted) {
                  await ref
                      .read(userStatsControllerProvider)
                      .recalculateWorldHealth(currentHabits);
                }
              } catch (e) {
                AppLogger.e('Failed to recalculate world health', e);
              }

              return HabitCompletionResult(
                xpEarned: xpGained,
                newStreak: newStreak,
                isStreakMilestone: isMilestone,
                breakdown: XpRewardBreakdown(
                  baseXp: baseXp,
                  streakBonus: (xpGained - baseXp).toDouble(),
                  randomBonus: 0,
                  milestoneBonus: 0,
                  totalXp: xpGained,
                ),
                wasRecovery: wasRecovery,
              );
            }
          }
          return const HabitCompletionResult(xpEarned: 0, newStreak: 0);
        } else {
          AppLogger.i('Habit completion undone: $habitId');

          if (userId != null) {
            try {
              final currentHabits = await repository.watchHabits(userId).first;
              if (ref.mounted) {
                await ref
                    .read(userStatsControllerProvider)
                    .recalculateWorldHealth(currentHabits);
              }
            } catch (e) {
              AppLogger.e('Failed to recalculate world health on undo', e);
            }
          }

          return const HabitCompletionResult(
            xpEarned: 0,
            newStreak: 0,
            isUndo: true,
          );
        }
      },
    );
  } finally {
    keepAliveLink.close();
  }
}

@riverpod
Future<List<HabitActivity>> habitActivity(
  Ref ref, {
  required DateTime start,
  required DateTime end,
}) async {
  final repository = ref.watch(habitRepositoryProvider);
  final user = ref.watch(authStateChangesProvider).value;

  if (user == null) return [];

  return repository.getActivity(user.id, start, end);
}

class HabitCompletionResult {
  final int xpEarned;
  final int newStreak;
  final bool isStreakMilestone;
  final XpRewardBreakdown? breakdown;
  final bool isUndo;
  final bool wasRecovery;

  const HabitCompletionResult({
    required this.xpEarned,
    required this.newStreak,
    this.isStreakMilestone = false,
    this.breakdown,
    this.isUndo = false,
    this.wasRecovery = false,
  });
}
