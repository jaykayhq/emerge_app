import 'package:equatable/equatable.dart';

/// Cue Trigger Types - The "When" of habit initiation
///
/// Based on behavioral science, cues must be:
/// 1. OBVIOUS: Visible and clear signals
/// 2. CONTEXTUAL: Tied to specific situations
/// 3. ACTIONABLE: Leading directly to the desired behavior
enum CueTriggerType {
  /// Time-based trigger (scheduled reminders)
  time,

  /// Location-based trigger (GPS geofencing)
  location,

  /// Context-based trigger (app state, user activity)
  context,

  /// Social-based trigger (friend activity, tribe events)
  social,

  /// Behavior-chain trigger (after completing another habit)
  habitStacking,

  /// Energy-based trigger (user energy level detection)
  energy,

  /// Milestone-based trigger (achievements, streak milestones)
  milestone,

  /// Recovery-based trigger (after missed habit - "Never Miss Twice")
  recovery,

  /// AI-personalized trigger (ML-predicted optimal timing)
  aiPersonalized,
}

/// Cue Intensity Levels - Managing urgency without stress
///
/// Based on research that excessive urgency creates resistance
/// while insufficient urgency leads to procrastination.
enum CueIntensity {
  /// Gentle reminder, low pressure
  gentle,

  /// Standard reminder, moderate pressure
  moderate,

  /// Urgent but not overwhelming
  urgent,

  /// Critical (streak at risk, time-sensitive)
  critical,
}

/// Cue Delivery Channels - Where the cue appears
enum CueDeliveryChannel {
  /// Push notification (system level)
  pushNotification,

  /// In-app popup (modal dialog)
  inAppPopup,

  /// In-app banner (non-modal, dismissible)
  inAppBanner,

  /// Home screen widget
  widget,

  /// Haptic feedback (vibration pattern)
  haptic,

  /// Sound notification
  sound,

  /// Badge/icon update
  badge,

  /// Subtle UI hint (glow, pulse, color change)
  subtleHint,
}

/// Cue Category - The psychological purpose of the cue
enum CueCategory {
  /// Habit initiation - starting the behavior
  initiation,

  /// Habit completion - reinforcing finished behavior
  completion,

  /// Social engagement - community/friend interactions
  social,

  /// Progress celebration - milestones and achievements
  celebration,

  /// Recovery support - bouncing back from missed habits
  recovery,

  /// Discovery - exploring new habits and features
  discovery,

  /// Reflection - daily review and insights
  reflection,

  /// Motivation - when engagement is dropping
  motivation,
}

/// Core Cue Entity - The fundamental unit of habit triggers
///
/// Implements the 1st Law of Behavior Change: MAKE IT OBVIOUS
///
/// Each cue contains:
/// - Trigger conditions (when it fires)
/// - Content (what it shows)
/// - Metadata (for personalization and analytics)
class Cue extends Equatable {
  /// Unique identifier for this cue instance
  final String id;

  /// Type of trigger that activates this cue
  final CueTriggerType triggerType;

  /// Psychological category of this cue
  final CueCategory category;

  /// Intensity level (manages urgency perception)
  final CueIntensity intensity;

  /// Primary delivery channel(s) for this cue
  final List<CueDeliveryChannel> channels;

  /// Title/headline of the cue
  final String title;

  /// Body content - the actionable message
  final String body;

  /// Associated habit ID (if habit-specific)
  final String? habitId;

  /// Associated user archetype for personalization
  final String userArchetype;

  /// Trigger condition data (time, location, context rules)
  final Map<String, dynamic> triggerData;

  /// Whether this cue has been shown to the user
  final bool isShown;

  /// Whether the user took action on this cue
  final bool actionTaken;

  /// When this cue was created
  final DateTime createdAt;

  /// When this cue should expire (if applicable)
  final DateTime? expiresAt;

  /// Priority for queue management (higher = shown first)
  final int priority;

  /// Personalization tokens for dynamic content insertion
  final Map<String, String> personalizationTokens;

  /// A/B testing variant ID (for experimentation)
  final String? variantId;

  /// Campaign ID (grouping related cues)
  final String? campaignId;

