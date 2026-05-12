// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_cache_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Synchronous provider — safe because init() is called before runApp().
/// If called before init(), it throws a clear error instead of a cryptic null crash.

@ProviderFor(localCacheService)
final localCacheServiceProvider = LocalCacheServiceProvider._();

/// Synchronous provider — safe because init() is called before runApp().
/// If called before init(), it throws a clear error instead of a cryptic null crash.

final class LocalCacheServiceProvider
    extends
        $FunctionalProvider<
          LocalCacheService,
          LocalCacheService,
          LocalCacheService
        >
    with $Provider<LocalCacheService> {
  /// Synchronous provider — safe because init() is called before runApp().
  /// If called before init(), it throws a clear error instead of a cryptic null crash.
  LocalCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localCacheServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localCacheServiceHash();

  @$internal
  @override
  $ProviderElement<LocalCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalCacheService create(Ref ref) {
    return localCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalCacheService>(value),
    );
  }
}

String _$localCacheServiceHash() => r'f3f35493407fc90ed93a3077483a09a9232d7cfb';

/// Fix #7: Reactive sync queue size using Hive.watch() instead of 2-second polling.
/// Zero CPU cost when the queue is empty.

@ProviderFor(syncQueueSize)
final syncQueueSizeProvider = SyncQueueSizeProvider._();

/// Fix #7: Reactive sync queue size using Hive.watch() instead of 2-second polling.
/// Zero CPU cost when the queue is empty.

final class SyncQueueSizeProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Fix #7: Reactive sync queue size using Hive.watch() instead of 2-second polling.
  /// Zero CPU cost when the queue is empty.
  SyncQueueSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueSizeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueSizeHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return syncQueueSize(ref);
  }
}

String _$syncQueueSizeHash() => r'9b7d1c8d6d99f370ce8f544fec6a11ecab089f34';
