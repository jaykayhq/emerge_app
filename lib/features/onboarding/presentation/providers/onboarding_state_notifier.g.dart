// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isOnboardingActiveHash() =>
    r'df48960662433fe9e260555a2db4f215901765e7';

/// Provider for checking if onboarding is active
///
/// Copied from [isOnboardingActive].
@ProviderFor(isOnboardingActive)
final isOnboardingActiveProvider = AutoDisposeProvider<bool>.internal(
  isOnboardingActive,
  name: r'isOnboardingActiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnboardingActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsOnboardingActiveRef = AutoDisposeProviderRef<bool>;
String _$onboardingProgressHash() =>
    r'a4ae9eb746b1836bfe98dba90de9122fa441397f';

/// Provider for onboarding progress percentage
///
/// Copied from [onboardingProgress].
@ProviderFor(onboardingProgress)
final onboardingProgressProvider = AutoDisposeProvider<double>.internal(
  onboardingProgress,
  name: r'onboardingProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingProgressRef = AutoDisposeProviderRef<double>;
String _$enhancedOnboardingNotifierHash() =>
    r'032dfda0daaf3169bfdaa70e53b5c09a5a9b6269';

/// Enhanced Onboarding State Notifier with dashboard sync
///
/// Copied from [EnhancedOnboardingNotifier].
@ProviderFor(EnhancedOnboardingNotifier)
final enhancedOnboardingNotifierProvider =
    NotifierProvider<
      EnhancedOnboardingNotifier,
      EnhancedOnboardingState
    >.internal(
      EnhancedOnboardingNotifier.new,
      name: r'enhancedOnboardingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$enhancedOnboardingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EnhancedOnboardingNotifier = Notifier<EnhancedOnboardingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
