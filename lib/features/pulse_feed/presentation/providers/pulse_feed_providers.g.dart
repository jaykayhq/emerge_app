// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pulseFeedRepository)
final pulseFeedRepositoryProvider = PulseFeedRepositoryProvider._();

final class PulseFeedRepositoryProvider
    extends
        $FunctionalProvider<
          PulseFeedRepository,
          PulseFeedRepository,
          PulseFeedRepository
        >
    with $Provider<PulseFeedRepository> {
  PulseFeedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pulseFeedRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pulseFeedRepositoryHash();

  @$internal
  @override
  $ProviderElement<PulseFeedRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PulseFeedRepository create(Ref ref) {
    return pulseFeedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PulseFeedRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PulseFeedRepository>(value),
    );
  }
}

String _$pulseFeedRepositoryHash() =>
    r'66aa0e6d230df70bcbea4a39099f070ecec1f44d';

/// Streams the latest pulse-feed cards for the currently authenticated user.
///
/// Automatically disposes when no longer watched. Returns an empty stream
/// when the user is not signed in.

@ProviderFor(pulseFeed)
final pulseFeedProvider = PulseFeedProvider._();

/// Streams the latest pulse-feed cards for the currently authenticated user.
///
/// Automatically disposes when no longer watched. Returns an empty stream
/// when the user is not signed in.

final class PulseFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PulseFeedCard>>,
          List<PulseFeedCard>,
          Stream<List<PulseFeedCard>>
        >
    with
        $FutureModifier<List<PulseFeedCard>>,
        $StreamProvider<List<PulseFeedCard>> {
  /// Streams the latest pulse-feed cards for the currently authenticated user.
  ///
  /// Automatically disposes when no longer watched. Returns an empty stream
  /// when the user is not signed in.
  PulseFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pulseFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pulseFeedHash();

  @$internal
  @override
  $StreamProviderElement<List<PulseFeedCard>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PulseFeedCard>> create(Ref ref) {
    return pulseFeed(ref);
  }
}

String _$pulseFeedHash() => r'25d489c677555d966866a08a72d12b14b9a83cfb';
