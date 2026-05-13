// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gamificationService)
final gamificationServiceProvider = GamificationServiceProvider._();

final class GamificationServiceProvider
    extends
        $FunctionalProvider<
          GamificationService,
          GamificationService,
          GamificationService
        >
    with $Provider<GamificationService> {
  GamificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamificationServiceHash();

  @$internal
  @override
  $ProviderElement<GamificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GamificationService create(Ref ref) {
    return gamificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GamificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GamificationService>(value),
    );
  }
}

String _$gamificationServiceHash() =>
    r'9718118359cbb8090436b42289f3282a8f087076';

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

String _$userProfileHash() => r'7835cb3367f7cdf6dba4211bddc324e955fb8aa0';
