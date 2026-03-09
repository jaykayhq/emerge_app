// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enhanced Onboarding State Notifier with dashboard sync

@ProviderFor(EnhancedOnboardingNotifier)
final enhancedOnboardingProvider = EnhancedOnboardingNotifierProvider._();

/// Enhanced Onboarding State Notifier with dashboard sync
final class EnhancedOnboardingNotifierProvider
    extends
        $NotifierProvider<EnhancedOnboardingNotifier, EnhancedOnboardingState> {
  /// Enhanced Onboarding State Notifier with dashboard sync
  EnhancedOnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enhancedOnboardingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enhancedOnboardingNotifierHash();

  @$internal
  @override
  EnhancedOnboardingNotifier create() => EnhancedOnboardingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnhancedOnboardingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnhancedOnboardingState>(value),
    );
  }
}

String _$enhancedOnboardingNotifierHash() =>
    r'7a41e4d8813042bfa6cdcf25c1d0d215fe5725e7';

/// Enhanced Onboarding State Notifier with dashboard sync

abstract class _$EnhancedOnboardingNotifier
    extends $Notifier<EnhancedOnboardingState> {
  EnhancedOnboardingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<EnhancedOnboardingState, EnhancedOnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EnhancedOnboardingState, EnhancedOnboardingState>,
              EnhancedOnboardingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for checking if onboarding is active

@ProviderFor(isOnboardingActive)
final isOnboardingActiveProvider = IsOnboardingActiveProvider._();

/// Provider for checking if onboarding is active

final class IsOnboardingActiveProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if onboarding is active
  IsOnboardingActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnboardingActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnboardingActiveHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isOnboardingActive(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isOnboardingActiveHash() =>
    r'c3b567cb45e38d30167d144a62161236831f145c';

/// Provider for onboarding progress percentage

@ProviderFor(onboardingProgress)
final onboardingProgressProvider = OnboardingProgressProvider._();

/// Provider for onboarding progress percentage

final class OnboardingProgressProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Provider for onboarding progress percentage
  OnboardingProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingProgressHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return onboardingProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$onboardingProgressHash() =>
    r'bed2c2fa03d6b39c207dc430c1c27372cb1f4f8c';
