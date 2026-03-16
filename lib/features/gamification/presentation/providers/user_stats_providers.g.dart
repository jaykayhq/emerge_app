// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Split provider that only watches avatarStats field
/// Prevents full profile rebuilds when only avatar stats change

@ProviderFor(userAvatarStats)
final userAvatarStatsProvider = UserAvatarStatsProvider._();

/// Split provider that only watches avatarStats field
/// Prevents full profile rebuilds when only avatar stats change

final class UserAvatarStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserAvatarStats>,
          UserAvatarStats,
          Stream<UserAvatarStats>
        >
    with $FutureModifier<UserAvatarStats>, $StreamProvider<UserAvatarStats> {
  /// Split provider that only watches avatarStats field
  /// Prevents full profile rebuilds when only avatar stats change
  UserAvatarStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userAvatarStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userAvatarStatsHash();

  @$internal
  @override
  $StreamProviderElement<UserAvatarStats> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserAvatarStats> create(Ref ref) {
    return userAvatarStats(ref);
  }
}

String _$userAvatarStatsHash() => r'58373bf583e0d8b2be451bbe25b49340a2c2f934';

/// Split provider that only watches level field
/// Useful for UI elements that only need level info

@ProviderFor(userLevel)
final userLevelProvider = UserLevelProvider._();

/// Split provider that only watches level field
/// Useful for UI elements that only need level info

final class UserLevelProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Split provider that only watches level field
  /// Useful for UI elements that only need level info
  UserLevelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLevelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLevelHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return userLevel(ref);
  }
}

String _$userLevelHash() => r'57baaf655df743db4a6506a6c4811fb3f852a956';

/// Split provider that only watches streak field
/// Useful for streak-specific UI components

@ProviderFor(userStreak)
final userStreakProvider = UserStreakProvider._();

/// Split provider that only watches streak field
/// Useful for streak-specific UI components

final class UserStreakProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Split provider that only watches streak field
  /// Useful for streak-specific UI components
  UserStreakProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStreakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStreakHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return userStreak(ref);
  }
}

String _$userStreakHash() => r'2223d4316268b01252f58e30d851d71d48217977';
