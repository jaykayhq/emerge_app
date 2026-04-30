import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart'; // For habit repo provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

final weeklyRecapServiceProvider = Provider((ref) => WeeklyRecapService(ref));

class WeeklyRecapService {
  final Ref _ref;

  WeeklyRecapService(this._ref);

  Future<UserWeeklyRecap?> generateRecapIfNeeded(String userId) async {
    final now = DateTime.now();
    final userStatsRepository = _ref.read(userStatsRepositoryProvider);

    // 1. Check for cached recap from TODAY
    final latestRecapData = await userStatsRepository.getLatestRecap(userId);
    if (latestRecapData != null) {
      final latestRecap = UserWeeklyRecap.fromMap(latestRecapData);
      final recapDate = latestRecap.endDate;
      final isSameDay = recapDate.year == now.year &&
          recapDate.month == now.month &&
          recapDate.day == now.day;

      if (isSameDay) {
        return latestRecap;
      }
    }

    // 2. Determine Date Range (Last 7 Days)
    final endDate = now;
    final startDate = now.subtract(const Duration(days: 7));

    // 3. Fetch Activity History
    final activities = await userStatsRepository.getWeeklyActivity(
      userId,
      startDate,
      endDate,
    );

    // 4. Get User Profile for stats
    final userProfile = await userStatsRepository.getUserStats(userId);

    // 5. Generate and Save (Attempt AI first)
    UserWeeklyRecap? recap;
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('generateAiRecap').call({
        'userId': userId,
      });
      
      if (result.data['success'] == true) {
        final localRecap = await _calculateRecap(userId, activities, startDate, now, userProfile);
        recap = UserWeeklyRecap(
          id: result.data['recapId'] ?? localRecap.id,
          userId: userId,
          startDate: startDate,
          endDate: now,
          totalHabitsCompleted: localRecap.totalHabitsCompleted,
          perfectDays: localRecap.perfectDays,
          totalXpEarned: localRecap.totalXpEarned,
          topHabitName: localRecap.topHabitName,
          currentLevel: localRecap.currentLevel,
          worldGrowthPercentage: localRecap.worldGrowthPercentage,
          dominantIdentityThisWeek: localRecap.dominantIdentityThisWeek,
          identityHeadline: localRecap.identityHeadline,
          aiInsight: result.data['insight'],
          velocityInsights: List<String>.from(result.data['adjustments'] ?? []),
        );
      }
    } catch (e) {
      AppLogger.d('AI Recap Error: $e');
      // Fallback to local calculation
      recap = await _calculateRecap(userId, activities, startDate, now, userProfile);
    }

    if (recap != null) {
      // Save to Firestore via repository
      await userStatsRepository.saveRecap(userId, recap.toMap());
    }
    
    return recap;
  }

  Future<UserWeeklyRecap> _calculateRecap(
    String userId,
    List<Map<String, dynamic>> activities,
    DateTime startDate,
    DateTime endDate,
    dynamic userProfile,
  ) async {
    int totalHabitsCompleted = 0;
    int totalXpEarned = 0;
    Map<String, int> habitCounts = {};
    Set<String> activeDays = {};
    Map<String, int> attributeVotes = {};

    for (var activity in activities) {
      if (activity['type'] == 'habit_completion') {
        totalHabitsCompleted++;
        totalXpEarned += (activity['xpEarned'] as int? ?? 0);

        final habitId = activity['habitId'] as String;
        habitCounts[habitId] = (habitCounts[habitId] ?? 0) + 1;

        final attribute = activity['attribute'] as String?;
        if (attribute != null) {
          attributeVotes[attribute] = (attributeVotes[attribute] ?? 0) + 1;
        }

        if (activity['date'] != null) {
          final date = (activity['date'] as Timestamp).toDate();
          activeDays.add('${date.year}-${date.month}-${date.day}');
        }
      }
    }

    // Determine dominant identity
    String? dominantIdentity;
    String? identityHeadline;
    if (attributeVotes.isNotEmpty) {
      final sorted = attributeVotes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      dominantIdentity = top.key;
      identityHeadline = 'You cast ${top.value} votes for your $dominantIdentity identity.';
    } else {
      dominantIdentity = 'Pioneer';
      identityHeadline = 'You are beginning your journey of identity transformation.';
    }

    // Determine Top Habit
    String topHabitName = 'New Beginnings';
    if (habitCounts.isNotEmpty) {
      final topHabitId = habitCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final habitRepository = _ref.read(habitRepositoryProvider);
      final habit = await habitRepository.getHabit(topHabitId);
      topHabitName = habit?.title ?? 'Unknown Habit';
    }

    // Calculate World Growth
    double worldGrowthPercentage = 0.0;
    try {
      worldGrowthPercentage = (1.0 - (userProfile.worldState?.entropy ?? 0.5)).clamp(0.0, 1.0);
    } catch (_) {}

    return UserWeeklyRecap(
      id: const Uuid().v4(),
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalHabitsCompleted: totalHabitsCompleted,
      perfectDays: activeDays.length,
      totalXpEarned: totalXpEarned,
      topHabitName: topHabitName,
      currentLevel: userProfile.avatarStats?.level ?? 1,
      worldGrowthPercentage: worldGrowthPercentage,
      dominantIdentityThisWeek: dominantIdentity,
      identityHeadline: identityHeadline,
    );
  }
}
