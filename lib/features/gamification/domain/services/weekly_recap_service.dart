import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart'; // For habit repo provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:uuid/uuid.dart';

final weeklyRecapServiceProvider = Provider((ref) => WeeklyRecapService(ref));

class WeeklyRecapService {
  final Ref _ref;

  WeeklyRecapService(this._ref);

  /// Generates or retrieves a recap for a specific date range.
  /// If [startDate] or [endDate] are null, it defaults to the last 7 days.
  Future<UserWeeklyRecap?> generateRecap({
    required String userId,
    String? recapId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final userStatsRepository = _ref.read(userStatsRepositoryProvider);

    // 1. If recapId is provided, fetch specific recap
    if (recapId != null) {
      final recapData = await userStatsRepository.getRecap(userId, recapId);
      if (recapData != null) {
        return UserWeeklyRecap.fromMap(recapData);
      }
    }

    DateTime startOfWeek(DateTime date) {
      final daysSinceSunday = date.weekday % 7;
      return DateTime(date.year, date.month, date.day - daysSinceSunday);
    }

    final now = DateTime.now();
    final end = endDate ?? now;
    final start = startDate ?? startOfWeek(end);

    final isPremium = _ref.read(isPremiumProvider).value ?? false;

    if (!forceRefresh) {
      final existingRecapData = await userStatsRepository.getLatestRecap(
        userId,
      );
      // For a better experience, we should ideally search by rangeId,
      // but for now, we'll check if the latest matches roughly.
      if (existingRecapData != null) {
        final existing = UserWeeklyRecap.fromMap(existingRecapData);
        if (existing.startDate.isAtSameMomentAs(start) &&
            existing.endDate.isAtSameMomentAs(end) &&
            existing.isComplete) {
          return existing;
        }
      }
    }

    // 2. Fetch Activity History
    final activities = await userStatsRepository.getWeeklyActivity(
      userId,
      start,
      end,
    );

    final userProfile = await userStatsRepository.getUserStats(userId);
    final diff = end.difference(start).inDays;
    final isComplete = diff >= 6;

    // 3. Generate and Save
    UserWeeklyRecap? recap;

    // GATED INSIGHTS LOGIC
    if (isPremium) {
      try {
        final functions = FirebaseFunctions.instance;
        final result = await functions.httpsCallable('generateAiRecap').call({
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
        });

        if (result.data['success'] == true) {
          final localRecap = await _calculateRecap(
            userId,
            activities,
            start,
            end,
            userProfile,
          );
          recap = UserWeeklyRecap(
            id: result.data['recapId'] ?? localRecap.id,
            userId: userId,
            startDate: start,
            endDate: end,
            totalHabitsCompleted: localRecap.totalHabitsCompleted,
            perfectDays: localRecap.perfectDays,
            totalXpEarned: localRecap.totalXpEarned,
            topHabitName: localRecap.topHabitName,
            currentLevel: localRecap.currentLevel,
            worldGrowthPercentage: localRecap.worldGrowthPercentage,
            dominantIdentityThisWeek: localRecap.dominantIdentityThisWeek,
            identityHeadline: localRecap.identityHeadline,
            aiInsight: result.data['insight'],
            velocityInsights: List<String>.from(
              result.data['adjustments'] ?? [],
            ),
            isComplete: isComplete,
            isAiGenerated: true,
            isLocked: false,
          );
        }
      } catch (e) {
        AppLogger.d('AI Recap Error: $e');
        // Fallback to local calculation (treated as non-premium or failed)
      }
    }

    // If still null (not premium, AI failed, or skipped), generate local-only
    if (recap == null) {
      final local = await _calculateRecap(
        userId,
        activities,
        start,
        end,
        userProfile,
      );
      recap = UserWeeklyRecap(
        id: local.id,
        userId: userId,
        startDate: start,
        endDate: end,
        totalHabitsCompleted: local.totalHabitsCompleted,
        perfectDays: local.perfectDays,
        totalXpEarned: local.totalXpEarned,
        topHabitName: local.topHabitName,
        currentLevel: local.currentLevel,
        worldGrowthPercentage: local.worldGrowthPercentage,
        dominantIdentityThisWeek: local.dominantIdentityThisWeek,
        identityHeadline: local.identityHeadline,
        isComplete: isComplete,
        isAiGenerated: false,
        isLocked: !isPremium, // Mark as locked if user isn't premium
      );
    }

    // Save to Firestore
    await userStatsRepository.saveRecap(userId, recap.toMap());

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
      identityHeadline =
          'You cast ${top.value} votes for your $dominantIdentity identity.';
    } else {
      dominantIdentity = 'Pioneer';
      identityHeadline =
          'You are beginning your journey of identity transformation.';
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
      worldGrowthPercentage = (1.0 - (userProfile.worldState?.entropy ?? 0.5))
          .clamp(0.0, 1.0);
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
