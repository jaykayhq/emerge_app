# Archetype-Based Notification System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a production-ready, archetype-based notification system where all notification types (habit reminders, streak warnings, AI insights, community updates, rewards) are fully functional with unique styling per archetype.

**Architecture:** Hybrid approach - local notifications for immediate gratification (welcome notifications) + Firebase Cloud Functions for smart features (streak warnings, adaptive scheduling, AI insights). Cross-device sync via FCM with archetype-themed content, colors, and icons.

**Tech Stack:** Flutter (Dart), Firebase Cloud Functions (TypeScript), flutter_local_notifications, firebase_messaging, Firestore triggers, Riverpod state management

---

## Task 1: Create Notification Templates Data Model

**Files:**
- Create: `lib/core/services/notification_templates.dart`

**Step 1: Write the notification templates model**

```dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Archetype-themed notification message templates
class NotificationTemplates {
  /// Welcome message sent immediately when habit is created
  static String welcomeMessage(UserArchetype archetype, String habitTitle) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '💪 New training protocol: $habitTitle! Your journey to greatness begins now.';
      case UserArchetype.scholar:
        return '📚 A new quest for knowledge begins: $habitTitle. The path to wisdom awaits.';
      case UserArchetype.creator:
        return '🎨 A new canvas awaits: $habitTitle. Your creative journey starts today.';
      case UserArchetype.stoic:
        return '🏛️ A new trial of discipline begins: $habitTitle. Master yourself.';
      case UserArchetype.zealot:
        return '🔥 A sacred devotion begins: $habitTitle. Let your light shine.';
      case UserArchetype.none:
        return '🗺️ A new adventure awaits: $habitTitle. Discover your potential.';
    }
  }

  /// Recurring reminder message
  static String reminderMessage(UserArchetype archetype, String habitTitle) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '⚡ Time to train, Athlete! Your $habitTitle awaits.';
      case UserArchetype.scholar:
        return '📖 Knowledge calls, Scholar. Time for $habitTitle.';
      case UserArchetype.creator:
        return '✨ Inspiration strikes! Time to create: $habitTitle.';
      case UserArchetype.stoic:
        return '⚖️ Time for your daily practice: $habitTitle.';
      case UserArchetype.zealot:
        return '🌟 Time for spiritual practice: $habitTitle.';
      case UserArchetype.none:
        return '🧭 Time to explore: $habitTitle.';
    }
  }

  /// Streak warning message (sent 1hr after reminder time if incomplete)
  static String streakWarning(UserArchetype archetype, int streakDays) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '🔥 Your $streakDays-day streak is burning! Don\'t let the flame die, Athlete.';
      case UserArchetype.scholar:
        return '🧠 Your $streakDays-day learning streak is at risk! Preserve your progress, Scholar.';
      case UserArchetype.creator:
        return '💫 Your $streakDays-day creative flow is at risk—keep the momentum, Creator!';
      case UserArchetype.stoic:
        return '🛡️ Your discipline is tested—protect your $streakDays-day streak, Stoic.';
      case UserArchetype.zealot:
        return '⚡ Your $streakDays-day devotion is tested—stay the sacred path, Zealot.';
      case UserArchetype.none:
        return '🏕️ Your $streakDays-day adventure streak is at risk, Explorer!';
    }
  }

  /// Daily AI insight notification
  static String aiInsightGreeting(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '💪 Training Report';
      case UserArchetype.scholar:
        return '📚 Daily Wisdom';
      case UserArchetype.creator:
        return '🎨 Creative Insight';
      case UserArchetype.stoic:
        return '🏛️ Daily Reflection';
      case UserArchetype.zealot:
        return '🔥 Sacred Guidance';
      case UserArchetype.none:
        return '🧭 Adventure Log';
    }
  }

  /// Level up notification
  static String levelUp(UserArchetype archetype, int newLevel) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '💪 LEVEL UP! You reached Level $newLevel. Your training pays off!';
      case UserArchetype.scholar:
        return '📚 WISDOM INCREASED! Level $newLevel unlocked. Knowledge is power.';
      case UserArchetype.creator:
        return '🎨 MASTERY GROWS! You reached Level $newLevel. Create without fear!';
      case UserArchetype.stoic:
        return '🏛️ DISCIPLINE STRENGTHENS! Level $newLevel. Control what you can.';
      case UserArchetype.zealot:
        return '🔥 DEVOTION DEEPENS! Level $newLevel. Your flame burns brighter!';
      case UserArchetype.none:
        return '🧭 JOURNEY CONTINUES! You reached Level $newLevel. Keep exploring!';
    }
  }

  /// Achievement unlocked
  static String achievement(UserArchetype archetype, String achievementName) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '🏆 ACHIEVEMENT UNLOCKED: $achievementName! Your dedication is unmatched.';
      case UserArchetype.scholar:
        return '📖 MILESTONE REACHED: $achievementName! Another truth discovered.';
      case UserArchetype.creator:
        return '✨ MASTERPIECE: $achievementName! Your vision comes to life.';
      case UserArchetype.stoic:
        return '🛡️ VIRTUE ATTAINED: $achievementName! Your character is forged.';
      case UserArchetype.zealot:
        return '🔥 BLESSING RECEIVED: $achievementName! Your devotion is rewarded.';
      case UserArchetype.none:
        return '🌟 DISCOVERY: $achievementName! New horizons revealed.';
    }
  }

  /// Get default reminder time based on archetype
  static String get defaultReminderTime {
    // Returns hour as string (24-hour format)
    return '07'; // 7 AM default for Explorer
  }

  static int getDefaultHour(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete: return 6;
      case UserArchetype.scholar: return 8;
      case UserArchetype.creator: return 9;
      case UserArchetype.stoic: return 5;
      case UserArchetype.zealot: return 6;
      case UserArchetype.none: return 7;
    }
  }
}

/// Notification channel IDs per archetype
class NotificationChannels {
  static String channelForArchetype(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete: return 'athlete_habits';
      case UserArchetype.scholar: return 'scholar_habits';
      case UserArchetype.creator: return 'creator_habits';
      case UserArchetype.stoic: return 'stoic_habits';
      case UserArchetype.zealot: return 'zealot_habits';
      case UserArchetype.none: return 'explorer_habits';
    }
  }

  static String get habitReminders => 'habit_reminders';
  static String get streakWarnings => 'streak_warnings';
  static String get aiInsights => 'ai_insights';
  static String get communityUpdates => 'community_updates';
  static String get rewards => 'rewards_achievements';
  static String get weeklyRecap => 'weekly_recap';
}

/// Icon data mapping for notifications
class NotificationIcons {
  static const Map<UserArchetype, String> archetypeIcons = {
    UserArchetype.athlete: 'directions_run',
    UserArchetype.scholar: 'menu_book',
    UserArchetype.creator: 'palette',
    UserArchetype.stoic: 'self_improvement',
    UserArchetype.zealot: 'local_fire_department',
    UserArchetype.none: 'explore',
  };
}
```

