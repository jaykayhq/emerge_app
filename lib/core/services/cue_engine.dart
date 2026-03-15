import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// CUE ENGINE - The Intelligence Behind "Make It Obvious"
///
/// The CueEngine implements the 1st Law of Behavior Change by managing
/// the entire lifecycle of cues: creation, scheduling, delivery, and
/// effectiveness measurement.
///
/// PSYCHOLOGICAL FOUNDATIONS:
/// 1. IMPLEMENTATION INTENTIONS: "When X happens, I will do Y"
/// 2. HABIT STACKING: Linking new habits to existing routines
/// 3. ENVIRONMENT DESIGN: Making cues visible in the right context
/// 4. VARIABLE REWARD SCHEDULE: Preventing cue habituation
class CueEngine {
  CueEngine._internal();

  static final CueEngine _instance = CueEngine._internal();
  factory CueEngine() => _instance;

  // ============ STATE ============

  /// Active cue queue (sorted by priority/relevance)
  final ListQueue<Cue> _cueQueue = ListQueue<Cue>();

  /// Registered cue rules
  final Map<String, CueRule> _rules = {};

  /// User's preferred quiet hours
  TimeWindow? _quietHours;

  /// User's archetype for personalization
  UserArchetype _userArchetype = UserArchetype.none;

  /// Last trigger timestamp for each rule (cooldown management)
  final Map<String, DateTime> _lastTriggerTime = {};

  /// Stream controller for cue events
  final _cueController = StreamController<Cue>.broadcast();

  /// Engagement metrics storage
  final Map<String, CueEngagementMetrics> _metrics = {};

  /// Gamification service for XP/reward calculations
  final GamificationService _gamificationService = GamificationService();

  // ============ CONFIGURATION ============

  /// Maximum cues to show per hour (prevents notification fatigue)
  static const int maxCuesPerHour = 5;

  /// Minimum time between identical cues
  static const Duration identicalCueCooldown = Duration(hours: 4);

  /// Default quiet hours (10 PM - 7 AM)
  static const TimeWindow defaultQuietHours = TimeWindow(
    startHour: 22,
    endHour: 7,
  );

  // ============ PUBLIC STREAMS ============

  /// Stream of cues ready to be displayed
  Stream<Cue> get cueStream => _cueController.stream;

  // ============ INITIALIZATION ============

  /// Initialize the cue engine with user preferences
  Future<void> initialize({UserArchetype? archetype}) async {
    if (archetype != null) {
      _userArchetype = archetype;
    }

    final prefs = await SharedPreferences.getInstance();

    // Load quiet hours
    final quietHoursStart = prefs.getInt('quiet_hours_start');
    final quietHoursEnd = prefs.getInt('quiet_hours_end');
    if (quietHoursStart != null && quietHoursEnd != null) {
      _quietHours = TimeWindow(
        startHour: quietHoursStart,
        endHour: quietHoursEnd,
      );
    } else {
      _quietHours = defaultQuietHours;
    }

    // Load metrics
    await _loadMetrics();

    // Register default cue rules
    _registerDefaultRules();

    debugPrint('CueEngine initialized for $_userArchetype');
  }

  void _registerDefaultRules() {
    // Time-based habit reminders
    registerRule(CueRule(
      id: 'habit_reminder_time',
      triggerType: CueTriggerType.time,
      conditions: {'isScheduledTime': true},
      cooldown: const Duration(hours: 24),
      priority: 80,
    ));

    // Streak at risk warnings
    registerRule(CueRule(
      id: 'streak_at_risk',
      triggerType: CueTriggerType.recovery,
      conditions: {
        'operator': 'greater_than',
        'value': 2,
        'field': 'hoursSinceReminder',
      },
      cooldown: const Duration(hours: 2),
      priority: 90,
    ));

    // Energy-based cues (low energy = gentle reminders)
    registerRule(CueRule(
      id: 'low_energy_reminder',
      triggerType: CueTriggerType.energy,
      conditions: {'energyLevel': 'low'},
      cooldown: const Duration(hours: 6),
      priority: 40,
    ));

    // Social proof triggers (friend completed habit)
    registerRule(CueRule(
      id: 'social_proof_trigger',
      triggerType: CueTriggerType.social,
      conditions: {'friendCompleted': true},
      cooldown: const Duration(minutes: 30),
      priority: 70,
    ));

    // Milestone celebrations
    registerRule(CueRule(
      id: 'milestone_celebration',
      triggerType: CueTriggerType.milestone,
      conditions: {
        'operator': 'in',
        'value': [7, 14, 21, 30, 50, 66, 100],
        'field': 'streakDays',
      },
      cooldown: Duration.zero,
      priority: 100,
    ));
  }

