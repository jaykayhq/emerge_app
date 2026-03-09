// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_notification_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Service for managing in-app notifications for social interactions.
/// Stores notifications in Firestore subcollection: users/{userId}/notifications

@ProviderFor(socialNotificationService)
final socialNotificationServiceProvider = SocialNotificationServiceProvider._();

/// Service for managing in-app notifications for social interactions.
/// Stores notifications in Firestore subcollection: users/{userId}/notifications

final class SocialNotificationServiceProvider
    extends
        $FunctionalProvider<
          SocialNotificationService,
          SocialNotificationService,
          SocialNotificationService
        >
    with $Provider<SocialNotificationService> {
  /// Service for managing in-app notifications for social interactions.
  /// Stores notifications in Firestore subcollection: users/{userId}/notifications
  SocialNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialNotificationServiceProvider',
        isAutoDispose: false,
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
    r'ef4a6d7e2e551bd5afd0efc4a9e587239c8abfc8';