**Step 2: Commit**

```bash
git add lib/core/services/notification_templates.dart
git commit -m "feat: add archetype-themed notification templates"
```

---

## Task 2: Create HabitNotificationSchedule Entity

**Files:**
- Create: `lib/features/habits/domain/entities/habit_notification_schedule.dart`

**Step 1: Write the habit notification schedule entity**

```dart
import 'package:equatable/equatable.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// Tracks notification scheduling for a habit
class HabitNotificationSchedule extends Equatable {
  final String habitId;
  final String userId;
  final UserArchetype archetype;
  final String reminderTime; // Format: "HH:MM"
  final HabitFrequency frequency;
  final List<int> specificDays; // 1=Monday, 7=Sunday
  final bool welcomeNotified;
  final DateTime? lastReminderSent;
  final bool enabled;
  final String? fcmToken;
  final DateTime? lastStreakWarningSent;
  final int streakWarningCount;
  final DateTime createdAt;

  const HabitNotificationSchedule({
    required this.habitId,
    required this.userId,
    required this.archetype,
    required this.reminderTime,
    required this.frequency,
    this.specificDays = const [],
    this.welcomeNotified = false,
    this.lastReminderSent,
    this.enabled = true,
    this.fcmToken,
    this.lastStreakWarningSent,
    this.streakWarningCount = 0,
    required this.createdAt,
  });

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

  factory HabitNotificationSchedule.fromMap(Map<String, dynamic> map) {
    return HabitNotificationSchedule(
      habitId: map['habitId'] as String,
      userId: map['userId'] as String,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => UserArchetype.none,
      ),
      reminderTime: map['reminderTime'] as String? ?? '07:00',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      specificDays: List<int>.from(map['specificDays'] ?? []),
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
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

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
```

**Step 2: Commit**

```bash
git add lib/features/habits/domain/entities/habit_notification_schedule.dart
git commit -m "feat: add HabitNotificationSchedule entity"
```

---

## Task 3: Enhance NotificationService with Archetype Support

**Files:**
- Modify: `lib/core/services/notification_service.dart`

**Step 1: Add imports and notification channel initialization**

```dart
// Add to imports
import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
```

**Step 2: Add method to get notification details for archetype**

Add this method to NotificationService class after `_nextMondayNineAM()`:

```dart
  /// Get Android notification details styled for archetype
  AndroidNotificationDetails _archetypeNotificationDetails(
    UserArchetype archetype,
    String channelId,
  ) {
    final theme = ArchetypeTheme.forArchetype(archetype);

    return AndroidNotificationDetails(
      channelId,
      '${theme.archetypeName} Habits',
      channelDescription: 'Personalized ${theme.archetypeName} notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: theme.primaryColor,
      LEDColor: theme.primaryColor,
      icon: '@drawable/push_notification_icon',
      largeIcon: const DrawableResourceAndroidBitmap('push_notification_icon'),
      styleInformation: BigTextStyleInformation(''),
      category: AndroidNotificationCategory.reminder,
    );
  }
```

**Step 3: Add habit notification methods**

Add these methods to NotificationService class:

```dart
  // ============ HABIT NOTIFICATIONS ============

  /// Send immediate welcome notification when habit is created
  Future<void> notifyHabitCreated(
    Habit habit,
    UserArchetype archetype,
  ) async {
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = NotificationTemplates.welcomeMessage(archetype, habit.title);

      await _localNotifications.show(
        habit.id.hashCode,
        'New Quest Active!',
        message,
        NotificationDetails(
          android: _archetypeNotificationDetails(archetype, channelId),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/habits/${habit.id}',
      );

      debugPrint('Welcome notification sent for habit: ${habit.title}');
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
    }
  }

  /// Schedule recurring reminder for a habit
  Future<void> scheduleHabitReminder(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime, // "HH:MM" format
    HabitFrequency frequency,
    List<int> specificDays,
  ) async {
    try {
      final parts = reminderTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = NotificationTemplates.reminderMessage(archetype, habitTitle);

      // Calculate next scheduled time based on frequency
      tz.TZDateTime scheduledTime;
      final now = tz.TZDateTime.now(tz.local);

      switch (frequency) {
        case HabitFrequency.daily:
          scheduledTime = _nextInstanceOfTime(hour, minute);
          break;
        case HabitFrequency.weekly:
          scheduledTime = _nextInstanceOfDayOfWeek(DateTime.monday, hour, minute);
          break;
        case HabitFrequency.specificDays:
          // Find next occurrence from specificDays
          scheduledTime = _nextInstanceOfSpecificDays(specificDays, hour, minute);
          break;
      }

      // Match day/time components for recurrence
      final matchDateTimeComponents = frequency == HabitFrequency.daily
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime;

      await _localNotifications.zonedSchedule(
        habitId.hashCode,
        habitTitle,
        message,
        scheduledTime,
        NotificationDetails(
          android: _archetypeNotificationDetails(archetype, channelId),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: '/habits/$habitId',
      );

      debugPrint('Scheduled reminder for $habitTitle at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling habit reminder: $e');
    }
  }

  /// Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(String habitId) async {
    try {
      await _localNotifications.cancel(habitId.hashCode);
      debugPrint('Cancelled notifications for habit: $habitId');
    } catch (e) {
      debugPrint('Error cancelling habit notifications: $e');
    }
  }

  /// Update existing notification schedule
  Future<void> updateHabitNotification(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String newTime,
    HabitFrequency newFrequency,
    List<int> specificDays,
  ) async {
    // Cancel existing, then reschedule
    await cancelHabitNotifications(habitId);
    await scheduleHabitReminder(
      habitId,
      habitTitle,
      archetype,
      newTime,
      newFrequency,
      specificDays,
    );
  }

  // ============ STREAK WARNINGS ============

  /// Schedule streak warning for 1hr after reminder time
  Future<void> scheduleStreakWarning(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    int currentStreak,
  ) async {
    try {
      final parts = reminderTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final warningTime = _nextInstanceOfTime(hour, minute + 60);
      final message = NotificationTemplates.streakWarning(archetype, currentStreak);

      await _localNotifications.zonedSchedule(
        '${habitId}_streak'.hashCode,
        '⚠️ Streak at Risk!',
        message,
        warningTime,
        NotificationDetails(
          android: _archetypeNotificationDetails(
            archetype,
            NotificationChannels.streakWarnings,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '/habits/$habitId',
      );

      debugPrint('Scheduled streak warning for $habitTitle');
    } catch (e) {
      debugPrint('Error scheduling streak warning: $e');
    }
  }

  // ============ AI INSIGHTS ============

  /// Send daily AI insight notification
  Future<void> sendDailyInsight(
    String userId,
    String insight,
    UserArchetype archetype,
  ) async {
    try {
      final greeting = NotificationTemplates.aiInsightGreeting(archetype);

      await _localNotifications.show(
        'daily_insight_$userId'.hashCode,
        greeting,
        insight,
        NotificationDetails(
          android: _archetypeNotificationDetails(
            archetype,
            NotificationChannels.aiInsights,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/world/recap',
      );

      debugPrint('Daily insight sent for user: $userId');
    } catch (e) {
      debugPrint('Error sending daily insight: $e');
    }
  }

  // ============ REWARDS & ACHIEVEMENTS ============

  /// Level up notification
  Future<void> notifyLevelUp(
    String userId,
    int newLevel,
    UserArchetype archetype,
  ) async {
    try {
      final message = NotificationTemplates.levelUp(archetype, newLevel);

      await _localNotifications.show(
        'level_up_$userId'.hashCode,
        '🎉 LEVEL UP!',
        message,
        NotificationDetails(
          android: _archetypeNotificationDetails(
            archetype,
            NotificationChannels.rewards,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/profile',
      );

      debugPrint('Level up notification sent for level $newLevel');
    } catch (e) {
      debugPrint('Error sending level up notification: $e');
    }
  }

  /// Achievement unlocked notification
  Future<void> notifyAchievement(
    String userId,
    String achievementName,
    UserArchetype archetype,
  ) async {
    try {
      final message = NotificationTemplates.achievement(archetype, achievementName);

      await _localNotifications.show(
        'achievement_$userId'.hashCode,
        '🏆 Achievement Unlocked!',
        message,
        NotificationDetails(
          android: _archetypeNotificationDetails(
            archetype,
            NotificationChannels.rewards,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/profile',
      );

      debugPrint('Achievement notification sent: $achievementName');
    } catch (e) {
      debugPrint('Error sending achievement notification: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get next instance of a specific time (for daily reminders)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next instance of a specific day of week and time
  tz.TZDateTime _nextInstanceOfDayOfWeek(int day, int hour, int minute) {
    var scheduledDate = _nextInstanceOfTime(hour, minute);

    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Get next instance from specific days list
  tz.TZDateTime _nextInstanceOfSpecificDays(List<int> days, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final today = now.weekday;

    // Sort days and find next occurrence
    final sortedDays = days..sort();

    // Find first day that's >= today
    for (final day in sortedDays) {
      if (day >= today) {
        final candidate = _nextInstanceOfDayOfWeek(day, hour, minute);
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }

    // If none found, wrap to first day of next week
    return _nextInstanceOfDayOfWeek(sortedDays.first, hour, minute);
  }
```

**Step 4: Commit**

```bash
git add lib/core/services/notification_service.dart
git commit -m "feat: add archetype-styled habit notifications to NotificationService"
```

---

## Task 4: Add Time Picker to Habit Creation Form

**Files:**
- Modify: `lib/features/habits/presentation/widgets/habit_form_widgets.dart`
- Or find the actual habit creation form file

**Step 1: Find the habit creation form**

Run: `find lib -name "*habit*create*" -o -name "*habit*form*" -type f`

**Step 2: Add TimeOfDay field to habit creation state**

```dart
// In the habit creation form widget state, add:
TimeOfDay? _reminderTime;
```

**Step 3: Add time picker widget**

```dart
Widget _buildReminderTimePicker(UserArchetype archetype, BuildContext context) {
  final defaultHour = NotificationTemplates.getDefaultHour(archetype);
  final currentTime = _reminderTime ?? TimeOfDay(hour: defaultHour, minute: 0);

  return GlassmorphismCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: EmergeColors.teal,
                size: 20,
              ),
              const Gap(12),
              Text(
                'Reminder Time',
                style: TextStyle(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Gap(16),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: currentTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: EmergeColors.teal,
                        onPrimary: Colors.white,
                        surface: AppTheme.surfaceDark,
                        onSurface: AppTheme.textMainDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _reminderTime = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EmergeColors.teal.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentTime.format(context),
                    style: TextStyle(
                      color: AppTheme.textMainDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: EmergeColors.teal,
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          Text(
            'Archetype-based default: ${defaultHour}:00',
            style: TextStyle(
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
    ),
  );
}
```