  // ============ CUE CREATION ============

  /// Create a habit initiation cue (archetype-personalized)
  Cue createHabitInitiationCue(Habit habit) {
    final archetype = _userArchetype;
    final template = NotificationTemplates.reminderMessage(archetype, habit.title);

    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.time,
      category: CueCategory.initiation,
      intensity: _calculateInitiationIntensity(habit),
      channels: [CueDeliveryChannel.pushNotification, CueDeliveryChannel.inAppBanner],
      title: 'Time to focus, ${_getArchetypeTitle(archetype)}',
      body: template,
      userArchetype: archetype.name,
      habitId: habit.id,
      createdAt: DateTime.now(),
      priority: _calculatePriority(habit),
      personalizationTokens: {
        'habitTitle': habit.title,
        'streak': habit.currentStreak.toString(),
      },
    );
  }

  /// Create a streak recovery cue ("Never Miss Twice")
  Cue createRecoveryCue(Habit habit) {
    final archetype = _userArchetype;
    final streakWarning = NotificationTemplates.streakWarning(
      archetype,
      habit.currentStreak,
    );

    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.recovery,
      category: CueCategory.recovery,
      intensity: CueIntensity.urgent,
      channels: [
        CueDeliveryChannel.pushNotification,
        CueDeliveryChannel.inAppPopup,
        CueDeliveryChannel.haptic,
      ],
      title: '⚠️ Streak at Risk!',
      body: streakWarning,
      userArchetype: archetype.name,
      habitId: habit.id,
      createdAt: DateTime.now(),
      priority: 95,
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      personalizationTokens: {
        'habitTitle': habit.title,
        'streakDays': habit.currentStreak.toString(),
      },
    );
  }

  /// Create a social proof cue (friend activity)
  Cue createSocialProofCue(String friendName, String friendArchetype, String habitTitle) {
    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.social,
      category: CueCategory.social,
      intensity: CueIntensity.moderate,
      channels: [CueDeliveryChannel.inAppBanner, CueDeliveryChannel.badge],
      title: '$friendName just completed $habitTitle!',
      body: 'Keep the momentum going! Your tribe is counting on you.',
      userArchetype: _userArchetype.name,
      createdAt: DateTime.now(),
      priority: 65,
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
      personalizationTokens: {
        'friendName': friendName,
        'habitTitle': habitTitle,
      },
    );
  }

  /// Create a milestone celebration cue
  Cue createMilestoneCue(Habit habit, int milestoneDays) {
    final archetype = _userArchetype;
    final levelUp = NotificationTemplates.levelUp(archetype, milestoneDays);

    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.milestone,
      category: CueCategory.celebration,
      intensity: CueIntensity.urgent,
      channels: [
        CueDeliveryChannel.inAppPopup,
        CueDeliveryChannel.haptic,
        CueDeliveryChannel.sound,
      ],
      title: '🏆 MILESTONE ACHIEVED!',
      body: levelUp,
      userArchetype: archetype.name,
      habitId: habit.id,
      createdAt: DateTime.now(),
      priority: 100,
      personalizationTokens: {
        'habitTitle': habit.title,
        'milestoneDays': milestoneDays.toString(),
        'xpGained': _gamificationService.calculateXpGain(habit).toString(),
      },
    );
  }

  /// Create a discovery cue (new habit/feature suggestion)
  Cue createDiscoveryCue(String suggestedHabit, String reason) {
    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.aiPersonalized,
      category: CueCategory.discovery,
      intensity: CueIntensity.gentle,
      channels: [CueDeliveryChannel.inAppBanner],
      title: '✨ New Opportunity',
      body: 'Based on your progress, try: $suggestedHabit\n\n$reason',
      userArchetype: _userArchetype.name,
      createdAt: DateTime.now(),
      priority: 45,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      personalizationTokens: {
        'suggestedHabit': suggestedHabit,
        'reason': reason,
      },
    );
  }

  /// Create a reflection cue (daily review)
  Cue createReflectionCue(double completionRate) {
    final emoji = completionRate >= 0.8 ? '🌟' :
                  completionRate >= 0.5 ? '💪' : '🌱';

    return Cue(
      id: const Uuid().v4(),
      triggerType: CueTriggerType.context,
      category: CueCategory.reflection,
      intensity: CueIntensity.gentle,
      channels: [CueDeliveryChannel.inAppBanner],
      title: '$emoji Daily Reflection',
      body: 'You completed ${(completionRate * 100).toInt()}% of habits today. '
             'Take a moment to reflect on your journey.',
      userArchetype: _userArchetype.name,
      createdAt: DateTime.now(),
      priority: 55,
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      personalizationTokens: {
        'completionRate': (completionRate * 100).toInt().toString(),
      },
    );
  }

  // ============ CUE MANAGEMENT ============

  /// Register a new cue rule
  void registerRule(CueRule rule) {
    _rules[rule.id] = rule;
    debugPrint('Registered cue rule: ${rule.id}');
  }

  /// Unregister a cue rule
  void unregisterRule(String ruleId) {
    _rules.remove(ruleId);
    debugPrint('Unregistered cue rule: $ruleId');
  }

  /// Queue a cue for display
  Future<void> queueCue(Cue cue) async {
    // Respect quiet hours
    if (_quietHours != null && _quietHours!.isActiveNow()) {
      debugPrint('Cue queued but suppressed (quiet hours): ${cue.id}');
      return;
    }

    // Check rate limiting
    if (!_shouldShowCueNow(cue)) {
      debugPrint('Cue rate limited: ${cue.id}');
      return;
    }

    // Add to queue
    _cueQueue.add(cue);
    _cueController.add(cue);

    // Track impression
    _trackImpression(cue);

    debugPrint('Cue queued: ${cue.title} (${cue.triggerType})');
  }

  /// Check if cue should be shown now (rate limiting)
  bool _shouldShowCueNow(Cue cue) {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // Count cues shown in the last hour
    final recentCues = _metrics.values
        .where((m) => m.lastShownAt != null && m.lastShownAt!.isAfter(oneHourAgo))
        .length;

    if (recentCues >= maxCuesPerHour) {
      return false;
    }

    // Check cooldown for this specific rule
    if (cue.habitId != null) {
      final lastTrigger = _lastTriggerTime[cue.habitId];
      if (lastTrigger != null) {
        final timeSinceLastTrigger = now.difference(lastTrigger);
        if (timeSinceLastTrigger < identicalCueCooldown) {
          return false;
        }
      }
    }

    return true;
  }

  /// Mark cue as acted upon
  void markActionTaken(String cueId, {Duration? timeToAction}) {
    final metrics = _metrics[cueId];
    if (metrics != null) {
      final updated = CueEngagementMetrics(
        cueId: cueId,
        impressions: metrics.impressions,
        conversions: metrics.conversions + 1,
        dismissals: metrics.dismissals,
        avgTimeToAction: timeToAction != null
            ? ((metrics.avgTimeToAction * metrics.conversions + timeToAction.inMilliseconds) /
                (metrics.conversions + 1)).toInt()
            : metrics.avgTimeToAction,
        lastShownAt: metrics.lastShownAt,
        lastActionAt: DateTime.now(),
      );
      _metrics[cueId] = updated;
      _saveMetrics(updated);
    }

    // Update cooldown
    final cue = _cueQueue.firstWhere((c) => c.id == cueId, orElse: () => cueId as Cue);
    if (cue.habitId != null) {
      _lastTriggerTime[cue.habitId!] = DateTime.now();
    }

    debugPrint('Cue action taken: $cueId');
  }

  /// Mark cue as dismissed
  void markDismissed(String cueId) {
    final metrics = _metrics[cueId];
    if (metrics != null) {
      final updated = CueEngagementMetrics(
        cueId: cueId,
        impressions: metrics.impressions,
        conversions: metrics.conversions,
        dismissals: metrics.dismissals + 1,
        avgTimeToAction: metrics.avgTimeToAction,
        lastShownAt: metrics.lastShownAt,
        lastActionAt: metrics.lastActionAt,
      );
      _metrics[cueId] = updated;
      _saveMetrics(updated);
    }

    debugPrint('Cue dismissed: $cueId');
  }

  // ============ CONTEXT-AWARE TRIGGERING ============

  /// Evaluate all rules and trigger matching cues
  Future<void> evaluateRules(Map<String, dynamic> context) async {
    for (final rule in _rules.values) {
      if (rule.shouldTrigger(context)) {
        await _triggerRule(rule, context);
      }
    }
  }

  Future<void> _triggerRule(CueRule rule, Map<String, dynamic> context) async {
    // Check cooldown
    final lastTrigger = _lastTriggerTime[rule.id];
    if (lastTrigger != null) {
      final timeSinceLastTrigger = DateTime.now().difference(lastTrigger);
      if (timeSinceLastTrigger < rule.cooldown) {
        return;
      }
    }

    // Create appropriate cue based on rule type
    Cue? cue;
    switch (rule.triggerType) {
      case CueTriggerType.time:
        // Handled by notification service
        break;
      case CueTriggerType.location:
        cue = _createLocationBasedCue(context);
        break;
      case CueTriggerType.social:
        cue = _createSocialCue(context);
        break;
      case CueTriggerType.recovery:
        cue = _createRecoveryCue(context);
        break;
      default:
        break;
    }

    if (cue != null) {
      await queueCue(cue);
      _lastTriggerTime[rule.id] = DateTime.now();
    }
  }

  Cue? _createLocationBasedCue(Map<String, dynamic> context) {
    // Location-based cues (future implementation with geolocation)
    final location = context['currentLocation'];
    if (location == null) return null;

    // Check if user is at a relevant location (gym, library, etc.)
    // This would integrate with user's habit locations
    return null; // Implement based on user's location preferences
  }

  Cue? _createSocialCue(Map<String, dynamic> context) {
    final friendName = context['friendName'] as String?;
    final habitTitle = context['habitTitle'] as String?;
    final friendArchetype = context['friendArchetype'] as String?;

    if (friendName != null && habitTitle != null) {
      return createSocialProofCue(friendName, friendArchetype ?? 'Creator', habitTitle);
    }
    return null;
  }

  Cue? _createRecoveryCue(Map<String, dynamic> context) {
    final habit = context['habit'] as Habit?;
    if (habit == null) return null;

    // Only trigger if habit was missed today
    final now = DateTime.now();
    final lastCompleted = habit.lastCompletedDate;

    if (lastCompleted == null ||
        (lastCompleted.year != now.year ||
         lastCompleted.month != now.month ||
         lastCompleted.day != now.day)) {
      // Check if reminder was sent earlier today
      final lastReminder = context['lastReminderTime'] as DateTime?;
      if (lastReminder == null || now.difference(lastReminder).inHours >= 2) {
        return createRecoveryCue(habit);
      }
    }
    return null;
  }

  // ============ ANALYTICS ============

  /// Get metrics for a specific cue
  CueEngagementMetrics? getMetrics(String cueId) => _metrics[cueId];

  /// Get overall cue performance
  Map<String, dynamic> getOverallPerformance() {
    if (_metrics.isEmpty) {
      return {
        'totalCues': 0,
        'avgConversionRate': 0.0,
        'avgEngagementScore': 0.0,
      };
    }

    final totalConversions = _metrics.values.fold<int>(0, (sum, m) => sum + m.conversions);
    final totalImpressions = _metrics.values.fold<int>(0, (sum, m) => sum + m.impressions);
    final avgScore = _metrics.values
        .map((m) => m.engagementScore)
        .reduce((a, b) => a + b) / _metrics.length;

    return {
      'totalCues': _metrics.length,
      'totalConversions': totalConversions,
      'totalImpressions': totalImpressions,
      'avgConversionRate': totalImpressions > 0 ? totalConversions / totalImpressions : 0.0,
      'avgEngagementScore': avgScore,
    };
  }

  void _trackImpression(Cue cue) {
    final existing = _metrics[cue.id];
    _metrics[cue.id] = CueEngagementMetrics(
      cueId: cue.id,
      impressions: (existing?.impressions ?? 0) + 1,
      conversions: existing?.conversions ?? 0,
      dismissals: existing?.dismissals ?? 0,
      avgTimeToAction: existing?.avgTimeToAction ?? 0,
      lastShownAt: DateTime.now(),
      lastActionAt: existing?.lastActionAt,
    );
    _saveMetrics(_metrics[cue.id]!);
  }

  Future<void> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final metricsJson = prefs.getString('cue_metrics');
    if (metricsJson != null) {
      // Deserialize metrics (implement JSON serialization)
      debugPrint('Loaded cue metrics');
    }
  }

  Future<void> _saveMetrics(CueEngagementMetrics metrics) async {
    final prefs = await SharedPreferences.getInstance();
    // Serialize and save metrics (implement JSON serialization)
    await prefs.setInt('cue_impressions_${metrics.cueId}', metrics.impressions);
    await prefs.setInt('cue_conversions_${metrics.cueId}', metrics.conversions);
  }

  // ============ HELPERS ============

  String _getArchetypeTitle(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Champion';
      case UserArchetype.scholar:
        return 'Seeker';
      case UserArchetype.creator:
        return 'Visionary';
      case UserArchetype.stoic:
        return 'Sage';
      case UserArchetype.zealot:
        return 'Devoted';
      case UserArchetype.none:
        return 'Builder';
    }
  }

  CueIntensity _calculateInitiationIntensity(Habit habit) {
    // Higher intensity for habits at risk of breaking streak
    if (habit.currentStreak == 0) {
      return CueIntensity.moderate;
    } else if (habit.currentStreak < 3) {
      return CueIntensity.moderate;
    } else if (habit.currentStreak < 7) {
      return CueIntensity.gentle;
    } else {
      // Established habits get gentle cues
      return CueIntensity.gentle;
    }
  }

  int _calculatePriority(Habit habit) {
    int base = 50;

    // Boost for active streaks
    base += habit.currentStreak * 2;

    // Boost for difficulty
    switch (habit.difficulty) {
      case HabitDifficulty.hard:
        base += 15;
        break;
      case HabitDifficulty.medium:
        base += 10;
        break;
      case HabitDifficulty.easy:
        base += 5;
        break;
    }

    // Boost for important attributes
    if (habit.attribute == HabitAttribute.focus ||
        habit.attribute == HabitAttribute.strength) {
      base += 10;
    }

    return base.clamp(0, 100);
  }

  /// Set quiet hours
  Future<void> setQuietHours(TimeWindow window) async {
    _quietHours = window;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiet_hours_start', window.startHour);
    await prefs.setInt('quiet_hours_end', window.endHour);
  }

  /// Cleanup resources
  void dispose() {
    _cueController.close();
  }
}
