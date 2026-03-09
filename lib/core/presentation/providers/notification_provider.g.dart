// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(unreadNotifications)
final unreadNotificationsProvider = UnreadNotificationsProvider._();

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

final class UnreadNotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
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
  UnreadNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return unreadNotifications(ref);
  }
}

String _$unreadNotificationsHash() =>
    r'3e870fe1bae46a991320d8115fa7f84954ee9da4';

/// Stream provider for all notifications (paginated) for the current user
///
/// Usage:
/// ```dart
/// final notificationsAsync = ref.watch(notificationsProvider);
/// ```

@ProviderFor(notifications)
final notificationsProvider = NotificationsProvider._();

/// Stream provider for all notifications (paginated) for the current user
///
/// Usage:
/// ```dart
/// final notificationsAsync = ref.watch(notificationsProvider);
/// ```

final class NotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
  /// Stream provider for all notifications (paginated) for the current user
  ///
  /// Usage:
  /// ```dart
  /// final notificationsAsync = ref.watch(notificationsProvider);
  /// ```
  NotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return notifications(ref);
  }
}

String _$notificationsHash() => r'a3b2fa5ccc3afc622e1d063b73fcb75484caca26';

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

@ProviderFor(unreadCount)
final unreadCountProvider = UnreadCountProvider._();

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

final class UnreadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
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
  UnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return unreadCount(ref);
  }
}

String _$unreadCountHash() => r'30740735b6c4ba3af0d39dce35c76b8a2686fba8';

/// Future provider for one-time unread count fetch
///
/// Usage:
/// ```dart
/// final countAsync = ref.watch(unreadCountFutureProvider);
/// final count = countAsync.value ?? 0;
/// ```

@ProviderFor(unreadCountFuture)
final unreadCountFutureProvider = UnreadCountFutureProvider._();

/// Future provider for one-time unread count fetch
///
/// Usage:
/// ```dart
/// final countAsync = ref.watch(unreadCountFutureProvider);
/// final count = countAsync.value ?? 0;
/// ```

final class UnreadCountFutureProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Future provider for one-time unread count fetch
  ///
  /// Usage:
  /// ```dart
  /// final countAsync = ref.watch(unreadCountFutureProvider);
  /// final count = countAsync.value ?? 0;
  /// ```
  UnreadCountFutureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadCountFutureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadCountFutureHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return unreadCountFuture(ref);
  }
}

String _$unreadCountFutureHash() => r'0c34f34c8df86b0c75205951815293f7816b2b8c';

/// Action provider to mark a notification as read
///
/// Usage:
/// ```dart
/// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
/// ```

@ProviderFor(markAsRead)
final markAsReadProvider = MarkAsReadFamily._();

/// Action provider to mark a notification as read
///
/// Usage:
/// ```dart
/// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
/// ```