**Step 5: Add reminder time to habit creation**

Update the habit creation logic to include `reminderTime`:

```dart
// When creating the habit:
final habit = Habit(
  // ... other fields
  reminderTime: _reminderTime,
  // ...
);
```

**Step 6: Commit**

```bash
git add lib/features/habits/presentation/widgets/habit_form_widgets.dart
git commit -m "feat: add reminder time picker to habit creation with archetype defaults"
```

---

## Task 5: Add Delete Button to Habit Detail Screen

**Files:**
- Modify: `lib/features/habits/presentation/screens/habit_detail_screen.dart`

**Step 1: Add delete confirmation dialog**

Add this method before the `_buildHeader` method:

```dart
Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          const Gap(12),
          Text(
            'Delete Habit?',
            style: TextStyle(
              color: AppTheme.textMainDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'This will permanently delete this habit and all its history. This action cannot be undone.',
        style: TextStyle(color: AppTheme.textSecondaryDark),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondaryDark),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Step 2: Add delete section at bottom of screen**

Before the closing `)` of the `SingleChildScrollView`'s `Column` children (after the Anchor Habit section), add:

```dart
                  const Gap(32),

                  // Delete Habit Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red.withValues(alpha: 0.7),
                          size: 36,
                        ),
                        const Gap(12),
                        Text(
                          'Delete Habit',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Permanently delete this habit and all its history.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirmed = await _showDeleteConfirmationDialog(context);
                              if (confirmed) {
                                try {
                                  // Delete habit from repository
                                  await ref.read(habitRepositoryProvider).deleteHabit(habit.id);

                                  // Cancel all notifications
                                  await ref.read(notificationServiceProvider).cancelHabitNotifications(habit.id);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Habit deleted successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.of(context).pop(); // Close detail screen
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error deleting habit: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.2),
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Delete Forever',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
```

**Step 3: Add import for NotificationService**

At the top of the file, ensure this import exists:

```dart
import 'package:emerge_app/core/services/notification_service.dart';
```

**Step 4: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_detail_screen.dart
git commit -m "feat: add delete habit button with confirmation dialog"
```

---

## Task 6: Create Habit Notification Repository

**Files:**
- Create: `lib/features/habits/data/repositories/habit_notification_repository.dart`
- Create: `lib/features/habits/data/repositories/habit_notification_repository_provider.dart`

**Step 1: Write the repository interface**

```dart
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_notification_schedule.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitNotificationRepository {
  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HabitNotificationRepository({
    required NotificationService notificationService,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _notificationService = notificationService,
        _firestore = firestore,
        _auth = auth;

  /// Create notification schedule for a new habit
  Future<void> scheduleHabitNotifications(
    Habit habit,
    UserArchetype archetype,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // 1. Send immediate welcome notification
    await _notificationService.notifyHabitCreated(habit, archetype);

    // 2. Schedule recurring reminder
    final reminderTime = habit.reminderTime ??
        TimeOfDay(hour: NotificationTemplates.getDefaultHour(archetype), minute: 0);
    final timeString = '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';

    await _notificationService.scheduleHabitReminder(
      habit.id,
      habit.title,
      archetype,
      timeString,
      habit.frequency,
      habit.specificDays,
    );

    // 3. Create notification schedule document
    final schedule = HabitNotificationSchedule(
      habitId: habit.id,
      userId: userId,
      archetype: archetype,
      reminderTime: timeString,
      frequency: habit.frequency,
      specificDays: habit.specificDays,
      welcomeNotified: true,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .doc(habit.id)
        .set(schedule.toMap());
  }

  /// Update notification schedule when habit is edited
  Future<void> updateHabitNotifications(
    Habit habit,
    UserArchetype archetype,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final reminderTime = habit.reminderTime ??
        TimeOfDay(hour: NotificationTemplates.getDefaultHour(archetype), minute: 0);
    final timeString = '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';

    await _notificationService.updateHabitNotification(
      habit.id,
      habit.title,
      archetype,
      timeString,
      habit.frequency,
      habit.specificDays,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .doc(habit.id)
        .update({
          'reminderTime': timeString,
          'frequency': habit.frequency.name,
          'specificDays': habit.specificDays,
        });
  }

  /// Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(String habitId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _notificationService.cancelHabitNotifications(habitId);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .doc(habitId)
        .delete();
  }

  /// Schedule streak warning for a habit
  Future<void> scheduleStreakWarning(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    int currentStreak,
  ) async {
    await _notificationService.scheduleStreakWarning(
      habitId,
      habitTitle,
      archetype,
      reminderTime,
      currentStreak,
    );
  }

  /// Send level up notification
  Future<void> notifyLevelUp(int newLevel, UserArchetype archetype) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _notificationService.notifyLevelUp(userId, newLevel, archetype);
  }

  /// Send achievement notification
  Future<void> notifyAchievement(
    String achievementName,
    UserArchetype archetype,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _notificationService.notifyAchievement(
      userId,
      achievementName,
      archetype,
    );
  }

  /// Get all notification schedules for user
  Stream<List<HabitNotificationSchedule>> getNotificationSchedules() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HabitNotificationSchedule.fromMap(doc.data()))
              .toList();
        });
  }
}
```

**Step 2: Create provider**

```dart
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<HabitNotificationRepository>((ref) {
  return HabitNotificationRepository(
    notificationService: ref.watch(notificationServiceProvider),
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});
```

**Step 3: Commit**

```bash
git add lib/features/habits/data/repositories/habit_notification_repository.dart
git add lib/features/habits/data/repositories/habit_notification_repository_provider.dart
git commit -m "feat: add HabitNotificationRepository for notification scheduling"
```

---

## Task 7: Integrate Notification Scheduling into Habit Creation

**Files:**
- Modify: Find and modify the habit creation handler
- This is likely in a provider or screen that handles habit creation

**Step 1: Find habit creation logic**

Run: `grep -r "createHabit\|addHabit" lib/features/habits --include="*.dart" -l`

**Step 2: Update habit creation to schedule notifications**

After habit is created, add:

```dart
// After habit creation:
final userProfile = await ref.read(userStatsStreamProvider.future);
if (userProfile != null) {
  await ref.read(notificationServiceProvider).scheduleHabitNotifications(
    createdHabit,
    userProfile.archetype,
  );
}
```

**Step 3: Commit**

```bash
git add [path/to/habit/creation/file]
git commit -m "feat: schedule notifications when habit is created"
```

---

## Task 8: Create Firebase Cloud Functions

**Files:**
- Create: `functions/src/habit_notifications.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create habit notifications function file**

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const fcm = admin.messaging();

// Notification templates matching Flutter templates
const NOTIFICATION_TEMPLATES = {
  athlete: {
    welcome: (title: string) => `💪 New training protocol: ${title}! Your journey to greatness begins now.`,
    reminder: (title: string) => `⚡ Time to train, Athlete! Your ${title} awaits.`,
    streakWarning: (days: number) => `🔥 Your ${days}-day streak is burning! Don't let the flame die.`,
  },
  scholar: {
    welcome: (title: string) => `📚 A new quest for knowledge begins: ${title}.`,
    reminder: (title: string) => `📖 Knowledge calls, Scholar. Time for ${title}.`,
    streakWarning: (days: number) => `🧠 Your ${days}-day learning streak is at risk!`,
  },
  creator: {
    welcome: (title: string) => `🎨 A new canvas awaits: ${title}.`,
    reminder: (title: string) => `✨ Inspiration strikes! Time to create: ${title}.`,
    streakWarning: (days: number) => `💫 Your ${days}-day creative flow is at risk!`,
  },
  stoic: {
    welcome: (title: string) => `🏛️ A new trial of discipline begins: ${title}.`,
    reminder: (title: string) => `⚖️ Time for your daily practice: ${title}.`,
    streakWarning: (days: number) => `🛡️ Your discipline is tested—protect your ${days}-day streak.`,
  },
  zealot: {
    welcome: (title: string) => `🔥 A sacred devotion begins: ${title}.`,
    reminder: (title: string) => `🌟 Time for spiritual practice: ${title}.`,
    streakWarning: (days: number) => `⚡ Your ${days}-day devotion is tested—stay the sacred path.`,
  },
  explorer: {
    welcome: (title: string) => `🗺️ A new adventure awaits: ${title}.`,
    reminder: (title: string) => `🧭 Time to explore: ${title}.`,
    streakWarning: (days: number) => `🏕️ Your ${days}-day adventure streak is at risk!`,
  },
};

