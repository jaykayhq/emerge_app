import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Schedules recurring reminders for every active habit with a set reminder
/// time, gated by the user's notification settings.
///
/// `zonedSchedule` with the same id replaces any existing alarm, so calling
/// this on login or after a settings change is idempotent — it covers
/// pre-existing habits, reinstalls, and reminder-time edits in one pass.
///
/// When the settings gate is off, cancels every scheduled habit reminder so
/// disabling a toggle actually silences the alarms.
Future<void> resyncHabitReminders({
  required NotificationService notificationService,
  required HabitRepository habitRepository,
  required UserProfile profile,
}) async {
  if (kIsWeb) return;
  final settings = profile.settings;

  final habits = await habitRepository.watchHabits(profile.uid).first;

  if (!settings.notificationsEnabled || !settings.habitReminders) {
    // Cancel pass — cancelling an unscheduled id is a no-op, so this is safe
    // to run unconditionally for every active habit.
    for (final habit in habits) {
      if (habit.isArchived) continue;
      await notificationService.cancelHabitNotifications(habit.id);
    }
    return;
  }

  for (final habit in habits) {
    final time = habit.reminderTime;
    if (habit.isArchived || time == null) continue;
    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await notificationService.scheduleHabitReminder(
      habit.id,
      habit.title,
      profile.archetype,
      timeString,
      habit.frequency,
      habit.specificDays,
      attribute: habit.attribute,
    );
  }
}
