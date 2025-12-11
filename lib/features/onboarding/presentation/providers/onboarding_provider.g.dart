// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localSettingsRepositoryHash() =>
    r'4e4bc98b8dbd6be474b714b36bf182061aad78a2';

/// See also [localSettingsRepository].
@ProviderFor(localSettingsRepository)
final localSettingsRepositoryProvider =
    Provider<LocalSettingsRepository>.internal(
      localSettingsRepository,
      name: r'localSettingsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localSettingsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalSettingsRepositoryRef = ProviderRef<LocalSettingsRepository>;
String _$activeMilestonesHash() => r'a2669e8f297e5891a419dd87db6d5e9823bae308';

/// Provider that returns the currently active onboarding milestones
/// Based on user's onboarding progress (0-3)
/// Returns empty list if onboarding is complete or if user profile isn't loaded
///
/// Copied from [activeMilestones].
@ProviderFor(activeMilestones)
final activeMilestonesProvider =
    AutoDisposeProvider<List<OnboardingMilestone>>.internal(
      activeMilestones,
      name: r'activeMilestonesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeMilestonesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveMilestonesRef = AutoDisposeProviderRef<List<OnboardingMilestone>>;
String _$onboardingControllerHash() =>
    r'e05c8d42d56e10e82af0dcde5faef2ce30322639';

/// See also [OnboardingController].
@ProviderFor(OnboardingController)
final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>.internal(
      OnboardingController.new,
      name: r'onboardingControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onboardingControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingController = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
