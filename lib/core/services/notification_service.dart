import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize Timezone
    tz.initializeTimeZones();
    // Fallback to UTC since flutter_timezone plugin is causing build issues
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint('Could not set local location: $e');
    }

    // Initialize Local Notifications
    // Use a custom notification icon (white on transparent for Android notification bar)
    const androidSettings = AndroidInitializationSettings(
      '@drawable/push_notification_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Request Android 13+ notification permissions for local notifications
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      debugPrint(
        'Local notifications permission ${granted ?? false ? "granted" : "denied"}',
      );
    }

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap - navigate to recap
        // implementation would require access to a router or global navigator context
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions and initialize FCM with error handling
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted permission');
        }

        // Get token with error handling
        try {
          String? token = await _firebaseMessaging.getToken();
          if (kDebugMode) {
            print('FCM Token: $token');
          }

          // Save token to Firestore User document
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && token != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'fcmToken': token}, SetOptions(merge: true));
          }
        } catch (e) {
          // FCM not available on this device, continue without it
          debugPrint('FCM get token failed: $e');
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Got a message whilst in the foreground!');
            print('Message data: ${message.data}');
          }

          if (message.notification != null) {
            if (kDebugMode) {
              print(
                'Message also contained a notification: ${message.notification}',
              );
            }
            // Show local notification here if needed
          }
        });
      } else {
        if (kDebugMode) {
          print('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      // FCM initialization failed, but continue without notifications
      debugPrint('FCM initialization failed: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> scheduleWeeklyRecap() async {
    try {
      // Schedule for next Monday at 9:00 AM

      await _localNotifications.zonedSchedule(
        0,
        'Weekly Recap Ready',
        'Check out how your world evolved this week!',
        _nextMondayNineAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_recap',
            'Weekly Recap',
            channelDescription: 'Weekly progress updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '/world/recap',
      );
    } catch (e, stack) {
      debugPrint('Error scheduling weekly recap: $e');
      if (!kReleaseMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  tz.TZDateTime _nextMondayNineAM() {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );

    // Find next Monday
    while (scheduledDate.weekday != DateTime.monday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If today is Monday and it's past 9am, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Sends notification for new weekly challenge
  Future<void> notifyNewWeeklyChallenge(
    String challengeId,
    String challengeName,
  ) async {
    try {
      await _localNotifications.show(
        challengeId.hashCode,
        '🔥 New Weekly Challenge!',
        challengeName,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_challenges',
            'Weekly Challenges',
            channelDescription: 'New weekly challenge notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/challenges/$challengeId',
      );
      debugPrint('New weekly challenge notification sent: $challengeName');
    } catch (e) {
      debugPrint('Error sending weekly challenge notification: $e');
    }
  }

  /// Sends notification when challenge is ending soon
  Future<void> notifyChallengeEnding(String challengeId, int hoursLeft) async {
    try {
      final timeText = hoursLeft == 24
          ? '1 day'
          : hoursLeft >= 24
          ? '${hoursLeft ~/ 24} days'
          : '$hoursLeft hours';

      await _localNotifications.show(
        challengeId.hashCode,
        '⏰ Challenge Ending Soon!',
        'Only $timeText left to complete your challenge!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'challenge_reminders',
            'Challenge Reminders',
            channelDescription: 'Challenge deadline notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/challenges/$challengeId',
      );
      debugPrint('Challenge ending notification sent: $hoursLeft hours left');
    } catch (e) {
      debugPrint('Error sending challenge ending notification: $e');
    }
  }

  /// Sends notification when reward is available for redemption
  Future<void> notifyRewardAvailable(
    String challengeId,
    String rewardDescription,
  ) async {
    try {
      await _localNotifications.show(
        challengeId.hashCode,
        '🎁 Reward Available!',
        rewardDescription,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'rewards',
            'Rewards',
            channelDescription: 'Reward redemption notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/challenges/$challengeId',
      );
      debugPrint('Reward available notification sent: $rewardDescription');
    } catch (e) {
      debugPrint('Error sending reward notification: $e');
    }
  }

  // ============ ARCHETYPE-THEMED NOTIFICATIONS ============

  /// Private helper to get archetype-styled Android notification details
  AndroidNotificationDetails _archetypeNotificationDetails(
    UserArchetype archetype,
    String channelId,
  ) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final primaryColor = theme.primaryColor;

    return AndroidNotificationDetails(
      channelId,
      '${archetype.name.toUpperCase()} Habits',
      channelDescription: 'Archetype-styled habit reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: primaryColor,
      ledColor: primaryColor,
      largeIcon: const DrawableResourceAndroidBitmap(
        '@drawable/push_notification_icon',
      ),
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  /// Sends immediate welcome notification when a new habit is created
  Future<void> notifyHabitCreated(Habit habit, UserArchetype archetype) async {
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = NotificationTemplates.welcomeMessage(
        archetype,
        habit.title,
      );

      await _localNotifications.show(
        habit.id.hashCode,
        'New Habit Started',
        message,
        NotificationDetails(
          android: _archetypeNotificationDetails(archetype, channelId),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/habits/${habit.id}',
      );
      debugPrint('Habit created notification sent: ${habit.title}');
    } catch (e) {
      debugPrint('Error sending habit created notification: $e');
    }
  }

  /// Schedules recurring habit reminder with archetype theming
  Future<void> scheduleHabitReminder(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    HabitFrequency frequency,
    List<int> specificDays,
  ) async {
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = NotificationTemplates.reminderMessage(
        archetype,
        habitTitle,
      );

      // Safe parsing with validation
      int hour, minute;
      try {
        final parts = reminderTime.split(':');
        if (parts.length != 2) throw FormatException('Invalid time format');

        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          throw FormatException('Invalid time values');
        }
      } catch (e) {
        debugPrint('Invalid reminder time format "$reminderTime": $e');
        hour = NotificationTemplates.getDefaultHour(archetype);
        minute = 0;
      }

      // Calculate next scheduled time based on frequency
      switch (frequency) {
        case HabitFrequency.daily:
          final scheduledTime = _nextInstanceOfTime(hour, minute);
          await _localNotifications.zonedSchedule(
            habitId.hashCode,
            'Habit Reminder',
            message,
            scheduledTime,
            NotificationDetails(
              android: _archetypeNotificationDetails(archetype, channelId),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: '/habits/$habitId',
          );
          break;
        case HabitFrequency.weekly:
          if (specificDays.isEmpty) {
            debugPrint('Cannot schedule weekly habit: no days specified');
            return;
          }
          final weeklyTime = _nextInstanceOfDayOfWeek(
            specificDays.first,
            hour,
            minute,
          );
          await _localNotifications.zonedSchedule(
            habitId.hashCode,
            'Habit Reminder',
            message,
            weeklyTime,
            NotificationDetails(
              android: _archetypeNotificationDetails(archetype, channelId),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: '/habits/$habitId',
          );
          break;
        case HabitFrequency.specificDays:
          if (specificDays.isEmpty) {
            debugPrint(
              'Cannot schedule specific days habit: no days specified',
            );
            return;
          }
          // Schedule a separate notification for each day
          for (final day in specificDays) {
            final dayTime = _nextInstanceOfDayOfWeek(day, hour, minute);
            await _localNotifications.zonedSchedule(
              '${habitId}_$day'.hashCode,
              'Habit Reminder',
              message,
              dayTime,
              NotificationDetails(
                android: _archetypeNotificationDetails(archetype, channelId),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: '/habits/$habitId',
            );
          }
          return; // Don't execute the single schedule below
      }
      debugPrint(
        'Habit reminder scheduled: $habitTitle at $reminderTime ($hour:$minute)',
      );
    } catch (e) {
      debugPrint('Error scheduling habit reminder: $e');
    }
  }

  /// Cancels all notifications for a specific habit
  Future<void> cancelHabitNotifications(String habitId) async {
    try {
      await _localNotifications.cancel(habitId.hashCode);
      debugPrint('Cancelled notifications for habit: $habitId');
    } catch (e) {
      debugPrint('Error cancelling habit notifications: $e');
    }
  }

  /// Updates habit notification by cancelling and rescheduling
  Future<void> updateHabitNotification(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    HabitFrequency frequency,
    List<int> specificDays,
  ) async {
    try {
      // Cancel existing notification
      await cancelHabitNotifications(habitId);
      // Reschedule with new parameters
      await scheduleHabitReminder(
        habitId,
        habitTitle,
        archetype,
        reminderTime,
        frequency,
        specificDays,
      );
      debugPrint('Updated habit notification: $habitTitle');
    } catch (e) {
      debugPrint('Error updating habit notification: $e');
    }
  }

  /// Schedules streak warning notification (1hr after reminder time)
  Future<void> scheduleStreakWarning(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    int currentStreak,
  ) async {
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = NotificationTemplates.streakWarning(
        archetype,
        currentStreak,
      );

      // Safe parsing with validation
      int hour, minute;
      try {
        final parts = reminderTime.split(':');
        if (parts.length != 2) throw FormatException('Invalid time format');

        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          throw FormatException('Invalid time values');
        }
      } catch (e) {
        debugPrint('Invalid reminder time format "$reminderTime": $e');
        hour = NotificationTemplates.getDefaultHour(archetype);
        minute = 0;
      }

      // Schedule 1 hour after reminder time
      final scheduledTime = _nextInstanceOfTime(
        hour,
        minute,
      ).add(const Duration(hours: 1));

      await _localNotifications.zonedSchedule(
        '${habitId}_streak'.hashCode,
        '⚠️ Streak at Risk!',
        message,
        scheduledTime,
        NotificationDetails(
          android: _archetypeNotificationDetails(archetype, channelId),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/habits/$habitId',
      );
      debugPrint('Streak warning scheduled for: $habitTitle');
    } catch (e) {
      debugPrint('Error scheduling streak warning: $e');
    }
  }

  /// Sends daily AI insight notification
  Future<void> sendDailyInsight(
    String userId,
    String insight,
    UserArchetype archetype,
  ) async {
    try {
      final greeting = NotificationTemplates.aiInsightGreeting(archetype);

      await _localNotifications.show(
        'insight_$userId'.hashCode,
        'Daily Insight',
        '$greeting\n\n$insight',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.aiInsights,
            'AI Insights',
            channelDescription: 'Personalized insights and recommendations',
            importance: Importance.low,
            priority: Priority.low,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/profile',
      );
      debugPrint('Daily insight sent for user: $userId');
    } catch (e) {
      debugPrint('Error sending daily insight: $e');
    }
  }

  /// Sends level up notification
  Future<void> notifyLevelUp(
    String userId,
    int newLevel,
    UserArchetype archetype,
  ) async {
    try {
      final message = NotificationTemplates.levelUp(archetype, newLevel);

      await _localNotifications.show(
        'levelup_$userId'.hashCode,
        '🏆 Level Up!',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.rewards,
            'Rewards',
            channelDescription: 'Achievements and level-ups',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/profile',
      );
      debugPrint('Level up notification sent: Level $newLevel');
    } catch (e) {
      debugPrint('Error sending level up notification: $e');
    }
  }

  /// Sends achievement notification
  Future<void> notifyAchievement(
    String userId,
    String achievementName,
    UserArchetype archetype,
  ) async {
    try {
      final message = NotificationTemplates.achievement(
        archetype,
        achievementName,
      );

      await _localNotifications.show(
        'achievement_${achievementName}_$userId'.hashCode,
        '🏅 Achievement Unlocked!',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.rewards,
            'Rewards',
            channelDescription: 'Achievements and level-ups',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: '/profile',
      );
      debugPrint('Achievement notification sent: $achievementName');
    } catch (e) {
      debugPrint('Error sending achievement notification: $e');
    }
  }

  // ============ TIME CALCULATION HELPERS ============

  /// Returns the next occurrence of a specific time (hour:minute)
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Returns the next occurrence of a specific day of week and time
  tz.TZDateTime _nextInstanceOfDayOfWeek(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Find the next occurrence of the specified day
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the time has passed on that day, move to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
