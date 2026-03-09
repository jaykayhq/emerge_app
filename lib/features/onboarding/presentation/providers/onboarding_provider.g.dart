// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localSettingsRepository)
final localSettingsRepositoryProvider = LocalSettingsRepositoryProvider._();

final class LocalSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          LocalSettingsRepository,
          LocalSettingsRepository,
          LocalSettingsRepository
        >
    with $Provider<LocalSettingsRepository> {
  LocalSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalSettingsRepository create(Ref ref) {
    return localSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalSettingsRepository>(value),
    );
  }
}

String _$localSettingsRepositoryHash() =>
    r'4e4bc98b8dbd6be474b714b36bf182061aad78a2';

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

final class OnboardingControllerProvider
    extends $NotifierProvider<OnboardingController, bool> {
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'086aa06fde650b4e084c483816b2184cab0c1f4e';

abstract class _$OnboardingController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(OnboardingStateController)
final onboardingStateControllerProvider = OnboardingStateControllerProvider._();

final class OnboardingStateControllerProvider
    extends $NotifierProvider<OnboardingStateController, OnboardingState> {
  OnboardingStateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStateControllerHash();

  @$internal
  @override
  OnboardingStateController create() => OnboardingStateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingState>(value),
    );
  }
}

String _$onboardingStateControllerHash() =>
    r'a342fb44e3cf19f6c7fae12ab7aea3f8c31288c8';

abstract class _$OnboardingStateController extends $Notifier<OnboardingState> {
  OnboardingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OnboardingState, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingState, OnboardingState>,
              OnboardingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider that returns the currently active onboarding milestones
/// Based on user's onboarding progress (0-5)
/// Returns empty list if onboarding is complete or if user profile isn't loaded

@ProviderFor(activeMilestones)
final activeMilestonesProvider = ActiveMilestonesProvider._();

/// Provider that returns the currently active onboarding milestones
/// Based on user's onboarding progress (0-5)
/// Returns empty list if onboarding is complete or if user profile isn't loaded

final class ActiveMilestonesProvider
    extends
        $FunctionalProvider<
          List<OnboardingMilestone>,
          List<OnboardingMilestone>,
          List<OnboardingMilestone>
        >
    with $Provider<List<OnboardingMilestone>> {
  /// Provider that returns the currently active onboarding milestones
  /// Based on user's onboarding progress (0-5)
  /// Returns empty list if onboarding is complete or if user profile isn't loaded
  ActiveMilestonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeMilestonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeMilestonesHash();

  @$internal
  @override
  $ProviderElement<List<OnboardingMilestone>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<OnboardingMilestone> create(Ref ref) {
    return activeMilestones(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OnboardingMilestone> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OnboardingMilestone>>(value),
    );
  }
}

String _$activeMilestonesHash() => r'5d623f433b7841b8e790dcab9e7dbb11e7709344';
