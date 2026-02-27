import 'package:equatable/equatable.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// Entity representing notification scheduling configuration for a habit.
/// Stored in Firestore to sync notification schedules across devices.
class HabitNotificationSchedule extends Equatable {
  /// ID of the habit this schedule belongs to
  final String habitId;

  /// ID of the user who owns this schedule
  final String userId;

  /// User archetype for personalized messaging
  final UserArchetype archetype;

  /// Reminder time in "HH:MM" format (24-hour)
  final String reminderTime;

  /// Frequency of the habit
  final HabitFrequency frequency;

  /// Specific days for reminders (1=Monday, 7=Sunday)
  final List<int> specificDays;

  /// Whether the welcome notification has been sent
  final bool welcomeNotified;

  /// Timestamp of the last reminder sent
  final DateTime? lastReminderSent;

  /// Whether notifications are enabled for this habit
  final bool enabled;

  /// FCM token for push notifications
  final String? fcmToken;

  /// Timestamp of the last streak warning sent
  final DateTime? lastStreakWarningSent;

  /// Number of streak warnings sent
  final int streakWarningCount;

  /// When this schedule was created
  final DateTime createdAt;

  const HabitNotificationSchedule({
    required this.habitId,
    required this.userId,
    required this.archetype,
    this.reminderTime = '07:00',
    this.frequency = HabitFrequency.daily,
    this.specificDays = const [],
    this.welcomeNotified = false,
    this.lastReminderSent,
    this.enabled = true,
    this.fcmToken,
    this.lastStreakWarningSent,
    this.streakWarningCount = 0,
    required this.createdAt,
  });

  /// Convert entity to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'archetype': archetype.name,
      'reminderTime': reminderTime,
      'frequency': frequency.name,
      'specificDays': specificDays,
      'welcomeNotified': welcomeNotified,
      'lastReminderSent': lastReminderSent?.toIso8601String(),
      'enabled': enabled,
      'fcmToken': fcmToken,
      'lastStreakWarningSent': lastStreakWarningSent?.toIso8601String(),
      'streakWarningCount': streakWarningCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create entity from Firestore map with safe null handling
  factory HabitNotificationSchedule.fromMap(Map<String, dynamic> map) {
    return HabitNotificationSchedule(
      habitId: map['habitId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => UserArchetype.none,
      ),
      reminderTime: map['reminderTime'] as String? ?? '07:00',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      specificDays: map['specificDays'] != null
          ? List<int>.from(map['specificDays'] as List<dynamic>)
          : const [],
      welcomeNotified: map['welcomeNotified'] as bool? ?? false,
      lastReminderSent: map['lastReminderSent'] != null
          ? DateTime.tryParse(map['lastReminderSent'] as String)
          : null,
      enabled: map['enabled'] as bool? ?? true,
      fcmToken: map['fcmToken'] as String?,
      lastStreakWarningSent: map['lastStreakWarningSent'] != null
          ? DateTime.tryParse(map['lastStreakWarningSent'] as String)
          : null,
      streakWarningCount: map['streakWarningCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Create a copy with modified fields
  HabitNotificationSchedule copyWith({
    String? habitId,
    String? userId,
    UserArchetype? archetype,
    String? reminderTime,
    HabitFrequency? frequency,
    List<int>? specificDays,
    bool? welcomeNotified,
    DateTime? lastReminderSent,
    bool? enabled,
    String? fcmToken,
    DateTime? lastStreakWarningSent,
    int? streakWarningCount,
    DateTime? createdAt,
  }) {
    return HabitNotificationSchedule(
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      archetype: archetype ?? this.archetype,
      reminderTime: reminderTime ?? this.reminderTime,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      welcomeNotified: welcomeNotified ?? this.welcomeNotified,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      enabled: enabled ?? this.enabled,
      fcmToken: fcmToken ?? this.fcmToken,
      lastStreakWarningSent: lastStreakWarningSent ?? this.lastStreakWarningSent,
      streakWarningCount: streakWarningCount ?? this.streakWarningCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        habitId,
        userId,
        archetype,
        reminderTime,
        frequency,
        specificDays,
        welcomeNotified,
        lastReminderSent,
        enabled,
        fcmToken,
        lastStreakWarningSent,
        streakWarningCount,
        createdAt,
      ];
}
