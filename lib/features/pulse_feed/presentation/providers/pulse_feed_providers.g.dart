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
          DriftPulseFeedRepository,
          DriftPulseFeedRepository,
          DriftPulseFeedRepository
        >
    with $Provider<DriftPulseFeedRepository> {
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
  $ProviderElement<DriftPulseFeedRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DriftPulseFeedRepository create(Ref ref) {
    return pulseFeedRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriftPulseFeedRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriftPulseFeedRepository>(value),
    );
  }
}

String _$pulseFeedRepositoryHash() =>
    r'b96763d0d34ca9e34db49ab368271b5015fd969f';

/// Streams pulse-feed cards — local first, Firestore in background.
///
/// Automatically disposes when no longer watched. Returns an empty stream
/// when the user is not signed in.

@ProviderFor(pulseFeed)
final pulseFeedProvider = PulseFeedProvider._();

/// Streams pulse-feed cards — local first, Firestore in background.
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
  /// Streams pulse-feed cards — local first, Firestore in background.
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

String _$pulseFeedHash() => r'c6060cf57aee268dc400d37cd6907871b85e8f4a';
