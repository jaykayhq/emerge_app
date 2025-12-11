// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gamificationRepositoryHash() =>
    r'c324b009ed20a6ed61cdad8e66b6bc8a1c383d70';

/// See also [gamificationRepository].
@ProviderFor(gamificationRepository)
final gamificationRepositoryProvider =
    Provider<GamificationRepository>.internal(
      gamificationRepository,
      name: r'gamificationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gamificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GamificationRepositoryRef = ProviderRef<GamificationRepository>;
String _$userStatsHash() => r'5d444d55c52cb91b096d9b2b2833af1d81189ada';

/// See also [userStats].
@ProviderFor(userStats)
final userStatsProvider = AutoDisposeStreamProvider<UserStats>.internal(
  userStats,
  name: r'userStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserStatsRef = AutoDisposeStreamProviderRef<UserStats>;
String _$userProfileHash() => r'b76c9a1d20452775b34f514b19d99a671aa18c7a';

/// See also [userProfile].
@ProviderFor(userProfile)
final userProfileProvider = AutoDisposeStreamProvider<UserProfile?>.internal(
  userProfile,
  name: r'userProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserProfileRef = AutoDisposeStreamProviderRef<UserProfile?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
