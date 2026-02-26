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
    final now = DateTime.now();

    // 1. Get user profile and check account creation date
    final userStatsRepository = _ref.read(userStatsRepositoryProvider);
    final userProfile = await userStatsRepository.getUserStats(userId);

    // Check if account is old enough (7+ days)
    final accountCreationDate = userProfile.accountCreatedAt ?? now;
    final daysSinceCreation = now.difference(accountCreationDate).inDays;

    if (daysSinceCreation < 7) {
      return null; // Not enough data - account less than 7 days old
    }

    // 2. Check for cached recap from the current week
    final latestRecap = await userStatsRepository.getLatestRecap(userId);
    if (latestRecap != null) {
      final endDate = latestRecap['endDate'] as Timestamp?;
      if (endDate != null) {
        final recapEndDate = endDate.toDate();
        // If a recap exists for the current week (within 7 days), return cached version
        if (now.difference(recapEndDate).inDays < 7) {
          return UserWeeklyRecap(
            id: latestRecap['id'] as String,
            userId: latestRecap['userId'] as String,
            startDate: DateTime.parse(latestRecap['startDate'] as String),
            endDate: recapEndDate,
            totalHabitsCompleted: latestRecap['totalHabitsCompleted'] as int,
            perfectDays: latestRecap['perfectDays'] as int,
            totalXpEarned: latestRecap['totalXpEarned'] as int,
            topHabitName: latestRecap['topHabitName'] as String,
            currentLevel: latestRecap['currentLevel'] as int,
            worldGrowthPercentage: (latestRecap['worldGrowthPercentage'] as num).toDouble(),
          );
        }
      }
    }

    // 3. Determine Date Range (Last 7 Days)
    final endDate = now;
    final startDate = now.subtract(const Duration(days: 7));

    // 4. Fetch Activity History
    final activities = await userStatsRepository.getWeeklyActivity(
      userId,
      startDate,
      endDate,
    );

    if (activities.isEmpty) {
      return null; // Not enough data for a recap
    }

    // 5. Aggregate Stats
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

    // 6. Determine Top Habit
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

    // 7. Calculate World Growth (Entropy reduction proxy)
    final worldGrowthPercentage = (1.0 - userProfile.worldState.entropy).clamp(
      0.0,
      1.0,
    );

    // 8. Create and save the recap
    final recap = UserWeeklyRecap(
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

    // 9. Save the recap for caching
    await userStatsRepository.saveRecap(userId, {
      'id': recap.id,
      'userId': recap.userId,
      'startDate': recap.startDate.toIso8601String(),
      'endDate': recap.endDate.toIso8601String(),
      'totalHabitsCompleted': recap.totalHabitsCompleted,
      'perfectDays': recap.perfectDays,
      'totalXpEarned': recap.totalXpEarned,
      'topHabitName': recap.topHabitName,
      'currentLevel': recap.currentLevel,
      'worldGrowthPercentage': recap.worldGrowthPercentage,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return recap;
  }
}