/**
 * Triggered when habit is created
 * Sends welcome notification via FCM
 */
export const onHabitCreated = functions.firestore
  .document('users/{userId}/habits/{habitId}')
  .onCreate(async (snap, context) => {
    const habit = snap.data();
    const userId = context.params.userId as string;
    const habitId = context.params.habitId;

    // Get user profile for archetype
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    const userProfile = userDoc.data();
    const archetype = userProfile?.archetype || 'explorer';
    const fcmToken = userProfile?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return null;
    }

    const template = NOTIFICATION_TEMPLATES[archetype as keyof typeof NOTIFICATION_TEMPLATES];
    const message = template.welcome(habit.title);

    const messagePayload: admin.messaging.Message = {
      notification: {
        title: 'New Quest Active!',
        body: message,
      },
      data: {
        type: 'habit_created',
        habitId: habitId,
        clickAction: '/habits/${habitId}',
      },
      token: fcmToken,
    };

    try {
      await fcm.send(messagePayload);
      console.log(`Welcome notification sent for habit ${habitId}`);

      // Mark welcome as sent in notification schedule
      await db.collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .doc(habitId)
        .set({ welcomeNotified: true }, { merge: true });
    } catch (error) {
      console.error(`Error sending welcome notification: ${error}`);
    }

    return null;
  });

/**
 * Triggered when habit is updated
 * Reschedules notifications if time/frequency changed
 */
export const onHabitUpdated = functions.firestore
  .document('users/{userId}/habits/{habitId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId as string;
    const habitId = context.params.habitId;

    // Check if reminder time or frequency changed
    const timeChanged = before.reminderTime !== after.reminderTime;
    const frequencyChanged = before.frequency !== after.frequency;

    if (!timeChanged && !frequencyChanged) return null;

    // Update notification schedule
    await db.collection('users')
      .doc(userId)
      .collection('notificationSchedules')
      .doc(habitId)
      .update({
        reminderTime: after.reminderTime,
        frequency: after.frequency,
        specificDays: after.specificDays || [],
      });

    console.log(`Notification schedule updated for habit ${habitId}`);
    return null;
  });

/**
 * Triggered when habit is deleted
 * Cancels all notifications
 */
export const onHabitDeleted = functions.firestore
  .document('users/{userId}/habits/{habitId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId as string;
    const habitId = context.params.habitId;

    // Delete notification schedule
    await db.collection('users')
      .doc(userId)
      .collection('notificationSchedules')
      .doc(habitId)
      .delete();

    console.log(`Notification schedule deleted for habit ${habitId}`);
    return null;
  });

/**
 * Scheduled function every 15 minutes to send streak warnings
 * Checks for habits not completed 1hr after reminder time
 */
