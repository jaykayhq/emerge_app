import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

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
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

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
                .set({
              'fcmToken': token,
            }, SetOptions(merge: true));
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
}
