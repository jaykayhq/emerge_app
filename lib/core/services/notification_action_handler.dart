import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/core/services/notification_service.dart';

/// Canonical IDs for notification action buttons.
abstract final class NotificationActionIds {
  static const String complete = 'complete';
  static const String snooze1h = 'snooze_1h';
}

/// Handles notification action button taps.
///
/// Dispatches [actionId] to the correct handler using the provided
/// [container] so that Riverpod providers are accessible from the
/// notification callback context (which typically runs outside the
/// widget tree).
abstract final class NotificationActionHandler {
  /// Process a notification action.
  ///
  /// [actionId]  — the ID of the tapped action button.
  /// [payload]   — the notification payload (typically the habit ID).
  /// [container] — a Riverpod [ProviderContainer] (works in non-widget
  ///               code and in tests).
  static Future<void> handle({
    required String actionId,
    required String? payload,
    required ProviderContainer container,
  }) async {
    if (payload == null || payload.isEmpty) {
      debugPrint(
        'NotificationActionHandler: no payload for action "$actionId"',
      );
      return;
    }

    switch (actionId) {
      case NotificationActionIds.complete:
        await _handleComplete(payload, container);
      case NotificationActionIds.snooze1h:
        await _handleSnooze(payload, container);
      default:
        debugPrint(
          'NotificationActionHandler: unknown action "$actionId"',
        );
    }
  }

  /// Mark the habit identified by [habitId] as completed.
  static Future<void> _handleComplete(
    String habitId,
    ProviderContainer container,
  ) async {
    try {
      await container.read(completeHabitProvider(habitId).future);
      debugPrint(
        'NotificationActionHandler: habit $habitId completed via notification',
      );
    } catch (e, stack) {
      debugPrint(
        'NotificationActionHandler: failed to complete habit $habitId: $e',
      );
      if (!kReleaseMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  /// Snooze the habit notification for ~1 hour.
  static Future<void> _handleSnooze(
    String habitId,
    ProviderContainer container,
  ) async {
    try {
      final service = container.read(notificationServiceProvider);
      await service.snoozeHabit(habitId);
      debugPrint(
        'NotificationActionHandler: habit $habitId snoozed 1h',
      );
    } catch (e, stack) {
      debugPrint(
        'NotificationActionHandler: failed to snooze habit $habitId: $e',
      );
      if (!kReleaseMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }
}
