// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the WorldHealthService

@ProviderFor(worldHealthService)
final worldHealthServiceProvider = WorldHealthServiceProvider._();

/// Provider for the WorldHealthService

final class WorldHealthServiceProvider
    extends
        $FunctionalProvider<
          WorldHealthService,
          WorldHealthService,
          WorldHealthService
        >
    with $Provider<WorldHealthService> {
  /// Provider for the WorldHealthService
  WorldHealthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldHealthServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldHealthServiceHash();

  @$internal
  @override
  $ProviderElement<WorldHealthService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorldHealthService create(Ref ref) {
    return worldHealthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorldHealthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorldHealthService>(value),
    );
  }
}

String _$worldHealthServiceHash() =>
    r'b247dd97a5cd93c71b5a5b62b0291c16f20dc70d';

/// Provider that calculates world health on demand
/// Uses the WorldHealthService with caching for efficiency

@ProviderFor(worldHealth)
final worldHealthProvider = WorldHealthProvider._();

/// Provider that calculates world health on demand
/// Uses the WorldHealthService with caching for efficiency

final class WorldHealthProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Provider that calculates world health on demand
  /// Uses the WorldHealthService with caching for efficiency
  WorldHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldHealthHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return worldHealth(ref);
  }
}

String _$worldHealthHash() => r'3535eb18b2ba155ffc430cef5d9982fc7a968574';

/// Reactive stream of world health score from UserProfile

@ProviderFor(worldHealthStream)
final worldHealthStreamProvider = WorldHealthStreamProvider._();

/// Reactive stream of world health score from UserProfile

final class WorldHealthStreamProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Reactive stream of world health score from UserProfile
  WorldHealthStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldHealthStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldHealthStreamHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return worldHealthStream(ref);
  }
}

String _$worldHealthStreamHash() => r'eb67ffd93c742ee27d07cf1754fa8099519e25e9';

/// Reactive stream of world entropy score from UserProfile

@ProviderFor(worldEntropyStream)
final worldEntropyStreamProvider = WorldEntropyStreamProvider._();

/// Reactive stream of world entropy score from UserProfile

final class WorldEntropyStreamProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Reactive stream of world entropy score from UserProfile
  WorldEntropyStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'worldEntropyStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$worldEntropyStreamHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return worldEntropyStream(ref);
  }
}

String _$worldEntropyStreamHash() =>
    r'e9d42173f402baec2850691a2346a2971f773f42';