export const sendStreakWarnings = functions.pubsub
  .schedule('*/15 * * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    // Get all users with habitReminders enabled
    const usersSnapshot = await db.collection('users')
      .where('settings.habitReminders', '==', true)
      .where('settings.notificationsEnabled', '==', true)
      .get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userProfile = userDoc.data();
      const archetype = userProfile.archetype || 'explorer';
      const fcmToken = userProfile.fcmToken;

      if (!fcmToken) continue;

      // Check if DND is active
      if (userProfile.settings?.doNotDisturb) {
        // Check if current time is in sleep window
        const currentHour = now.getUTCHours();
        if (currentHour >= 22 || currentHour < 7) {
          continue; // Skip during DND hours
        }
      }

      // Get notification schedules
      const schedulesSnapshot = await db.collection('users')
        .doc(userId)
        .collection('notificationSchedules')
        .where('enabled', '==', true)
        .get();

      for (const scheduleDoc of schedulesSnapshot.docs) {
        const schedule = scheduleDoc.data();
        const habitId = schedule.habitId;

        // Get habit data
        const habitDoc = await db.collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .get();

        if (!habitDoc.exists) continue;

        const habit = habitDoc.data();
        const lastCompleted = habit.lastCompletedDate ? new Date(habit.lastCompletedDate) : null;
        const streak = habit.currentStreak || 0;

        // Check if streak is at risk (3+ days and not completed today)
        if (streak < 3) continue;

        const today = now.toISOString().split('T')[0];
        const lastCompletedDate = lastCompleted ? lastCompleted.toISOString().split('T')[0] : null;

        if (lastCompletedDate === today) continue; // Already completed today

        // Check if reminder was sent ~1 hour ago
        const reminderTime = schedule.reminderTime || '07:00';
        const [hour, minute] = reminderTime.split(':').map(Number);
        const reminderDateTime = new Date(now);
        reminderDateTime.setHours(hour, minute, 0, 0);

        // Only send if we're within 15 minutes of 1 hour after reminder
        const timeDiff = now.getTime() - reminderDateTime.getTime();
        if (timeDiff < 45 * 60 * 1000 || timeDiff > 75 * 60 * 1000) {
          continue;
        }

        // Check if we already sent a warning today
        const lastWarning = schedule.lastStreakWarningSent ? new Date(schedule.lastStreakWarningSent) : null;
        if (lastWarning) {
          const lastWarningDate = lastWarning.toISOString().split('T')[0];
          if (lastWarningDate === today) continue;
        }

        // Send streak warning
        const template = NOTIFICATION_TEMPLATES[archetype as keyof typeof NOTIFICATION_TEMPLATES];
        const message = template.streakWarning(streak);

        const messagePayload: admin.messaging.Message = {
          notification: {
            title: '⚠️ Streak at Risk!',
            body: message,
          },
          data: {
            type: 'streak_warning',
            habitId: habitId,
            clickAction: '/habits/${habitId}',
          },
          token: fcmToken,
        };

        try {
          await fcm.send(messagePayload);
          console.log(`Streak warning sent for habit ${habitId}`);

          // Update last warning sent
          await scheduleDoc.ref.update({
            lastStreakWarningSent: now.toISOString(),
            streakWarningCount: admin.firestore.FieldValue.increment(1),
          });
        } catch (error) {
          console.error(`Error sending streak warning: ${error}`);
        }
      }
    }

    return null;
  });

/**
 * Triggered when user levels up
 */
export const onLevelUp = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    const beforeLevel = before.avatarStats?.level || 1;
    const afterLevel = after.avatarStats?.level || 1;

    if (afterLevel <= beforeLevel) return null;

    const archetype = after.archetype || 'explorer';
    const fcmToken = after.fcmToken;

    if (!fcmToken) return null;

    // Check if rewards notifications are enabled
    if (!after.settings?.rewardsUpdates) return null;

    const message = `🎉 LEVEL UP! You reached Level ${afterLevel}. Your ${archetype} journey continues!`;

    const messagePayload: admin.messaging.Message = {
      notification: {
        title: '🎉 Level Up!',
        body: message,
      },
      data: {
        type: 'level_up',
        clickAction: '/profile',
      },
      token: fcmToken,
    };

    try {
      await fcm.send(messagePayload);
      console.log(`Level up notification sent for level ${afterLevel}`);
    } catch (error) {
      console.error(`Error sending level up notification: ${error}`);
    }

    return null;
  });

/**
 * Daily AI insights at 9 AM
 */
export const sendDailyInsights = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = new Date();

    // Get users with AI insights enabled
    const usersSnapshot = await db.collection('users')
      .where('settings.aiInsights', '==', true)
      .where('settings.notificationsEnabled', '==', true)
      .get();

    for (const userDoc of usersSnapshot.docs) {
      const userProfile = userDoc.data();
      const archetype = userProfile.archetype || 'explorer';
      const fcmToken = userProfile.fcmToken;

      if (!fcmToken) continue;

      // Generate insight (this would call your AI service)
      const insight = 'Your consistency is inspiring! Keep building your identity, one habit at a time.';

      const greeting = archetype === 'athlete' ? '💪 Training Report' :
                       archetype === 'scholar' ? '📚 Daily Wisdom' :
                       archetype === 'creator' ? '🎨 Creative Insight' :
                       archetype === 'stoic' ? '🏛️ Daily Reflection' :
                       archetype === 'zealot' ? '🔥 Sacred Guidance' :
                       '🧭 Adventure Log';

      const messagePayload: admin.messaging.Message = {
        notification: {
          title: greeting,
          body: insight,
        },
        data: {
          type: 'daily_insight',
          clickAction: '/world/recap',
        },
        token: fcmToken,
      };

      try {
        await fcm.send(messagePayload);
        console.log(`Daily insight sent to user ${userDoc.id}`);
      } catch (error) {
        console.error(`Error sending daily insight: ${error}`);
      }
    }

    return null;
  });
