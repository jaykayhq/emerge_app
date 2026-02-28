import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_notification_schedule.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
        _auth = FirebaseAuth.instance;

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
