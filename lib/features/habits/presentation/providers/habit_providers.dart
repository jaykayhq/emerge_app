import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/remote_config_service.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/habits/data/repositories/firestore_habit_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/domain/services/variable_reward_service.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/cue_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_providers.g.dart';

/// Fallback free tier habit limit when Remote Config is unavailable.
const int kDefaultFreeHabitLimit = 3;

class SubscriptionLimitReachedException implements Exception {
  final String message;
  const SubscriptionLimitReachedException(this.message);
}

@riverpod
MomentumService momentumService(Ref ref) => MomentumService();

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  final socialActivityService = ref.watch(socialActivityServiceProvider);
  final userStatsRepository = ref.watch(userStatsRepositoryProvider);
  return FirestoreHabitRepository(
    FirebaseFirestore.instance,
    socialActivityService,
    userStatsRepository,
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
      stream.first.then((habitsList) async {
        try {
          final today = DateTime.now();
          bool hasChanges = false;
          final momentumService = ref.read(momentumServiceProvider);

          for (final habit in habitsList) {
            if (habit.isArchived) continue;

            final lastCompleted = habit.lastCompletedDate;
            final baseDate = lastCompleted ?? habit.createdAt;

            // Normalize to midnight for accurate calendar day counting
            final todayMidnight = DateTime(today.year, today.month, today.day);
            final baseMidnight = DateTime(baseDate.year, baseDate.month, baseDate.day);
            final calendarDaysDifference = todayMidnight.difference(baseMidnight).inDays;

            // If difference is 1, they completed/created it yesterday (no miss yet)
            // If difference is 2+, they missed at least yesterday
            if (calendarDaysDifference >= 2) {
              final missedDays = calendarDaysDifference - 1;
              final decayed = momentumService.applyMultiDayDecay(habit, missedDays);

              if (decayed.momentumScore != habit.momentumScore ||
                  decayed.consecutiveMisses != habit.consecutiveMisses) {
                await repository.updateHabit(decayed);
                hasChanges = true;
              }
            }
          }

          if (hasChanges) {
            final updated = await repository.watchHabits(user.id).first;
            if (ref.mounted) {
              await ref.read(userStatsControllerProvider).recalculateWorldHealth(updated);
            }
          } else {
            if (ref.mounted) {
              await ref.read(userStatsControllerProvider).recalculateWorldHealth(habitsList);
            }
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
  try {
    // Check limit logic
    final isPremiumAsync = ref.read(isPremiumProvider);
    // Default to false if still loading or error, but ideally we should wait.
    // Since this is a simple provider, we'll try to get the value if available.
    final isPremium = isPremiumAsync.value ?? false;

    if (!isPremium) {
      // Check current habit count
      // BUT: Allow creation if this is an onboarding habit (bypass limit)
      final isOnboarding =
          habit.identityTags.contains('onboarding') ||
          habit.identityTags.contains(
            'anchor',
          ); // Anchors are also part of onboarding flow

      if (!isOnboarding) {
        final habitsAsync = ref.read(habitsProvider);
        final currentHabits = habitsAsync.value ?? [];
        final freeHabitLimit = ref
            .read(remoteConfigServiceProvider)
            .freeHabitLimit;
        if (currentHabits.length >= freeHabitLimit) {
          // Check if provider is still mounted before throwing
          if (!ref.mounted) {
            return; // Provider was disposed, silently return
          }
          throw SubscriptionLimitReachedException(
            'You have reached the limit of $freeHabitLimit active habits on the free tier. Upgrade to add more.',
          );
        }
      }
    }

    final repository = ref.read(habitRepositoryProvider);
    final result = await repository.createHabit(habit);

    result.fold(
      (failure) {
        AppLogger.e('Failed to create habit', failure, StackTrace.current);
        if (ref.mounted) {
          throw Exception(failure.message);
        }
      },
      (_) {
        AppLogger.i('Successfully created habit: ${habit.id}');
      },
    );
  } catch (e, s) {
    AppLogger.e('Error in createHabit provider', e, s);
    rethrow;
  }
}

@riverpod
Future<HabitCompletionResult> completeHabit(Ref ref, String habitId) async {
  final repository = ref.read(habitRepositoryProvider);
  final userAsync = ref.read(authStateChangesProvider);
  final userId = userAsync.value?.id;

  final result = await repository.completeHabit(habitId, DateTime.now());

  return result.fold(
    (failure) {
      AppLogger.e('Failed to complete habit', failure, StackTrace.current);
      if (ref.mounted) {
        throw Exception(failure.message);
      }
      return HabitCompletionResult(xpEarned: 0, newStreak: 0);
    },
    (isCompleted) async {
      if (isCompleted) {
        AppLogger.i('Successfully completed habit: $habitId');
        if (userId != null) {
          final habit = await repository.getHabit(habitId);
          if (habit != null) {
            final baseXp = _calculateBaseXp(habit);
            final currentStreak = habit.currentStreak;
            final newStreak = currentStreak + 1;

            final xpResult = calculateXpBreakdown(
              habit: habit,
              baseXp: baseXp,
              currentStreak: newStreak,
            );

            final isMilestone = VariableRewardService.isStreakMilestone(
              newStreak,
            );

            if (isMilestone) {
              AppLogger.i(
                'Streak milestone reached: $newStreak days for habit $habitId',
              );
              ref
                  .read(cueNotifierProvider.notifier)
                  .queueMilestoneCue(habit, newStreak);
            }

            AppLogger.i(
              'Habit completed: $habitId. XP: ${xpResult.totalXp}, Streak: $newStreak, Milestone: $isMilestone',
            );

            // Recalculate world health after completion
            try {
              final currentHabits = await repository.watchHabits(userId).first;
              if (ref.mounted) {
                await ref.read(userStatsControllerProvider).recalculateWorldHealth(currentHabits);
              }
            } catch (e) {
              AppLogger.e('Failed to recalculate world health', e);
            }

            return HabitCompletionResult(
              xpEarned: xpResult.totalXp,
              newStreak: newStreak,
              isStreakMilestone: isMilestone,
              breakdown: xpResult,
            );
          }
        }
        return HabitCompletionResult(xpEarned: 0, newStreak: 0);
      } else {
        AppLogger.i('Habit completion undone: $habitId');
        
        if (userId != null) {
          try {
            final currentHabits = await repository.watchHabits(userId).first;
            if (ref.mounted) {
              await ref.read(userStatsControllerProvider).recalculateWorldHealth(currentHabits);
            }
          } catch (e) {
            AppLogger.e('Failed to recalculate world health on undo', e);
          }
        }
        
        return HabitCompletionResult(xpEarned: 0, newStreak: 0, isUndo: true);
      }
    },
  );
}

int _calculateBaseXp(Habit habit) {
  switch (habit.difficulty) {
    case HabitDifficulty.easy:
      return 10;
    case HabitDifficulty.medium:
      return 20;
    case HabitDifficulty.hard:
      return 30;
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

  const HabitCompletionResult({
    required this.xpEarned,
    required this.newStreak,
    this.isStreakMilestone = false,
    this.breakdown,
    this.isUndo = false,
  });
}
