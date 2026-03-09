import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

part 'notification_provider.g.dart';

/// Provider for the social notification service instance
///
/// This is already provided by socialNotificationServiceProvider
/// but re-exported here for convenience in the core presentation layer
final socialNotificationServiceProvider = socialNotificationServiceProvider;

/// Stream provider for unread notifications for the current user
///
/// Usage:
/// ```dart
/// final unreadNotifications = ref.watch(unreadNotificationsProvider);
/// unreadNotifications.when(
///   data: (notifications) => ListView.builder(...),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@riverpod
Stream<List<AppNotification>> unreadNotifications(UnreadNotificationsRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return const Stream.empty();
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.unreadNotificationsStream(user.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
}

/// Stream provider for all notifications (paginated) for the current user
///
/// Usage:
/// ```dart
/// final notificationsAsync = ref.watch(notificationsProvider);
/// ```
@riverpod
Stream<List<AppNotification>> notifications(NotificationsRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return const Stream.empty();
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.notificationsStream(user.id, limit: 20);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
}

/// Stream provider for unread notification count
///
/// Usage:
/// ```dart
/// final unreadCount = ref.watch(unreadCountProvider);
/// unreadCount.when(
///   data: (count) => Badge(count: count),
///   loading: () => Badge(count: 0),
///   error: (_, __) => Badge(count: 0),
/// );
/// ```
@riverpod
Stream<int> unreadCount(UnreadCountRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return const Stream.value(0);
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.unreadCountStream(user.id);
    },
    loading: () => const Stream.value(0),
    error: (_, __) => const Stream.value(0),
  );
}

/// Future provider for one-time unread count fetch
///
/// Usage:
/// ```dart
/// final countAsync = ref.watch(unreadCountFutureProvider);
/// final count = countAsync.value ?? 0;
/// ```
@riverpod
Future<int> unreadCountFuture(UnreadCountFutureRef ref) async {
  final authState = ref.watch(authStateChangesProvider);

  final user = authState.value;
  if (user == null) {
    return 0;
  }

  final service = ref.watch(socialNotificationServiceProvider);
  return service.getUnreadCount(user.id);
}

/// Action provider to mark a notification as read
///
/// Usage:
/// ```dart
/// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
/// ```
@riverpod
Future<void> markAsRead(
  MarkAsReadRef ref,
  String notificationId,
) async {
  final authState = ref.read(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.read(socialNotificationServiceProvider);
  await service.markAsRead(user.id, notificationId);
}

/// Action provider to mark all notifications as read
///
/// Usage:
/// ```dart
/// ref.read(markAllAsReadProvider.notifier)();
/// ```
@riverpod
Future<void> markAllAsRead(MarkAllAsReadRef ref) async {
  final authState = ref.read(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.read(socialNotificationServiceProvider);
  await service.markAllAsRead(user.id);
}

/// Action provider to delete a notification
///
/// Usage:
/// ```dart
/// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
/// ```
@riverpod
Future<void> deleteNotification(
  DeleteNotificationRef ref,
  String notificationId,
) async {
  final authState = ref.read(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.read(socialNotificationServiceProvider);
  await service.deleteNotification(user.id, notificationId);
}

/// Action provider to send a notification to a specific user
///
/// Usage:
/// ```dart
/// final service = ref.read(socialNotificationServiceProvider);
/// final notification = service.createFriendRequestNotification(
///   senderName: 'John',
///   senderId: 'user123',
/// );
/// await ref.read(sendNotificationProvider.notifier)(targetUserId, notification);
/// ```
@riverpod
Future<void> sendNotification(
  SendNotificationRef ref,
  String targetUserId,
  AppNotification notification,
) async {
  final service = ref.read(socialNotificationServiceProvider);
  await service.sendNotification(targetUserId, notification);
}

/// Action provider to send a notification to multiple users
///
/// Usage:
/// ```dart
/// final service = ref.read(socialNotificationServiceProvider);
/// final notification = service.createTribeActivityNotification(
///   tribeName: 'Warriors',
///   tribeId: 'tribe123',
///   activityDescription: 'Weekly challenge completed!',
/// );
/// await ref.read(sendNotificationToMultipleProvider.notifier)(userIds, notification);
/// ```
@riverpod
Future<void> sendNotificationToMultiple(
  SendNotificationToMultipleRef ref,
  List<String> userIds,
  AppNotification notification,
) async {
  final service = ref.read(socialNotificationServiceProvider);
  await service.sendNotificationToMultiple(userIds, notification);
}

/// Combined provider that returns both unread count and notifications
/// Useful for notification screens that need both pieces of data
///
/// Usage:
/// ```dart
/// final notificationData = ref.watch(notificationDataProvider);
/// notificationData.when(
///   data: (data) {
///     final count = data.$1;
///     final notifications = data.$2;
///     // Render UI
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@riverpod
Stream<(int count, List<AppNotification> notifications)> notificationData(
  NotificationDataRef ref,
) {
  final countStream = ref.watch(unreadCountProvider);
  final notificationsStream = ref.watch(unreadNotificationsProvider);

  // Combine both streams using async* generator
  return Stream.asyncExpand((count) {
    return notificationsStream.map((notifications) => (count, notifications));
  }).asyncExpand((data) async* {
    yield data;
  });
}

/// Provider for cleaning up expired notifications
/// Should be called on app startup or periodically
///
/// Usage:
/// ```dart
/// ref.listen(deleteExpiredNotificationsProvider, (previous, next) {
///   next.when(
///     data: (_) => print('Expired notifications cleaned up'),
///     error: (err, _) => print('Cleanup error: $err'),
///     loading: () {},
///   );
/// });
/// ```
@riverpod
Future<void> deleteExpiredNotifications(DeleteExpiredNotificationsRef ref) async {
  final authState = ref.read(authStateChangesProvider);
  final user = authState.value;
  if (user == null) {
    return;
  }

  final service = ref.read(socialNotificationServiceProvider);
  await service.deleteExpiredNotifications(user.id);
}
