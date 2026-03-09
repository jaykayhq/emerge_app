// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_presence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the online presence service instance.
///
/// This provider keeps the service alive for the app lifetime.
/// The service will be properly disposed when the provider is disposed.

@ProviderFor(onlinePresenceService)
final onlinePresenceServiceProvider = OnlinePresenceServiceProvider._();

/// Provider for the online presence service instance.
///
/// This provider keeps the service alive for the app lifetime.
/// The service will be properly disposed when the provider is disposed.

final class OnlinePresenceServiceProvider
    extends
        $FunctionalProvider<
          OnlinePresenceService,
          OnlinePresenceService,
          OnlinePresenceService
        >
    with $Provider<OnlinePresenceService> {
  /// Provider for the online presence service instance.
  ///
  /// This provider keeps the service alive for the app lifetime.
  /// The service will be properly disposed when the provider is disposed.
  OnlinePresenceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlinePresenceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlinePresenceServiceHash();

  @$internal
  @override
  $ProviderElement<OnlinePresenceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnlinePresenceService create(Ref ref) {
    return onlinePresenceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnlinePresenceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnlinePresenceService>(value),
    );
  }
}

String _$onlinePresenceServiceHash() =>
    r'60487f5c842af6510d69846490ead57a42823443';
