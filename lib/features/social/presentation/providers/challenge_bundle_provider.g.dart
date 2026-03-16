// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_bundle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Consolidated challenge data provider
/// Fetches all challenge data in a single batch to prevent multiple rebuild waves

@ProviderFor(ChallengeBundle)
final challengeBundleProvider = ChallengeBundleProvider._();

/// Consolidated challenge data provider
/// Fetches all challenge data in a single batch to prevent multiple rebuild waves
final class ChallengeBundleProvider
    extends $AsyncNotifierProvider<ChallengeBundle, ChallengeBundleData> {
  /// Consolidated challenge data provider
  /// Fetches all challenge data in a single batch to prevent multiple rebuild waves
  ChallengeBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengeBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengeBundleHash();

  @$internal
  @override
  ChallengeBundle create() => ChallengeBundle();
}

String _$challengeBundleHash() => r'5ce10037efd296d5f128abfa666e7cb5805f6d79';

/// Consolidated challenge data provider
/// Fetches all challenge data in a single batch to prevent multiple rebuild waves

abstract class _$ChallengeBundle extends $AsyncNotifier<ChallengeBundleData> {
  FutureOr<ChallengeBundleData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ChallengeBundleData>, ChallengeBundleData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChallengeBundleData>, ChallengeBundleData>,
              AsyncValue<ChallengeBundleData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Selector helper for weekly spotlight

@ProviderFor(weeklySpotlightFromBundle)
final weeklySpotlightFromBundleProvider = WeeklySpotlightFromBundleProvider._();

/// Selector helper for weekly spotlight

final class WeeklySpotlightFromBundleProvider
    extends $FunctionalProvider<Challenge?, Challenge?, Challenge?>
    with $Provider<Challenge?> {
  /// Selector helper for weekly spotlight
  WeeklySpotlightFromBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklySpotlightFromBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklySpotlightFromBundleHash();

  @$internal
  @override
  $ProviderElement<Challenge?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Challenge? create(Ref ref) {
    return weeklySpotlightFromBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Challenge? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Challenge?>(value),
    );
  }
}

String _$weeklySpotlightFromBundleHash() =>
    r'ec8d0f53ee7314693022ddec55515b3e57746fc3';

/// Selector helper for daily quest

@ProviderFor(dailyQuestFromBundle)
final dailyQuestFromBundleProvider = DailyQuestFromBundleProvider._();

/// Selector helper for daily quest

final class DailyQuestFromBundleProvider
    extends $FunctionalProvider<Challenge?, Challenge?, Challenge?>
    with $Provider<Challenge?> {
  /// Selector helper for daily quest
  DailyQuestFromBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyQuestFromBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyQuestFromBundleHash();

  @$internal
  @override
  $ProviderElement<Challenge?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Challenge? create(Ref ref) {
    return dailyQuestFromBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Challenge? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Challenge?>(value),
    );
  }
}

String _$dailyQuestFromBundleHash() =>
    r'6bb50a47579ae8119c2e56f80ecee65e4f214047';

/// Selector helper for user challenges

@ProviderFor(userChallengesFromBundle)
final userChallengesFromBundleProvider = UserChallengesFromBundleProvider._();

/// Selector helper for user challenges

final class UserChallengesFromBundleProvider
    extends
        $FunctionalProvider<List<Challenge>, List<Challenge>, List<Challenge>>
    with $Provider<List<Challenge>> {
  /// Selector helper for user challenges
  UserChallengesFromBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userChallengesFromBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userChallengesFromBundleHash();

  @$internal
  @override
  $ProviderElement<List<Challenge>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Challenge> create(Ref ref) {
    return userChallengesFromBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Challenge> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Challenge>>(value),
    );
  }
}

String _$userChallengesFromBundleHash() =>
    r'fe405583811ece27da6d8edd8a649b3e1685f66c';

/// Selector helper for archetype challenges

@ProviderFor(archetypeChallengesFromBundle)
final archetypeChallengesFromBundleProvider =
    ArchetypeChallengesFromBundleProvider._();

/// Selector helper for archetype challenges

final class ArchetypeChallengesFromBundleProvider
    extends
        $FunctionalProvider<List<Challenge>, List<Challenge>, List<Challenge>>
    with $Provider<List<Challenge>> {
  /// Selector helper for archetype challenges
  ArchetypeChallengesFromBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archetypeChallengesFromBundleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archetypeChallengesFromBundleHash();

  @$internal
  @override
  $ProviderElement<List<Challenge>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Challenge> create(Ref ref) {
    return archetypeChallengesFromBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Challenge> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Challenge>>(value),
    );
  }
}

String _$archetypeChallengesFromBundleHash() =>
    r'8cb817a76b9c1af7ade4403250f9bf9678a86da4';