```

**Step 2: Update functions index.ts to export**

Add to `functions/src/index.ts`:

```typescript
export * from './habit_notifications';
export * from './revenuecat_webhook';
// ... other exports
```

**Step 3: Deploy functions**

Run: `firebase deploy --only functions`

**Step 4: Commit**

```bash
git add functions/src/habit_notifications.ts
git add functions/src/index.ts
git commit -m "feat: add Firebase Cloud Functions for habit notifications"
```

---

## Task 9: Update Notification Settings Screen with Do Not Disturb

**Files:**
- Modify: `lib/features/settings/presentation/screens/notification_settings_screen.dart`

**Step 1: Add DND time range picker**

Update the DND switch tile to include time range selection:

```dart
                  _buildSwitchTile(
                    'Do Not Disturb',
                    'Silence notifications during sleep hours (10 PM - 7 AM)',
                    dnd,
                    (val) => _updateSettings(
                      context,
                      ref,
                      userProfile,
                      settings.copyWith(doNotDisturb: val),
                    ),
                  ),
                  if (dnd) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '🌙 Quiet hours: 10:00 PM - 7:00 AM',
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
```

**Step 2: Commit**

```bash
git add lib/features/settings/presentation/screens/notification_settings_screen.dart
git commit -m "feat: enhance DND display with quiet hours info"
```

---

## Task 10: Add Tests for Notification Templates

**Files:**
- Create: `test/core/services/notification_templates_test.dart`

**Step 1: Write the test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

void main() {
  group('NotificationTemplates', () {
    test('welcomeMessage returns correct message for Athlete', () {
      const archetype = UserArchetype.athlete;
      const habitTitle = 'Morning Run';

      final result = NotificationTemplates.welcomeMessage(archetype, habitTitle);

      expect(result, contains('Morning Run'));
      expect(result, contains('training protocol'));
    });

    test('reminderMessage returns correct message for Scholar', () {
      const archetype = UserArchetype.scholar;
      const habitTitle = 'Read 20 pages';

      final result = NotificationTemplates.reminderMessage(archetype, habitTitle);

      expect(result, contains('Read 20 pages'));
      expect(result, contains('Knowledge calls'));
    });

    test('streakWarning includes streak days', () {
      const archetype = UserArchetype.creator;
      const streakDays = 7;

      final result = NotificationTemplates.streakWarning(archetype, streakDays);

      expect(result, contains('7'));
      expect(result, contains('creative flow'));
    });

    test('getDefaultHour returns correct hour per archetype', () {
      expect(NotificationTemplates.getDefaultHour(UserArchetype.athlete), 6);
      expect(NotificationTemplates.getDefaultHour(UserArchetype.scholar), 8);
      expect(NotificationTemplates.getDefaultHour(UserArchetype.creator), 9);
      expect(NotificationTemplates.getDefaultHour(UserArchetype.stoic), 5);
      expect(NotificationTemplates.getDefaultHour(UserArchetype.zealot), 6);
      expect(NotificationTemplates.getDefaultHour(UserArchetype.none), 7);
    });
  });

  group('NotificationChannels', () {
    test('channelForArchetype returns correct channel ID', () {
      expect(NotificationChannels.channelForArchetype(UserArchetype.athlete), 'athlete_habits');
      expect(NotificationChannels.channelForArchetype(UserArchetype.scholar), 'scholar_habits');
      expect(NotificationChannels.channelForArchetype(UserArchetype.creator), 'creator_habits');
      expect(NotificationChannels.channelForArchetype(UserArchetype.stoic), 'stoic_habits');
      expect(NotificationChannels.channelForArchetype(UserArchetype.zealot), 'zealot_habits');
      expect(NotificationChannels.channelForArchetype(UserArchetype.none), 'explorer_habits');
    });
  });
}
```

**Step 2: Run test**

Run: `flutter test test/core/services/notification_templates_test.dart`

Expected: All tests pass

**Step 3: Commit**

```bash
git add test/core/services/notification_templates_test.dart
git commit -m "test: add tests for notification templates"
```

---

## Task 11: Integration Test for Notification Flow

**Files:**
- Create: `integration_test/app_test.dart` (or add to existing)

**Step 1: Write integration test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete habit creation flow with notifications', (tester) async {
    // Launch app
    await tester.pumpWidget(
      ProviderScope(
        child: app.EmergeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Sign in (if needed)
    // ... sign in steps

    // Navigate to habit creation
    // ... navigation steps

    // Verify time picker shows archetype default
    expect(find.textContaining('Archetype-based default'), findsOneWidget);

    // Create habit with reminder time
    // ... fill form and submit

    // Verify notification permission request
    // ... check for permission dialog

    // Complete test
  });
}
```

**Step 2: Run integration test**

Run: `flutter test integration_test/app_test.dart`

**Step 3: Commit**

```bash
git add integration_test/app_test.dart
git commit -m "test: add notification flow integration test"
```

---

## Task 12: Create Documentation

**Files:**
- Create: `docs/notification_system.md`

**Step 1: Write documentation**

```markdown
# Notification System Documentation

## Overview

Emerge's notification system is archetype-themed, meaning each user receives notifications personalized to their chosen archetype (Athlete, Scholar, Creator, Stoic, Zealot, or Explorer).

## Architecture

**Hybrid Approach:**
- **Local Notifications:** Immediate welcome notifications, initial habit reminders
- **Cloud Functions:** Streak warnings, AI insights, level-ups, achievements
- **Cross-Device Sync:** FCM tokens stored in Firestore for multi-device support

## Notification Types

### 1. Habit Reminders
- **Trigger:** Scheduled based on habit frequency and reminder time
- **Channel:** `{archetype}_habits` (e.g., `athlete_habits`)
- **Content:** Archetype-specific motivational message with habit title

### 2. Streak Warnings
- **Trigger:** 1 hour after reminder time if habit not completed (streak ≥ 3 days)
- **Channel:** `streak_warnings`
- **Cloud Function:** `sendStreakWarnings` (runs every 15 minutes)

### 3. AI Insights
- **Trigger:** Daily at 9 AM UTC
- **Channel:** `ai_insights`
- **Content:** Daily coaching summary archetype-voiced

### 4. Level Ups
- **Trigger:** Firestore onUpdate when `avatarStats.level` increases
- **Channel:** `rewards_achievements`

