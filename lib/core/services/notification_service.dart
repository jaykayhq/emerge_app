import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:emerge_app/core/services/notification_gate.dart';
import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/core/services/notification_action_handler.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse details) async {
  if (details.actionId != null && details.actionId!.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final container = ProviderContainer();
      await NotificationActionHandler.handle(
        actionId: details.actionId!,
        payload: details.payload,
        container: container,
      );
      container.dispose();
    } catch (e) {
      debugPrint('Background notification error: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service._attachRef(ref);
  return service;
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Riverpod [Ref] attached by the provider so that action handlers
  /// can read providers (repositories, services) from notification callbacks.
  Ref? _ref;

  /// Called by [notificationServiceProvider] to give this singleton access
  /// to the Riverpod container.
  void _attachRef(Ref ref) {
    _ref = ref;
  }

  bool _isAllowed(NotificationChannelKind kind, {DateTime? at}) {
    try {
      final profile = _ref?.read(userStatsStreamProvider).value;
      return NotificationGate.shouldShow(
        profile?.settings,
        kind,
        now: at ?? DateTime.now(),
      );
    } catch (_) {
      return true;
    }
  }

  bool _isScheduledAllowed(NotificationChannelKind kind, DateTime scheduled) {
    try {
      final profile = _ref?.read(userStatsStreamProvider).value;
      return NotificationGate.shouldShow(profile?.settings, kind, now: scheduled);
    } catch (_) {
      return true;
    }
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    // Initialize Timezone
    tz.initializeTimeZones();
    // Fallback to UTC since flutter_timezone plugin is causing build issues
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint('Could not set local location: $e');
    }

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
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(NotificationIcons.smallIcon),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (details) {
        // Action button tap → delegate to NotificationActionHandler.
        if (details.actionId != null && details.actionId!.isNotEmpty) {
          final ref = _ref;
          if (ref != null) {
            unawaited(
              NotificationActionHandler.handle(
                actionId: details.actionId!,
                payload: details.payload,
                container: ref.container,
              ),
            );
          } else {
            debugPrint(
              'NotificationActionHandler: _ref not attached yet, '
              'cannot handle action "${details.actionId}"',
            );
          }
          return;
        }

        // Plain tap → navigate to recap (payload holds route).
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

          // Save token to Firestore User document with error handling
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && token != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'fcmToken': token}, SetOptions(merge: true));
              debugPrint(
                'FCM token updated successfully for user: ${user.uid}',
              );
            } catch (e) {
              // Log error but don't crash - notification token update is non-critical
              debugPrint('Failed to update FCM token: $e');
              // Token update failure is not critical - app can still function
              // The token will be updated on next app launch
            }
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
    _isInitialized = true;
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Successfully subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
      // Topic subscription is non-critical, continue without failing
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Successfully unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
      // Topic unsubscription is non-critical, continue without failing
    }
  }

  /// Disables all notifications for [userId]: cancels pending local alarms,
  /// deletes the FCM token (so server pushes stop), and clears the stored
  /// `fcmToken` field. Call when the master toggle is turned off.
  Future<void> disableAll(String userId) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.cancelAll();
    } catch (_) {}
    try {
      await _firebaseMessaging.deleteToken();
    } catch (_) {}
    if (userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'fcmToken': FieldValue.delete()},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Re-enables notifications: re-requests permission and re-registers the
  /// FCM token. Call when the master toggle is turned back on.
  Future<void> enableAll(String userId) async {
    if (kIsWeb) return;
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      final token = await _firebaseMessaging.getToken();
      if (token != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }

  Future<void> scheduleWeeklyRecap() async {
    if (kIsWeb) return;
    final scheduled = _nextSundayNineAM();
    if (!_isScheduledAllowed(NotificationChannelKind.community, scheduled)) return;
    try {
      // Schedule for next Monday at 9:00 AM

      await _localNotifications.zonedSchedule(
        id: 0,
        title: 'Weekly Recap Ready',
        body: 'Check out how your world evolved this week!',
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            'weekly_recap',
            'Weekly Recap',
            'Weekly progress updates',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '/world-map/recap',
      );
    } catch (e, stack) {
      debugPrint('Error scheduling weekly recap: $e');
      if (!kReleaseMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  tz.TZDateTime _nextSundayNineAM() {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );

    // Find next Sunday
    while (scheduledDate.weekday != DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If today is Sunday and it's past 9am, schedule for next week
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
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.community)) return;
    try {
      await _localNotifications.show(
        id: challengeId.hashCode,
        title: '🔥 New Weekly Challenge!',
        body: challengeName,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            'weekly_challenges',
            'Weekly Challenges',
            'New weekly challenge notifications',
          ),
          iOS: const DarwinNotificationDetails(),
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
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.community)) return;
    try {
      final timeText = hoursLeft == 24
          ? '1 day'
          : hoursLeft >= 24
          ? '${hoursLeft ~/ 24} days'
          : '$hoursLeft hours';

      await _localNotifications.show(
        id: challengeId.hashCode,
        title: '⏰ Challenge Ending Soon!',
        body: 'Only $timeText left to complete your challenge!',
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            'challenge_reminders',
            'Challenge Reminders',
            'Challenge deadline notifications',
          ),
          iOS: const DarwinNotificationDetails(),
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
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.rewards)) return;
    try {
      await _localNotifications.show(
        id: challengeId.hashCode,
        title: '🎁 Reward Available!',
        body: rewardDescription,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            'rewards',
            'Rewards',
            'Reward redemption notifications',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/challenges/$challengeId',
      );
      debugPrint('Reward available notification sent: $rewardDescription');
    } catch (e) {
      debugPrint('Error sending reward notification: $e');
    }
  }

  // ============ CHANNEL DETAILS ============

  /// Splash-logo blue sampled from assets/icons/splash_logo.png; tints the
  /// small status-bar icon and the notification shade accent on Android.
  static const Color notificationAccent = Color(0xFF4850AE);

  /// Shared Android channel details. Every notification shows the Emerge
  /// splash-flame treatment: alpha-only flame silhouette in the status bar
  /// (tinted [notificationAccent]) and the blue-circle/black-flame badge as
  /// the large icon, unless an archetype-specific mark overrides it.
  AndroidNotificationDetails _androidChannel(
    String channelId,
    String name,
    String description, {
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    StyleInformation? styleInformation,
    List<AndroidNotificationAction> actions = const [],
    String? largeIconName,
    Color? color,
  }) {
    return AndroidNotificationDetails(
      channelId,
      name,
      channelDescription: description,
      importance: importance,
      priority: priority,
      color: color ?? notificationAccent,
      ledColor: color ?? notificationAccent,
      largeIcon: DrawableResourceAndroidBitmap(
        largeIconName ?? NotificationIcons.defaultLargeIcon,
      ),
      styleInformation:
          styleInformation ?? const BigTextStyleInformation(''),
      actions: actions,
    );
  }

  // ============ ARCHETYPE-THEMED NOTIFICATIONS ============

  /// Private helper to get archetype-styled Android notification details
  AndroidNotificationDetails _archetypeNotificationDetails(
    UserArchetype archetype,
    String channelId,
  ) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final primaryColor = theme.primaryColor;
    // Map to specific archetype drawable icons
    final iconName =
        NotificationIcons.archetypeIcons[archetype] ??
        NotificationIcons.defaultLargeIcon;

    return _androidChannel(
      channelId,
      '${archetype.name.toUpperCase()} Habits',
      'Archetype-styled habit reminders',
      color: primaryColor,
      largeIconName: iconName,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationActionIds.complete,
          'Complete',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationActionIds.snooze1h,
          'Snooze 1h',
          showsUserInterface: false,
        ),
      ],
    );
  }

  /// Sends immediate welcome notification when a new habit is created
  Future<void> notifyHabitCreated(
    Habit habit,
    UserArchetype archetype, {
    bool archetypeNudges = true,
  }) async {
    if (kIsWeb) return;
    final repoKind = archetypeNudges
        ? NotificationChannelKind.archetypeNudge
        : NotificationChannelKind.habitReminder;
    if (!_isAllowed(repoKind)) return;
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = archetypeNudges
          ? NotificationTemplates.welcomeMessage(
              archetype,
              habit.title,
              attribute: habit.attribute,
            )
          : 'New habit started: ${habit.title}';

      await _localNotifications.show(
        id: habit.id.hashCode,
        title: 'New Habit Started',
        body: message,
        notificationDetails: NotificationDetails(
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
    List<int> specificDays, {
    HabitAttribute? attribute,
    bool archetypeNudges = true,
  }) async {
    if (kIsWeb) return;
    final repoKind = archetypeNudges
        ? NotificationChannelKind.archetypeNudge
        : NotificationChannelKind.habitReminder;
    // Parse reminder hour early so DND can be evaluated at the fire time.
    int preHour = NotificationTemplates.getDefaultHour(archetype);
    int preMinute = 0;
    try {
      final p = reminderTime.split(':');
      preHour = int.parse(p[0]);
      preMinute = int.parse(p[1]);
    } catch (_) {}
    final preScheduled = DateTime(2000, 1, 1, preHour, preMinute);
    if (!_isScheduledAllowed(repoKind, preScheduled)) {
      await cancelHabitNotifications(habitId);
      return;
    }
    try {
      final channelId = NotificationChannels.channelForArchetype(archetype);
      final message = archetypeNudges
          ? NotificationTemplates.reminderMessage(
              archetype,
              habitTitle,
              attribute: attribute,
            )
          : 'Reminder: $habitTitle';

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
            id: habitId.hashCode,
            title: 'Habit Reminder',
            body: message,
            scheduledDate: scheduledTime,
            notificationDetails: NotificationDetails(
              android: _archetypeNotificationDetails(archetype, channelId),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
            id: habitId.hashCode,
            title: 'Habit Reminder',
            body: message,
            scheduledDate: weeklyTime,
            notificationDetails: NotificationDetails(
              android: _archetypeNotificationDetails(archetype, channelId),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
              id: '${habitId}_$day'.hashCode,
              title: 'Habit Reminder',
              body: message,
              scheduledDate: dayTime,
              notificationDetails: NotificationDetails(
                android: _archetypeNotificationDetails(archetype, channelId),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
    if (kIsWeb) return;
    try {
      // Cancel every id family this habit can schedule: the daily/weekly
      // reminder, per-day reminders (specificDays), the snoozed follow-up,
      // and the streak warning. Cancelling unscheduled ids is a no-op.
      await _localNotifications.cancel(id: habitId.hashCode);
      for (var day = 1; day <= 7; day++) {
        await _localNotifications.cancel(id: '${habitId}_$day'.hashCode);
      }
      await _localNotifications.cancel(id: '${habitId}_snoozed'.hashCode);
      await _localNotifications.cancel(id: '${habitId}_streak'.hashCode);
      debugPrint('Cancelled notifications for habit: $habitId');
    } catch (e) {
      debugPrint('Error cancelling habit notifications: $e');
    }
  }

  /// Snoozes a habit reminder by cancelling the current notification
  /// and scheduling a new one ~1 hour later.
  Future<void> snoozeHabit(String habitId) async {
    if (kIsWeb) return;
    final snoozedAt = DateTime.now().add(const Duration(hours: 1));
    if (!_isScheduledAllowed(NotificationChannelKind.habitReminder, snoozedAt)) return;
    try {
      // Cancel the existing notification for this habit.
      await _localNotifications.cancel(id: habitId.hashCode);

      final tzSnoozed = tz.TZDateTime.from(snoozedAt, tz.local);

      await _localNotifications.zonedSchedule(
        id: '${habitId}_snoozed'.hashCode,
        title: '⏰ Reminder (Snoozed)',
        body: 'Time to complete your habit!',
        scheduledDate: tzSnoozed,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            'habit_reminders',
            'Habit Reminders',
            'Habit reminder notifications',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: habitId,
      );
      debugPrint('Habit $habitId snoozed until $snoozedAt');
    } catch (e) {
      debugPrint('Error snoozing habit $habitId: $e');
    }
  }

  /// Updates habit notification by cancelling and rescheduling
  Future<void> updateHabitNotification(
    String habitId,
    String habitTitle,
    UserArchetype archetype,
    String reminderTime,
    HabitFrequency frequency,
    List<int> specificDays, {
    HabitAttribute? attribute,
    bool archetypeNudges = true,
  }) async {
    if (kIsWeb) return;
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
        attribute: attribute,
        archetypeNudges: archetypeNudges,
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
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.streakWarning)) return;
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
      if (!_isScheduledAllowed(
        NotificationChannelKind.streakWarning,
        DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day,
            scheduledTime.hour, scheduledTime.minute),
      )) {
        await _localNotifications.cancel(id: '${habitId}_streak'.hashCode);
        return;
      }

      await _localNotifications.zonedSchedule(
        id: '${habitId}_streak'.hashCode,
        title: '⚠️ Streak at Risk!',
        body: message,
        scheduledDate: scheduledTime,
        notificationDetails: NotificationDetails(
          android: _archetypeNotificationDetails(archetype, channelId),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/habits/$habitId',
      );
      debugPrint('Streak warning scheduled for: $habitTitle');
    } catch (e) {
      debugPrint('Error scheduling streak warning: $e');
    }
  }

  /// Schedules the daily AI insight notification (client-side replacement
  /// for the Cloud Scheduler's `sendDailyInsights`). Fires at 08:00 daily;
  /// scheduling again with the same id replaces any prior schedule.
  Future<void> scheduleDailyInsight(
    String userId,
    String insight,
    UserArchetype archetype,
  ) async {
    if (kIsWeb) return;
    final insightAt = _nextInsightTime();
    if (!_isScheduledAllowed(NotificationChannelKind.aiInsight, DateTime(insightAt.year, insightAt.month, insightAt.day, insightAt.hour, insightAt.minute))) {
      await cancelDailyInsight(userId);
      return;
    }
    try {
      final greeting = NotificationTemplates.aiInsightGreeting(archetype);

      await _localNotifications.zonedSchedule(
        id: 'insight_$userId'.hashCode,
        title: 'Daily Insight',
        body: '$greeting\n\n$insight',
        scheduledDate: insightAt,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            NotificationChannels.aiInsights,
            'AI Insights',
            'Personalized insights and recommendations',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/profile',
      );
      debugPrint('Daily insight scheduled for user: $userId');
    } catch (e) {
      debugPrint('Error scheduling daily insight: $e');
    }
  }

  /// Cancels the scheduled daily AI insight for [userId].
  Future<void> cancelDailyInsight(String userId) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.cancel(id: 'insight_$userId'.hashCode);
    } catch (e) {
      debugPrint('Error cancelling daily insight: $e');
    }
  }

  /// Next 08:00 local — today if not past, else tomorrow. The app pins the
  /// local timezone to UTC (see initialize), matching the old 08:00 UTC cron.
  tz.TZDateTime _nextInsightTime() {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Sends level up notification
  Future<void> notifyLevelUp(
    String userId,
    int newLevel,
    UserArchetype archetype,
  ) async {
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.rewards)) return;
    try {
      final message = NotificationTemplates.levelUp(archetype, newLevel);

      await _localNotifications.show(
        id: 'levelup_$userId'.hashCode,
        title: '🏆 Level Up!',
        body: message,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            NotificationChannels.rewards,
            'Rewards',
            'Achievements and level-ups',
          ),
          iOS: const DarwinNotificationDetails(),
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
    if (kIsWeb) return;
    if (!_isAllowed(NotificationChannelKind.rewards)) return;
    try {
      final message = NotificationTemplates.achievement(
        archetype,
        achievementName,
      );

      await _localNotifications.show(
        id: 'achievement_${achievementName}_$userId'.hashCode,
        title: '🏅 Achievement Unlocked!',
        body: message,
        notificationDetails: NotificationDetails(
          android: _androidChannel(
            NotificationChannels.rewards,
            'Rewards',
            'Achievements and level-ups',
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
