import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/habits/data/repositories/firestore_habit_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';

import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_providers.g.dart';

class SubscriptionLimitReachedException implements Exception {
  final String message;
  const SubscriptionLimitReachedException(this.message);
}

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) {
  return FirestoreHabitRepository(FirebaseFirestore.instance);
}

@riverpod
Stream<List<Habit>> habits(Ref ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user.isEmpty) return Stream.value([]);
      return repository.watchHabits(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
}

@riverpod
Future<void> createHabit(Ref ref, Habit habit) async {
  try {
    // Check limit logic
    final isPremiumAsync = ref.read(isPremiumProvider);
    // Default to false if still loading or error, but ideally we should wait.
    // Since this is a simple provider, we'll try to get the value if available.
    final isPremium = isPremiumAsync.valueOrNull ?? false;

    if (!isPremium) {
      // Check current habit count
      final habitsAsync = ref.read(habitsProvider);
      final currentHabits = habitsAsync.valueOrNull ?? [];
      if (currentHabits.length >= 3) {
        throw const SubscriptionLimitReachedException(
          'You have reached the limit of 3 active habits on the free tier. Upgrade to add more.',
        );
      }
    }

    final repository = ref.read(habitRepositoryProvider);
    final result = await repository.createHabit(habit);

    result.fold(
      (failure) {
        AppLogger.e('Failed to create habit', failure, StackTrace.current);
        throw Exception(failure.message);
      },
      (_) {
        AppLogger.i('Successfully created habit: ${habit.id}');

        // Add to onboarding completion if this is during onboarding
        // This connects the habit creation to the onboarding flow
        final currentOnboardingState = ref.read(onboardingStateProvider);
        final hasCompletedMilestone4 = currentOnboardingState.completedMilestones.length > 4
            ? currentOnboardingState.completedMilestones[4]
            : false;
        if (hasCompletedMilestone4 && currentOnboardingState.completedMilestones.length < 6) {  // If we're past habit creation milestone
          // Update onboarding state to reflect that first habit was created
          ref.read(onboardingStateProvider.notifier).update((state) {
            final updatedMilestones = List<bool>.from(state.completedMilestones);
            // Ensure the list has enough elements
            while (updatedMilestones.length <= 5) {
              updatedMilestones.add(false);
            }
            updatedMilestones[5] = true; // Mark milestone 5 as completed

            return state.copyWith(
              completedMilestones: updatedMilestones,
            );
          });
        }
      }
    );
  } catch (e, s) {
    AppLogger.e('Error in createHabit provider', e, s);
    rethrow;
  }
}

@riverpod
Future<void> completeHabit(Ref ref, String habitId) async {
  final repository = ref.read(habitRepositoryProvider);
  final result = await repository.completeHabit(habitId, DateTime.now());

  result.fold(
    (failure) {
      AppLogger.e('Failed to complete habit', failure, StackTrace.current);
      throw Exception(failure.message);
    },
    (isCompleted) async {
      if (isCompleted) {
        AppLogger.i('Successfully completed habit: $habitId');
        final userAsync = ref.read(authStateChangesProvider);
        final userId = userAsync.value?.id;
        if (userId != null) {
          // Fetch the habit to calculate XP
          final habit = await repository.getHabit(habitId);
          if (habit != null) {
            // Log activity for gamification system
            // The actual XP calculation happens in backend Cloud Functions
            // but we can still connect to the leveling system for UI updates
          }
        }
      } else {
        AppLogger.i('Habit completion undone: $habitId');
      }
    }
  );
}
