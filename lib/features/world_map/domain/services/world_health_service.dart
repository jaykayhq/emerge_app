import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';

/// Domain service for calculating dynamic world health based on user activity.
///
/// World health represents the overall vitality of a user's world based on:
/// - Recent habit completion rate (last 7 days)
/// - Decay penalty for missed days
/// - Streak bonus for consistent activity
///
/// Returns a value between 0.0 (completely decayed) and 1.0 (thriving).
class WorldHealthService {
  final UserStatsRepository _repository;
  final Map<String, double> _cache = {};
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  WorldHealthService(this._repository);

  /// Calculate world health based on user profile and recent activity.
  ///
  /// Factors:
  /// - 70% weight: Last 7 days habit completion rate
  /// - Decay penalty: Reduces health for consecutive missed days
  /// - Streak bonus: Increases health for consistent completions
  ///
  /// Returns value between 0.0 and 1.0
  Future<double> calculateWorldHealth(UserProfile profile) async {
    try {
      AppLogger.d('Calculating world health for user ${profile.uid}');

      // Get last 7 days activity
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final weeklyActivity = await _repository.getWeeklyActivity(
        profile.uid,
        sevenDaysAgo,
        now,
      );

      // Calculate completion rate (70% weight)
      final completionRate = _calculateCompletionRate(
        weeklyActivity,
        sevenDaysAgo,
        now,
      );

      // Calculate decay penalty (reduces health)
      final decayPenalty = _calculateDecayPenalty(
        profile.worldState.lastActiveDate,
        now,
      );

      // Calculate streak bonus (increases health)
      final streakBonus = _calculateStreakBonus(profile.avatarStats.streak);

      // Combine factors
      var health =
          (completionRate * 0.7) +
          (1.0 - decayPenalty) * 0.2 +
          streakBonus * 0.1;

      // Clamp between 0.0 and 1.0
      health = health.clamp(0.0, 1.0);

      AppLogger.i(
        'World health calculated: ${health.toStringAsFixed(2)} '
        '(completion: ${completionRate.toStringAsFixed(2)}, '
        'decay: ${decayPenalty.toStringAsFixed(2)}, '
        'streak: ${streakBonus.toStringAsFixed(2)})',
      );

      return health;
    } catch (e) {
      AppLogger.e('Error calculating world health', e);
      // Return current world health from profile as fallback
      return profile.worldState.worldHealth.clamp(0.0, 1.0);
    }
  }

  /// Calculate completion rate for the last 7 days.
  ///
  /// Returns value between 0.0 and 1.0
  double _calculateCompletionRate(
    List<Map<String, dynamic>> activity,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (activity.isEmpty) {
      AppLogger.d('No activity found in the last 7 days');
      return 0.0;
    }

    // Group by day
    final Map<String, int> dailyCompletions = {};
    for (final act in activity) {
      // Handle both Timestamp (from Firestore) and DateTime types
      final dateValue = act['date'];
      final DateTime date;

      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        AppLogger.w('Invalid date type: ${dateValue.runtimeType}, skipping');
        continue;
      }

      final dayKey = '${date.year}-${date.month}-${date.day}';
      dailyCompletions[dayKey] = (dailyCompletions[dayKey] ?? 0) + 1;
    }

    // Count active days (days with at least one completion)
    final activeDays = dailyCompletions.length;
    final totalDays = 7;

    // Calculate rate (active days / total days)
    final rate = activeDays / totalDays;

    AppLogger.d(
      'Completion rate: $activeDays/$totalDays days active '
      '(${(rate * 100).toStringAsFixed(0)}%)',
    );

    return rate.clamp(0.0, 1.0);
  }

  /// Calculate decay penalty based on inactivity.
  ///
  /// Returns value between 0.0 (no penalty) and 1.0 (max penalty)
  double _calculateDecayPenalty(DateTime? lastActiveDate, DateTime now) {
    if (lastActiveDate == null) {
      // No activity recorded, apply max penalty
      AppLogger.d('No last active date found, applying max decay penalty');
      return 1.0;
    }

    final daysInactive = now.difference(lastActiveDate).inDays;

    if (daysInactive <= 1) {
      // Active within last day, no penalty
      return 0.0;
    } else if (daysInactive <= 3) {
      // 2-3 days inactive: light penalty (0.2)
      final penalty = 0.2;
      AppLogger.d(
        'Light decay penalty: $penalty (inactive for $daysInactive days)',
      );
      return penalty;
    } else if (daysInactive <= 7) {
      // 4-7 days inactive: medium penalty (0.5)
      final penalty = 0.5;
      AppLogger.d(
        'Medium decay penalty: $penalty (inactive for $daysInactive days)',
      );
      return penalty;
    } else {
      // 8+ days inactive: heavy penalty (0.8)
      final penalty = 0.8;
      AppLogger.d(
        'Heavy decay penalty: $penalty (inactive for $daysInactive days)',
      );
      return penalty;
    }
  }

  /// Calculate streak bonus for consistent activity.
  ///
  /// Returns value between 0.0 and 1.0
  double _calculateStreakBonus(int streak) {
    if (streak == 0) {
      return 0.0;
    } else if (streak < 7) {
      // 1-6 days: small bonus (0.1)
      final bonus = 0.1;
      AppLogger.d('Small streak bonus: $bonus (streak: $streak)');
      return bonus;
    } else if (streak < 21) {
      // 7-20 days: medium bonus (0.3)
      final bonus = 0.3;
      AppLogger.d('Medium streak bonus: $bonus (streak: $streak)');
      return bonus;
    } else if (streak < 50) {
      // 21-49 days: large bonus (0.6)
      final bonus = 0.6;
      AppLogger.d('Large streak bonus: $bonus (streak: $streak)');
      return bonus;
    } else {
      // 50+ days: maximum bonus (1.0)
      AppLogger.d('Maximum streak bonus: 1.0 (streak: $streak)');
      return 1.0;
    }
  }

  /// Get world health with caching.
  ///
  /// Returns cached value if available and fresh, otherwise calculates fresh.
  Future<double> getWorldHealth(String userId) async {
    // Check cache
    final cached = _cache[userId];
    final isCacheFresh =
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheDuration;

    if (cached != null && isCacheFresh) {
      AppLogger.d(
        'Using cached world health for user $userId: ${cached.toStringAsFixed(2)}',
      );
      return cached;
    }

    // Calculate fresh
    AppLogger.d(
      'Cache miss or stale, calculating fresh world health for user $userId',
    );
    final profile = await _repository.getUserStats(userId);
    final health = await calculateWorldHealth(profile);

    // Update cache
    _cache[userId] = health;
    _lastCacheTime = DateTime.now();

    return health;
  }

  /// Clear cache for a specific user or all users.
  void clearCache([String? userId]) {
    if (userId != null) {
      _cache.remove(userId);
      AppLogger.d('Cleared world health cache for user $userId');
    } else {
      _cache.clear();
      _lastCacheTime = null;
      AppLogger.d('Cleared all world health cache');
    }
  }

  /// Get cache size (for debugging/monitoring).
  int get cacheSize => _cache.length;
}
