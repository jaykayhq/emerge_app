// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gamificationRepository)
final gamificationRepositoryProvider = GamificationRepositoryProvider._();

final class GamificationRepositoryProvider
    extends
        $FunctionalProvider<
          GamificationRepository,
          GamificationRepository,
          GamificationRepository
        >
    with $Provider<GamificationRepository> {
  GamificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<GamificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamificationRepository create(Ref ref) {
    return gamificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamificationRepository>(value),
    );
  }
}

String _$gamificationRepositoryHash() =>
    r'c324b009ed20a6ed61cdad8e66b6bc8a1c383d70';

@ProviderFor(userStats)
final userStatsProvider = UserStatsProvider._();

final class UserStatsProvider
    extends
        $FunctionalProvider<AsyncValue<UserStats>, UserStats, Stream<UserStats>>
    with $FutureModifier<UserStats>, $StreamProvider<UserStats> {
  UserStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStatsHash();

  @$internal
  @override
  $StreamProviderElement<UserStats> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UserStats> create(Ref ref) {
    return userStats(ref);
  }
}

String _$userStatsHash() => r'5d444d55c52cb91b096d9b2b2833af1d81189ada';

@ProviderFor(userProfile)
final userProfileProvider = UserProfileProvider._();

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'b76c9a1d20452775b34f514b19d99a671aa18c7a';
