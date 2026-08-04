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

@ProviderFor(lineResolver)
final lineResolverProvider = LineResolverProvider._();

final class LineResolverProvider
    extends
        $FunctionalProvider<
          NarratorLineResolver,
          NarratorLineResolver,
          NarratorLineResolver
        >
    with $Provider<NarratorLineResolver> {
  LineResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lineResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineResolverHash();

  @$internal
  @override
  $ProviderElement<NarratorLineResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NarratorLineResolver create(Ref ref) {
    return lineResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NarratorLineResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NarratorLineResolver>(value),
    );
  }
}

String _$lineResolverHash() => r'75dbaa5d6cbae31d16610f8aeae19b3307d4223c';

/// Pending narrator line awaiting display in the slide-up card.

@ProviderFor(PendingMilestone)
final pendingMilestoneProvider = PendingMilestoneProvider._();

/// Pending narrator line awaiting display in the slide-up card.
final class PendingMilestoneProvider
    extends $NotifierProvider<PendingMilestone, PendingMilestoneLine?> {
  /// Pending narrator line awaiting display in the slide-up card.
  PendingMilestoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMilestoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMilestoneHash();

  @$internal
  @override
  PendingMilestone create() => PendingMilestone();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingMilestoneLine? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingMilestoneLine?>(value),
    );
  }
}

String _$pendingMilestoneHash() => r'ea518de9cf562be01d44746b9381ec16cdcd6c50';

/// Pending narrator line awaiting display in the slide-up card.

abstract class _$PendingMilestone extends $Notifier<PendingMilestoneLine?> {
  PendingMilestoneLine? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PendingMilestoneLine?, PendingMilestoneLine?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingMilestoneLine?, PendingMilestoneLine?>,
              PendingMilestoneLine?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Session-scoped: the Day Card has been dismissed for this app session.

@ProviderFor(NarratorCardDismissed)
final narratorCardDismissedProvider = NarratorCardDismissedProvider._();

/// Session-scoped: the Day Card has been dismissed for this app session.
final class NarratorCardDismissedProvider
    extends $NotifierProvider<NarratorCardDismissed, bool> {
  /// Session-scoped: the Day Card has been dismissed for this app session.
  NarratorCardDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorCardDismissedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorCardDismissedHash();

  @$internal
  @override
  NarratorCardDismissed create() => NarratorCardDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$narratorCardDismissedHash() =>
    r'4046a44b0a5fbb5c483aad6e901fa1ebae054df2';

/// Session-scoped: the Day Card has been dismissed for this app session.

abstract class _$NarratorCardDismissed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Session-scoped: latched request to expand and focus the Day Card's ask
/// field (driven by the timeline header avatar tap). Stays true until the
/// card consumes it, so a bump while the card is unmounted replays on mount.

@ProviderFor(NarratorAskFocus)
final narratorAskFocusProvider = NarratorAskFocusProvider._();

/// Session-scoped: latched request to expand and focus the Day Card's ask
/// field (driven by the timeline header avatar tap). Stays true until the
/// card consumes it, so a bump while the card is unmounted replays on mount.
final class NarratorAskFocusProvider
    extends $NotifierProvider<NarratorAskFocus, bool> {
  /// Session-scoped: latched request to expand and focus the Day Card's ask
  /// field (driven by the timeline header avatar tap). Stays true until the
  /// card consumes it, so a bump while the card is unmounted replays on mount.
  NarratorAskFocusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'narratorAskFocusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$narratorAskFocusHash();

  @$internal
  @override
  NarratorAskFocus create() => NarratorAskFocus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$narratorAskFocusHash() => r'a30ac32fd87ffd6238d4372ecaedc09fe8f1edcc';

/// Session-scoped: latched request to expand and focus the Day Card's ask
/// field (driven by the timeline header avatar tap). Stays true until the
/// card consumes it, so a bump while the card is unmounted replays on mount.

abstract class _$NarratorAskFocus extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
