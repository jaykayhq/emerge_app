// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(monetizationRepository)
final monetizationRepositoryProvider = MonetizationRepositoryProvider._();

final class MonetizationRepositoryProvider
    extends
        $FunctionalProvider<
          MonetizationRepository,
          MonetizationRepository,
          MonetizationRepository
        >
    with $Provider<MonetizationRepository> {
  MonetizationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monetizationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monetizationRepositoryHash();

  @$internal
  @override
  $ProviderElement<MonetizationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MonetizationRepository create(Ref ref) {
    return monetizationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MonetizationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MonetizationRepository>(value),
    );
  }
}

String _$monetizationRepositoryHash() =>
    r'f79b9a3db446c65f59a8406009b481c1743b0d7e';

@ProviderFor(IsPremium)
final isPremiumProvider = IsPremiumProvider._();

final class IsPremiumProvider extends $AsyncNotifierProvider<IsPremium, bool> {
  IsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPremiumProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPremiumHash();

  @$internal
  @override
  IsPremium create() => IsPremium();
}

String _$isPremiumHash() => r'20f7306a8e8b896ff5d018b4ecb0647b34318687';

abstract class _$IsPremium extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether a daily login bonus is available to claim for a premium user.
///
/// Returns false for free users and for premium users who already claimed
/// today. Claiming persists the claim date to [SharedPreferences] so the
/// bonus is one-per-calendar-day.

@ProviderFor(DailyLoginBonus)
final dailyLoginBonusProvider = DailyLoginBonusProvider._();

/// Whether a daily login bonus is available to claim for a premium user.
///
/// Returns false for free users and for premium users who already claimed
/// today. Claiming persists the claim date to [SharedPreferences] so the
/// bonus is one-per-calendar-day.
final class DailyLoginBonusProvider
    extends $AsyncNotifierProvider<DailyLoginBonus, bool> {
  /// Whether a daily login bonus is available to claim for a premium user.
  ///
  /// Returns false for free users and for premium users who already claimed
  /// today. Claiming persists the claim date to [SharedPreferences] so the
  /// bonus is one-per-calendar-day.
  DailyLoginBonusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyLoginBonusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyLoginBonusHash();

  @$internal
  @override
  DailyLoginBonus create() => DailyLoginBonus();
}

String _$dailyLoginBonusHash() => r'2194c9d94dda996a41d7aeb5a81c8c16c1fe5c85';

/// Whether a daily login bonus is available to claim for a premium user.
///
/// Returns false for free users and for premium users who already claimed
/// today. Claiming persists the claim date to [SharedPreferences] so the
/// bonus is one-per-calendar-day.

abstract class _$DailyLoginBonus extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
