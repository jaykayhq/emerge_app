// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creatorAnalyticsService)
final creatorAnalyticsServiceProvider = CreatorAnalyticsServiceProvider._();

final class CreatorAnalyticsServiceProvider
    extends
        $FunctionalProvider<
          CreatorAnalyticsService,
          CreatorAnalyticsService,
          CreatorAnalyticsService
        >
    with $Provider<CreatorAnalyticsService> {
  CreatorAnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorAnalyticsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorAnalyticsServiceHash();

  @$internal
  @override
  $ProviderElement<CreatorAnalyticsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreatorAnalyticsService create(Ref ref) {
    return creatorAnalyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatorAnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatorAnalyticsService>(value),
    );
  }
}

String _$creatorAnalyticsServiceHash() =>
    r'b166327ece6fa0459e9f9848a7f2a2c8a5667c4b';

@ProviderFor(tribeAnalyticsSnapshotService)
final tribeAnalyticsSnapshotServiceProvider =
    TribeAnalyticsSnapshotServiceProvider._();

final class TribeAnalyticsSnapshotServiceProvider
    extends
        $FunctionalProvider<
          TribeAnalyticsSnapshotService,
          TribeAnalyticsSnapshotService,
          TribeAnalyticsSnapshotService
        >
    with $Provider<TribeAnalyticsSnapshotService> {
  TribeAnalyticsSnapshotServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tribeAnalyticsSnapshotServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tribeAnalyticsSnapshotServiceHash();

  @$internal
  @override
  $ProviderElement<TribeAnalyticsSnapshotService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TribeAnalyticsSnapshotService create(Ref ref) {
    return tribeAnalyticsSnapshotService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TribeAnalyticsSnapshotService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TribeAnalyticsSnapshotService>(
        value,
      ),
    );
  }
}

String _$tribeAnalyticsSnapshotServiceHash() =>
    r'e82b2236cf241cbbc7c4c41977a9d58f5b25e5e0';

/// Full analytics for (uid, tribeId). Refreshes on invalidation
/// (e.g. after a share action or pull-to-refresh).

@ProviderFor(creatorAnalytics)
final creatorAnalyticsProvider = CreatorAnalyticsFamily._();

/// Full analytics for (uid, tribeId). Refreshes on invalidation
/// (e.g. after a share action or pull-to-refresh).

final class CreatorAnalyticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreatorAnalytics>,
          CreatorAnalytics,
          FutureOr<CreatorAnalytics>
        >
    with $FutureModifier<CreatorAnalytics>, $FutureProvider<CreatorAnalytics> {
  /// Full analytics for (uid, tribeId). Refreshes on invalidation
  /// (e.g. after a share action or pull-to-refresh).
  CreatorAnalyticsProvider._({
    required CreatorAnalyticsFamily super.from,
    required ({String uid, String tribeId}) super.argument,
  }) : super(
         retry: null,
         name: r'creatorAnalyticsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$creatorAnalyticsHash();

  @override
  String toString() {
    return r'creatorAnalyticsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CreatorAnalytics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreatorAnalytics> create(Ref ref) {
    final argument = this.argument as ({String uid, String tribeId});
    return creatorAnalytics(ref, uid: argument.uid, tribeId: argument.tribeId);
  }

  @override
  bool operator ==(Object other) {
    return other is CreatorAnalyticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$creatorAnalyticsHash() => r'0e9256e4d2df166c3a21c6e696194ce950de0bce';

/// Full analytics for (uid, tribeId). Refreshes on invalidation
/// (e.g. after a share action or pull-to-refresh).

final class CreatorAnalyticsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CreatorAnalytics>,
          ({String uid, String tribeId})
        > {
  CreatorAnalyticsFamily._()
    : super(
        retry: null,
        name: r'creatorAnalyticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Full analytics for (uid, tribeId). Refreshes on invalidation
  /// (e.g. after a share action or pull-to-refresh).

  CreatorAnalyticsProvider call({
    required String uid,
    required String tribeId,
  }) => CreatorAnalyticsProvider._(
    argument: (uid: uid, tribeId: tribeId),
    from: this,
  );

  @override
  String toString() => r'creatorAnalyticsProvider';
}
