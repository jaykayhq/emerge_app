import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart'; // For habit repo provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final weeklyRecapServiceProvider = Provider((ref) => WeeklyRecapService(ref));

class WeeklyRecapService {
  final Ref _ref;

  WeeklyRecapService(this._ref);

  Future<UserWeeklyRecap?> generateRecapIfNeeded(String userId) async {
    // 1. Determine Date Range (Last 7 Days)
    final now = DateTime.now();
    final endDate = now;
    final startDate = now.subtract(const Duration(days: 7));

    // 2. Fetch Activity History
    final userStatsRepository = _ref.read(userStatsRepositoryProvider);
    final activities = await userStatsRepository.getWeeklyActivity(
      userId,
      startDate,
      endDate,
    );

    if (activities.isEmpty) {
      return null; // Not enough data for a recap
    }

    // 3. Aggregate Stats
    int totalHabitsCompleted = 0;
    int totalXpEarned = 0;
    Map<String, int> habitCounts = {};
    Set<String> activeDays = {};

    for (var activity in activities) {
      if (activity['type'] == 'habit_completion') {
        totalHabitsCompleted++;
        totalXpEarned += (activity['xpEarned'] as int? ?? 0);

        final habitId = activity['habitId'] as String;
        habitCounts[habitId] = (habitCounts[habitId] ?? 0) + 1;

        // Track active days safely
        if (activity['date'] != null) {
          final date = (activity['date'] as Timestamp).toDate();
          activeDays.add('${date.year}-${date.month}-${date.day}');
        }
      }
    }

    // 4. Determine Top Habit
    String topHabitName = 'None';
    if (habitCounts.isNotEmpty) {
      final topHabitId = habitCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      // Optimistically try to fetch title, otherwise fallback
      final habitRepository = _ref.read(habitRepositoryProvider);
      final habit = await habitRepository.getHabit(topHabitId);
      topHabitName = habit?.title ?? 'Unknown Habit';
    }

    // 5. Fetch Current User Stats for Context
    final userProfile = await userStatsRepository.getUserStats(userId);

    // 6. Calculate World Growth (Entropy reduction proxy)
    // We can assume perfect entropy (0.0) is 100% growth, decayed (1.0) is 0%.
    // Or compare with a snapshot if we had one. For now, use current inverse entropy.
    final worldGrowthPercentage = (1.0 - userProfile.worldState.entropy).clamp(
      0.0,
      1.0,
    );

    return UserWeeklyRecap(
      id: const Uuid().v4(),
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalHabitsCompleted: totalHabitsCompleted,
      perfectDays:
          activeDays.length, // Approximation: Active days = "Perfect" for now
      totalXpEarned: totalXpEarned,
      topHabitName: topHabitName,
      currentLevel: userProfile.avatarStats.level,
      worldGrowthPercentage: worldGrowthPercentage,
    );
  }
}
