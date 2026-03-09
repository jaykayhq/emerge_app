// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the social notification service instance

@ProviderFor(socialNotificationService)
final socialNotificationServiceProvider = SocialNotificationServiceProvider._();

/// Provider for the social notification service instance

final class SocialNotificationServiceProvider
    extends
        $FunctionalProvider<
          SocialNotificationService,
          SocialNotificationService,
          SocialNotificationService
        >
    with $Provider<SocialNotificationService> {
  /// Provider for the social notification service instance
  SocialNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialNotificationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<SocialNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SocialNotificationService create(Ref ref) {
    return socialNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialNotificationService>(value),
    );
  }
}

String _$socialNotificationServiceHash() =>
    r'e08785853ecf8dc40eb72c3ff5f06066d5b05488';

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
    r'101460624cbd98c8921e750aa470f4282f64d1fc';

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

String _$notificationsHash() => r'27d750b578120719d8a36f8865cec31cfcf017d6';

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
///   error: (_, _) => Badge(count: 0),
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
  ///   error: (_, _) => Badge(count: 0),
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

String _$unreadCountHash() => r'0563893fd6429051e308d8f18ef2537e1c62e99d';

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

String _$unreadCountFutureHash() => r'3654386e098274f7731a1efcde201129c615c3b8';