final class MarkAsReadProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Action provider to mark a notification as read
  ///
  /// Usage:
  /// ```dart
  /// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
  /// ```
  MarkAsReadProvider._({
    required MarkAsReadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'markAsReadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$markAsReadHash();

  @override
  String toString() {
    return r'markAsReadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return markAsRead(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkAsReadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$markAsReadHash() => r'962981bb8eff7d7e0d260ac49b31c27e4cf94348';

/// Action provider to mark a notification as read
///
/// Usage:
/// ```dart
/// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
/// ```

final class MarkAsReadFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  MarkAsReadFamily._()
    : super(
        retry: null,
        name: r'markAsReadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Action provider to mark a notification as read
  ///
  /// Usage:
  /// ```dart
  /// ref.read(markAsReadProvider(notificationId).notifier)(notificationId);
  /// ```

  MarkAsReadProvider call(String notificationId) =>
      MarkAsReadProvider._(argument: notificationId, from: this);

  @override
  String toString() => r'markAsReadProvider';
}

/// Action provider to mark all notifications as read
///
/// Usage:
/// ```dart
/// ref.read(markAllAsReadProvider.notifier)();
/// ```

@ProviderFor(markAllAsRead)
final markAllAsReadProvider = MarkAllAsReadProvider._();

/// Action provider to mark all notifications as read
///
/// Usage:
/// ```dart
/// ref.read(markAllAsReadProvider.notifier)();
/// ```

final class MarkAllAsReadProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Action provider to mark all notifications as read
  ///
  /// Usage:
  /// ```dart
  /// ref.read(markAllAsReadProvider.notifier)();
  /// ```
  MarkAllAsReadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markAllAsReadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markAllAsReadHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return markAllAsRead(ref);
  }
}

String _$markAllAsReadHash() => r'20605661208ca642625d3d7bbef70a4820752248';

/// Action provider to delete a notification
///
/// Usage:
/// ```dart
/// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
/// ```

@ProviderFor(deleteNotification)
final deleteNotificationProvider = DeleteNotificationFamily._();

/// Action provider to delete a notification
///
/// Usage:
/// ```dart
/// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
/// ```

final class DeleteNotificationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Action provider to delete a notification
  ///
  /// Usage:
  /// ```dart
  /// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
  /// ```
  DeleteNotificationProvider._({
    required DeleteNotificationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteNotificationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteNotificationHash();

  @override
  String toString() {
    return r'deleteNotificationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return deleteNotification(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteNotificationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteNotificationHash() =>
    r'c53e9c6d17125a24742447f6d13904fa49546d89';

/// Action provider to delete a notification
///
/// Usage:
/// ```dart
/// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
/// ```

final class DeleteNotificationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  DeleteNotificationFamily._()
    : super(
        retry: null,
        name: r'deleteNotificationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Action provider to delete a notification
  ///
  /// Usage:
  /// ```dart
  /// ref.read(deleteNotificationProvider(notificationId).notifier)(notificationId);
  /// ```

  DeleteNotificationProvider call(String notificationId) =>
      DeleteNotificationProvider._(argument: notificationId, from: this);

  @override
  String toString() => r'deleteNotificationProvider';
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

@ProviderFor(sendNotification)
final sendNotificationProvider = SendNotificationFamily._();

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

final class SendNotificationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  SendNotificationProvider._({
    required SendNotificationFamily super.from,
    required (String, AppNotification) super.argument,
  }) : super(
         retry: null,
         name: r'sendNotificationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendNotificationHash();

  @override
  String toString() {
    return r'sendNotificationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, AppNotification);
    return sendNotification(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SendNotificationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendNotificationHash() => r'e1104934d676c2ef19667fc37843b82cc59ac46c';

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

final class SendNotificationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, AppNotification)> {
  SendNotificationFamily._()
    : super(
        retry: null,
        name: r'sendNotificationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  SendNotificationProvider call(
    String targetUserId,
    AppNotification notification,
  ) => SendNotificationProvider._(
    argument: (targetUserId, notification),
    from: this,
  );

  @override
  String toString() => r'sendNotificationProvider';
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

@ProviderFor(sendNotificationToMultiple)
final sendNotificationToMultipleProvider = SendNotificationToMultipleFamily._();

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

final class SendNotificationToMultipleProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  SendNotificationToMultipleProvider._({
    required SendNotificationToMultipleFamily super.from,
    required (List<String>, AppNotification) super.argument,
  }) : super(
         retry: null,
         name: r'sendNotificationToMultipleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendNotificationToMultipleHash();

  @override
  String toString() {
    return r'sendNotificationToMultipleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (List<String>, AppNotification);
    return sendNotificationToMultiple(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SendNotificationToMultipleProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendNotificationToMultipleHash() =>
    r'ac84f5e0402e1ae3fe0baae15da6e825599b1eb2';

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

final class SendNotificationToMultipleFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          (List<String>, AppNotification)
        > {
  SendNotificationToMultipleFamily._()
    : super(
        retry: null,
        name: r'sendNotificationToMultipleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  SendNotificationToMultipleProvider call(
    List<String> userIds,
    AppNotification notification,
  ) => SendNotificationToMultipleProvider._(
    argument: (userIds, notification),
    from: this,
  );

  @override
  String toString() => r'sendNotificationToMultipleProvider';
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

@ProviderFor(notificationData)
final notificationDataProvider = NotificationDataProvider._();

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

final class NotificationDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<(int, List<AppNotification>)>,
          (int, List<AppNotification>),
          Stream<(int, List<AppNotification>)>
        >
    with
        $FutureModifier<(int, List<AppNotification>)>,
        $StreamProvider<(int, List<AppNotification>)> {
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
  NotificationDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationDataHash();

  @$internal
  @override
  $StreamProviderElement<(int, List<AppNotification>)> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<(int, List<AppNotification>)> create(Ref ref) {
    return notificationData(ref);
  }
}

String _$notificationDataHash() => r'8b97e2074065692e376e45fbd4f0b90a6f4443a0';

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

@ProviderFor(deleteExpiredNotifications)
final deleteExpiredNotificationsProvider =
    DeleteExpiredNotificationsProvider._();

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

final class DeleteExpiredNotificationsProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
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
  DeleteExpiredNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteExpiredNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteExpiredNotificationsHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return deleteExpiredNotifications(ref);
  }
}

String _$deleteExpiredNotificationsHash() =>
    r'c9037c7875f34a49cf980ddfe65714a9e5e02793';
