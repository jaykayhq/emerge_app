import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

part 'notification_provider.g.dart';

/// Provider for the social notification service instance
@riverpod
SocialNotificationService socialNotificationService(Ref ref) {
  return SocialNotificationService(FirebaseFirestore.instance);
}

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
Stream<List<AppNotification>> unreadNotifications(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user.isEmpty) {
        return const Stream.empty();
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.unreadNotificationsStream(user.id);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
}

/// Stream provider for all notifications (paginated) for the current user
///
/// Usage:
/// ```dart
/// final notificationsAsync = ref.watch(notificationsProvider);
/// ```
@riverpod
Stream<List<AppNotification>> notifications(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user.isEmpty) {
        return const Stream.empty();
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.notificationsStream(user.id, limit: 20);
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
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
///   error: (_, _) => Badge(count: 0),
/// );
/// ```
@riverpod
Stream<int> unreadCount(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user.isEmpty) {
        return Stream.value(0);
      }
      final service = ref.watch(socialNotificationServiceProvider);
      return service.unreadCountStream(user.id);
    },
    loading: () => Stream.value(0),
    error: (_, _) => Stream.value(0),
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
Future<int> unreadCountFuture(Ref ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null || user.isEmpty) return 0;

  final service = ref.watch(socialNotificationServiceProvider);
  return service.getUnreadCount(user.id);
}