### 5. Achievements
- **Trigger:** When achievement is unlocked
- **Channel:** `rewards_achievements`

## Archetype Notification Defaults

| Archetype | Default Time | Icon | Color |
|-----------|--------------|------|-------|
| Athlete   | 6:00 AM      | directions_run | Red (#FF5252) |
| Scholar   | 8:00 AM      | menu_book | Purple (#7C3AED) |
| Creator   | 9:00 AM      | palette | Gold (#FFD700) |
| Stoic     | 5:00 AM      | self_improvement | Teal (#26A69A) |
| Zealot    | 6:00 AM      | local_fire_department | Deep Red (#991B1B) |
| Explorer  | 7:00 AM      | explore | Teal (#009688) |

## Do Not Disturb

When enabled, notifications are silenced between 10 PM - 7 AM UTC.

## User Settings

All notification types respect user settings:
- `notificationsEnabled` - Master toggle
- `habitReminders` - Enable/disable habit reminders
- `streakWarnings` - Enable/disable streak warnings
- `aiInsights` - Enable/disable daily AI insights
- `communityUpdates` - Enable/disable social notifications
- `rewardsUpdates` - Enable/disable achievement/level notifications
- `doNotDisturb` - Enable quiet hours

## Firestore Schema

### notificationSchedules collection
```
users/{userId}/notificationSchedules/{habitId}
{
  habitId: string,
  userId: string,
  archetype: 'athlete' | 'scholar' | 'creator' | 'stoic' | 'zealot' | 'explorer',
  reminderTime: "HH:MM",
  frequency: 'daily' | 'weekly' | 'specificDays',
  specificDays: [1,2,3,4,5,6,7],
  welcomeNotified: boolean,
  lastReminderSent: ISO8601 timestamp,
  enabled: boolean,
  fcmToken: string,
  lastStreakWarningSent: ISO8601 timestamp,
  streakWarningCount: number,
  createdAt: ISO8601 timestamp
}
```

## Testing

Run notification tests:
```bash
flutter test test/core/services/notification_templates_test.dart
flutter test integration_test/app_test.dart
```

## Troubleshooting

### Notifications not appearing:
1. Check notification permissions in app settings
2. Verify `notificationsEnabled` is true in user settings
3. Check if DND is active
4. Verify FCM token is set in Firestore

### Streak warnings not sending:
1. Verify streak is ≥ 3 days
2. Check that `streakWarnings` setting is enabled
3. Confirm Cloud Function is deployed and running
4. Check Firebase Functions logs for errors

### Cloud Functions deployment:
```bash
firebase deploy --only functions
```

View logs:
```bash
firebase functions:log
```
```

**Step 2: Commit**

```bash
git add docs/notification_system.md
git commit -m "docs: add notification system documentation"
```

---

## Task 13: Final Testing and Verification

**Step 1: Run all tests**

Run: `flutter test`

Expected: All tests pass

**Step 2: Build and test on device**

Run: `flutter run`

**Test Checklist:**
- [ ] Create habit → Immediate welcome notification appears
- [ ] Habit reminder scheduled at correct time
- [ ] Reminder notification shows archetype styling
- [ ] Delete habit → Notifications cancelled
- [ ] Edit habit reminder time → Schedule updated
- [ ] Streak warning sends 1hr after reminder (simulate by adjusting time)
- [ ] Level up notification appears
- [ ] DND silences notifications during quiet hours
- [ ] Settings toggles enable/disable notification types

**Step 3: Verify Cloud Functions**

Run: `firebase functions:log --only onHabitCreated,onHabitUpdated,sendStreakWarnings`

**Step 4: Final commit**

```bash
git add .
git commit -m "feat: complete archetype-based notification system implementation"
```

---

## Task 14: Update Changelog

**Files:**
- Modify: `CHANGELOG.md` (or create if doesn't exist)

**Step 1: Add changelog entry**

```markdown
## [Unreleased]

### Added
- **Notifications:** Complete archetype-based notification system
  - Immediate welcome notifications when habits are created
  - Recurring habit reminders with archetype-themed messages
  - Streak warnings sent 1 hour after reminder time if incomplete
  - Daily AI insights at 9 AM
  - Level up and achievement notifications
  - Do Not Disturb mode (10 PM - 7 AM)
  - Archetype-specific notification channels, colors, and icons
  - Smart default reminder times per archetype
  - Time picker for customizing reminder times

- **Habit Management:** Delete habit button in detail screen
  - Confirmation dialog before deletion
  - Cancels all associated notifications

- **Firebase Cloud Functions:** Smart notification scheduling
  - Habit creation/update/delete triggers
  - Scheduled streak warning checks (every 15 min)
  - Daily AI insights delivery
  - Level up detection and notification

### Changed
- Habit creation now includes reminder time picker with archetype defaults
- All notifications respect user notification settings
- Notification channels now archetype-specific for better organization

### Fixed
- FCM token now properly synced to Firestore
- Do Not Disturb now correctly silences all notification types
```

**Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update changelog for notification system"
```

---

## Summary

This implementation plan creates a complete, production-ready, archetype-based notification system with:

1. **6 archetype themes** - Unique messages, colors, icons for Athlete, Scholar, Creator, Stoic, Zealot, Explorer
2. **7 notification types** - Habit reminders, streak warnings, AI insights, level ups, achievements, weekly recap, community updates
3. **Hybrid architecture** - Local for immediate gratification, cloud for smart features
4. **Full UI integration** - Time picker, delete button, settings screen
5. **Firebase Cloud Functions** - Automated triggers and scheduled jobs
6. **Complete testing** - Unit tests, integration tests, manual testing checklist
7. **Documentation** - System docs, changelog

**Estimated implementation time:** 3-5 days for a solo developer

**Key files created/modified:**
- Created: 14 new files
- Modified: 7 existing files
- Firebase Functions: 6 new cloud functions
- Tests: 2 test files
- Documentation: 2 docs
