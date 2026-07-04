// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'narrator_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(narratorLocalDatasource)
final narratorLocalDatasourceProvider = NarratorLocalDatasourceProvider._();

final class NarratorLocalDatasourceProvider
    extends
        $FunctionalProvider<
          NarratorLocalDatasource,
          NarratorLocalDatasource,
          NarratorLocalDatasource
        >
    with $Provider<NarratorLocalDatasource> {
  NarratorLocalDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorLocalDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorLocalDatasourceHash();

  @$internal
  @override
  $ProviderElement<NarratorLocalDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NarratorLocalDatasource create(Ref ref) {
    return narratorLocalDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorLocalDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorLocalDatasource>(value),
    );
  }
}

String _$narratorLocalDatasourceHash() =>
    r'fcc2673d1849f5dd5c672512d754bb5db9cbe5b6';

@ProviderFor(narratorRepository)
final narratorRepositoryProvider = NarratorRepositoryProvider._();

final class NarratorRepositoryProvider
    extends
        $FunctionalProvider<
          NarratorRepository,
          NarratorRepository,
          NarratorRepository
        >
    with $Provider<NarratorRepository> {
  NarratorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorRepositoryHash();

  @$internal
  @override
  $ProviderElement<NarratorRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NarratorRepository create(Ref ref) {
    return narratorRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorRepository>(value),
    );
  }
}

String _$narratorRepositoryHash() =>
    r'cde08456a8468d2b52b7e228db11278e7996e030';

@ProviderFor(recentNarratorNotes)
final recentNarratorNotesProvider = RecentNarratorNotesProvider._();

final class RecentNarratorNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NarratorNote>>,
          List<NarratorNote>,
          FutureOr<List<NarratorNote>>
        >
    with
        $FutureModifier<List<NarratorNote>>,
        $FutureProvider<List<NarratorNote>> {
  RecentNarratorNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentNarratorNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentNarratorNotesHash();

  @$internal
  @override
  $FutureProviderElement<List<NarratorNote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NarratorNote>> create(Ref ref) {
    return recentNarratorNotes(ref);
  }
}

String _$recentNarratorNotesHash() =>
    r'033dff68d9213434ea10eb3099f7123089414c55';

@ProviderFor(latestNarratorInsight)
final latestNarratorInsightProvider = LatestNarratorInsightProvider._();

final class LatestNarratorInsightProvider
    extends
        $FunctionalProvider<
          AsyncValue<NarratorNote?>,
          NarratorNote?,
          FutureOr<NarratorNote?>
        >
    with $FutureModifier<NarratorNote?>, $FutureProvider<NarratorNote?> {
  LatestNarratorInsightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestNarratorInsightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestNarratorInsightHash();

  @$internal
  @override
  $FutureProviderElement<NarratorNote?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NarratorNote?> create(Ref ref) {
    return latestNarratorInsight(ref);
  }
}

String _$latestNarratorInsightHash() =>
    r'6f654a581a85f7d264343cbe03b7c286b854755f';

/// Notifier that manages the currently active Narrator appearance.

@ProviderFor(NarratorStateNotifier)
final narratorStateProvider = NarratorStateNotifierProvider._();

/// Notifier that manages the currently active Narrator appearance.
final class NarratorStateNotifierProvider
    extends $NotifierProvider<NarratorStateNotifier, NarratorState> {
  /// Notifier that manages the currently active Narrator appearance.
  NarratorStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorStateNotifierHash();

  @$internal
  @override
  NarratorStateNotifier create() => NarratorStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorState>(value),
    );
  }
}

String _$narratorStateNotifierHash() =>
    r'afc6beefd2864c5f52b8ffdc66c8c8019058583a';

/// Notifier that manages the currently active Narrator appearance.

abstract class _$NarratorStateNotifier extends $Notifier<NarratorState> {
  NarratorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NarratorState, NarratorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NarratorState, NarratorState>,
              NarratorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
