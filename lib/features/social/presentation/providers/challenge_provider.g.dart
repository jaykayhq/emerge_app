// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(featuredChallenges)
final featuredChallengesProvider = FeaturedChallengesProvider._();

final class FeaturedChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challenge>>,
          List<Challenge>,
          FutureOr<List<Challenge>>
        >
    with $FutureModifier<List<Challenge>>, $FutureProvider<List<Challenge>> {
  FeaturedChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredChallengesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredChallengesHash();

  @$internal
  @override
  $FutureProviderElement<List<Challenge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challenge>> create(Ref ref) {
    return featuredChallenges(ref);
  }
}

String _$featuredChallengesHash() =>
    r'a652397d57315c702d53e27cddea549a242fc414';

@ProviderFor(allChallenges)
final allChallengesProvider = AllChallengesProvider._();

final class AllChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challenge>>,
          List<Challenge>,
          FutureOr<List<Challenge>>
        >
    with $FutureModifier<List<Challenge>>, $FutureProvider<List<Challenge>> {
  AllChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allChallengesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allChallengesHash();

  @$internal
  @override
  $FutureProviderElement<List<Challenge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challenge>> create(Ref ref) {
    return allChallenges(ref);
  }
}

String _$allChallengesHash() => r'ef22a6177a29260ede21a7aedf98718bb92aa210';

@ProviderFor(userChallenges)
final userChallengesProvider = UserChallengesProvider._();

final class UserChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challenge>>,
          List<Challenge>,
          FutureOr<List<Challenge>>
        >
    with $FutureModifier<List<Challenge>>, $FutureProvider<List<Challenge>> {
  UserChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userChallengesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userChallengesHash();

  @$internal
  @override
  $FutureProviderElement<List<Challenge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challenge>> create(Ref ref) {
    return userChallenges(ref);
  }
}

String _$userChallengesHash() => r'a40c1872ac144785be07f86b83d8563322b143f8';

/// Challenges filtered by the current user's archetype

@ProviderFor(archetypeChallenges)
final archetypeChallengesProvider = ArchetypeChallengesProvider._();

/// Challenges filtered by the current user's archetype

final class ArchetypeChallengesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Challenge>>,
          List<Challenge>,
          FutureOr<List<Challenge>>
        >
    with $FutureModifier<List<Challenge>>, $FutureProvider<List<Challenge>> {
  /// Challenges filtered by the current user's archetype
  ArchetypeChallengesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archetypeChallengesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archetypeChallengesHash();

  @$internal
  @override
  $FutureProviderElement<List<Challenge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Challenge>> create(Ref ref) {
    return archetypeChallenges(ref);
  }
}

String _$archetypeChallengesHash() =>
    r'caf6410b71e0161ba7e7c0ceb5d2a55158923da5';

/// Weekly spotlight challenge for the user's archetype

@ProviderFor(weeklySpotlight)
final weeklySpotlightProvider = WeeklySpotlightProvider._();

/// Weekly spotlight challenge for the user's archetype

final class WeeklySpotlightProvider
    extends
        $FunctionalProvider<
          AsyncValue<Challenge?>,
          Challenge?,
          FutureOr<Challenge?>
        >
    with $FutureModifier<Challenge?>, $FutureProvider<Challenge?> {
  /// Weekly spotlight challenge for the user's archetype
  WeeklySpotlightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklySpotlightProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklySpotlightHash();

  @$internal
  @override
  $FutureProviderElement<Challenge?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Challenge?> create(Ref ref) {
    return weeklySpotlight(ref);
  }
}

String _$weeklySpotlightHash() => r'91a996098665d3b922cdf5833cc53226d43d3eef';

/// Daily quest for the user's archetype

@ProviderFor(dailyQuest)
final dailyQuestProvider = DailyQuestProvider._();

/// Daily quest for the user's archetype

final class DailyQuestProvider
    extends
        $FunctionalProvider<
          AsyncValue<Challenge?>,
          Challenge?,
          FutureOr<Challenge?>
        >
    with $FutureModifier<Challenge?>, $FutureProvider<Challenge?> {
  /// Daily quest for the user's archetype
  DailyQuestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyQuestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyQuestHash();

  @$internal
  @override
  $FutureProviderElement<Challenge?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Challenge?> create(Ref ref) {
    return dailyQuest(ref);
  }
}

String _$dailyQuestHash() => r'5a4870b7050dd88f9122ce1cf34679c473ca6125';