  const Cue({
    required this.id,
    required this.triggerType,
    required this.category,
    required this.intensity,
    required this.channels,
    required this.title,
    required this.body,
    required this.userArchetype,
    this.habitId,
    this.triggerData = const {},
    this.isShown = false,
    this.actionTaken = false,
    required this.createdAt,
    this.expiresAt,
    this.priority = 50,
    this.personalizationTokens = const {},
    this.variantId,
    this.campaignId,
  });

  /// Check if cue has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if cue should be shown now
  bool get shouldShow {
    if (isShown) return false;
    if (isExpired) return false;
    return true;
  }

  /// Get the fully personalized title
  String get personalizedTitle {
    String result = title;
    personalizationTokens.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Get the fully personalized body
  String get personalizedBody {
    String result = body;
    personalizationTokens.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Calculate relevance score for personalization
  double get relevanceScore {
    double score = priority.toDouble();

    // Boost for time-sensitive cues
    if (expiresAt != null) {
      final timeUntilExpiry = expiresAt!.difference(DateTime.now());
      if (timeUntilExpiry.inHours < 2) {
        score += 30;
      } else if (timeUntilExpiry.inHours < 6) {
        score += 15;
      }
    }

    // Boost for user's preferred archetype
    if (triggerType == CueTriggerType.aiPersonalized) {
      score += 20;
    }

    return score.clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        id,
        triggerType,
        category,
        intensity,
        channels,
        title,
        body,
        habitId,
        userArchetype,
        isShown,
        actionTaken,
        createdAt,
        expiresAt,
        priority,
      ];

  /// Create a copy with modified fields
  Cue copyWith({
    String? id,
    CueTriggerType? triggerType,
    CueCategory? category,
    CueIntensity? intensity,
    List<CueDeliveryChannel>? channels,
    String? title,
    String? body,
    String? habitId,
    String? userArchetype,
    Map<String, dynamic>? triggerData,
    bool? isShown,
    bool? actionTaken,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? priority,
    Map<String, String>? personalizationTokens,
    String? variantId,
    String? campaignId,
  }) {
    return Cue(
      id: id ?? this.id,
      triggerType: triggerType ?? this.triggerType,
      category: category ?? this.category,
      intensity: intensity ?? this.intensity,
      channels: channels ?? this.channels,
      title: title ?? this.title,
      body: body ?? this.body,
      userArchetype: userArchetype ?? this.userArchetype,
      habitId: habitId ?? this.habitId,
      triggerData: triggerData ?? this.triggerData,
      isShown: isShown ?? this.isShown,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      priority: priority ?? this.priority,
      personalizationTokens: personalizationTokens ?? this.personalizationTokens,
      variantId: variantId ?? this.variantId,
      campaignId: campaignId ?? this.campaignId,
    );
  }
}

/// Cue Rule - Defines when a cue should be triggered
///
/// Encapsulates the logic for cue activation, allowing
/// dynamic, context-aware triggering.
class CueRule extends Equatable {
  /// Unique rule identifier
  final String id;

  /// Which habit this rule applies to (null = global rules)
  final String? habitId;

  /// Trigger type for this rule
  final CueTriggerType triggerType;

  /// Trigger conditions (evaluated to determine if cue fires)
  final Map<String, dynamic> conditions;

  /// Cooldown period between triggers (prevents spam)
  final Duration cooldown;

  /// Time window when this rule is active
  final TimeWindow? activeWindow;

  /// Priority (higher priority rules evaluated first)
  final int priority;

  /// Whether this rule is currently enabled
  final bool isEnabled;

  const CueRule({
    required this.id,
    this.habitId,
    required this.triggerType,
    required this.conditions,
    required this.cooldown,
    this.activeWindow,
    this.priority = 50,
    this.isEnabled = true,
  });

  /// Check if rule should trigger based on current context
  bool shouldTrigger(Map<String, dynamic> context) {
    if (!isEnabled) {
      return false;
    }

    // Check time window
    if (activeWindow != null && !activeWindow!.isActiveNow()) {
      return false;
    }

    // Check conditions
    for (final entry in conditions.entries) {
      final contextValue = context[entry.key];
      final conditionValue = entry.value;

      if (!_evaluateCondition(contextValue, conditionValue)) {
        return false;
      }
    }

    return true;
  }

  bool _evaluateCondition(dynamic contextValue, dynamic conditionValue) {
    if (conditionValue is Map) {
      final operator = conditionValue['operator'];
      final value = conditionValue['value'];

      switch (operator) {
        case 'equals':
          return contextValue == value;
        case 'not_equals':
          return contextValue != value;
        case 'greater_than':
          return (contextValue as num) > (value as num);
        case 'less_than':
          return (contextValue as num) < (value as num);
        case 'contains':
          return (contextValue as String).contains(value as String);
        case 'in':
          return (value as List).contains(contextValue);
        default:
          return false;
      }
    }
    return contextValue == conditionValue;
  }

  @override
  List<Object?> get props => [
        id,
        habitId,
        triggerType,
        conditions,
        cooldown,
        activeWindow,
        priority,
        isEnabled,
      ];
}

/// Time Window - Restricts when cues can be shown
///
/// Respects user's "quiet hours" and optimal engagement times.
class TimeWindow extends Equatable {
  /// Start of active window (hour 0-23)
  final int startHour;

  /// End of active window (hour 0-23)
  final int endHour;

  /// Days of week when window is active (null = all days)
  final List<int>? activeDays;

  const TimeWindow({
    required this.startHour,
    required this.endHour,
    this.activeDays,
  });

  /// Check if the time window is currently active
  bool isActiveNow() {
    final now = DateTime.now();

    // Check day of week
    if (activeDays != null && !activeDays!.contains(now.weekday)) {
      return false;
    }

    // Check time
    final currentHour = now.hour;
    if (startHour <= endHour) {
      return currentHour >= startHour && currentHour <= endHour;
    } else {
      // Handles overnight windows (e.g., 22:00 to 06:00)
      return currentHour >= startHour || currentHour <= endHour;
    }
  }

  @override
  List<Object?> get props => [startHour, endHour, activeDays];
}

/// Cue Engagement Metrics - Track cue effectiveness
///
/// Measures the 1st Law's effectiveness: ARE CUES WORKING?
class CueEngagementMetrics extends Equatable {
  /// Cue ID being tracked
  final String cueId;

  /// Number of times this cue was shown
  final int impressions;

  /// Number of times user took the desired action
  final int conversions;

  /// Number of times user dismissed the cue
  final int dismissals;

  /// Average time from cue display to action (milliseconds)
  final int avgTimeToAction;

  /// Last time this cue was shown
  final DateTime? lastShownAt;

  /// Last time user took action on this cue
  final DateTime? lastActionAt;

  const CueEngagementMetrics({
    required this.cueId,
    this.impressions = 0,
    this.conversions = 0,
    this.dismissals = 0,
    this.avgTimeToAction = 0,
    this.lastShownAt,
    this.lastActionAt,
  });

  /// Calculate conversion rate (0.0 to 1.0)
  double get conversionRate {
    if (impressions == 0) return 0.0;
    return conversions / impressions;
  }

  /// Calculate dismissal rate (0.0 to 1.0)
  double get dismissalRate {
    if (impressions == 0) return 0.0;
    return dismissals / impressions;
  }

  /// Calculate engagement score (0-100)
  ///
  /// Combines conversion rate and speed to action
  double get engagementScore {
    final rateScore = conversionRate * 70; // Max 70 points
    final speedScore = _calculateSpeedScore(); // Max 30 points
    return (rateScore + speedScore).clamp(0.0, 100.0);
  }

  double _calculateSpeedScore() {
    if (avgTimeToAction == 0) return 0.0;

    // Faster action = higher score
    // < 5 seconds: 30 points
    // < 30 seconds: 20 points
    // < 2 minutes: 10 points
    // >= 2 minutes: 5 points
    final seconds = avgTimeToAction / 1000;
    if (seconds < 5) return 30.0;
    if (seconds < 30) return 20.0;
    if (seconds < 120) return 10.0;
    return 5.0;
  }

  @override
  List<Object?> get props => [
        cueId,
        impressions,
        conversions,
        dismissals,
        avgTimeToAction,
        lastShownAt,
        lastActionAt,
      ];
}
