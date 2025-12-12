import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/habits/data/repositories/firestore_habit_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
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
  result.fold((error) => throw Exception(error), (_) => null);
}

@riverpod
Future<void> completeHabit(Ref ref, String habitId) async {
  final repository = ref.read(habitRepositoryProvider);
  final result = await repository.completeHabit(habitId, DateTime.now());

  result.fold((error) => throw Exception(error), (isCompleted) async {
    if (isCompleted) {
      final userAsync = ref.read(authStateChangesProvider);
      final userId = userAsync.value?.id;
      if (userId != null) {
        // Fetch the habit to calculate XP
        final habit = await repository.getHabit(habitId);
        if (habit != null) {
          final userStatsController = ref.read(userStatsControllerProvider);
          await userStatsController.awardXpForHabit(habit);
        }
      }
    }
  });
}
