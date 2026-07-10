// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreatorOnboardingDraftController)
final creatorOnboardingDraftControllerProvider =
    CreatorOnboardingDraftControllerProvider._();

final class CreatorOnboardingDraftControllerProvider
    extends
        $NotifierProvider<
          CreatorOnboardingDraftController,
          CreatorOnboardingDraft
        > {
  CreatorOnboardingDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorOnboardingDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorOnboardingDraftControllerHash();

  @$internal
  @override
  CreatorOnboardingDraftController create() =>
      CreatorOnboardingDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatorOnboardingDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatorOnboardingDraft>(value),
    );
  }
}

String _$creatorOnboardingDraftControllerHash() =>
    r'9c79f16f59e8410ad67228d26396e259f3e50596';

abstract class _$CreatorOnboardingDraftController
    extends $Notifier<CreatorOnboardingDraft> {
  CreatorOnboardingDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CreatorOnboardingDraft, CreatorOnboardingDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreatorOnboardingDraft, CreatorOnboardingDraft>,
              CreatorOnboardingDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Persists the current draft to `creator_profiles/{uid}` and updates
/// `creatorOnboardingProgress` so the router stops redirecting.
///
/// Safe to call multiple times (idempotent merge). After the third step
/// (reveal screen) it also calls the setUserRole Cloud Function with
/// `creatorOnboardingCompletedAt` so the dashboard is reachable.

@ProviderFor(saveCreatorOnboardingProgress)
final saveCreatorOnboardingProgressProvider =
    SaveCreatorOnboardingProgressFamily._();

/// Persists the current draft to `creator_profiles/{uid}` and updates
/// `creatorOnboardingProgress` so the router stops redirecting.
///
/// Safe to call multiple times (idempotent merge). After the third step
/// (reveal screen) it also calls the setUserRole Cloud Function with
/// `creatorOnboardingCompletedAt` so the dashboard is reachable.

final class SaveCreatorOnboardingProgressProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Persists the current draft to `creator_profiles/{uid}` and updates
  /// `creatorOnboardingProgress` so the router stops redirecting.
  ///
  /// Safe to call multiple times (idempotent merge). After the third step
  /// (reveal screen) it also calls the setUserRole Cloud Function with
  /// `creatorOnboardingCompletedAt` so the dashboard is reachable.
  SaveCreatorOnboardingProgressProvider._({
    required SaveCreatorOnboardingProgressFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'saveCreatorOnboardingProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saveCreatorOnboardingProgressHash();

  @override
  String toString() {
    return r'saveCreatorOnboardingProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as int;
    return saveCreatorOnboardingProgress(ref, progress: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveCreatorOnboardingProgressProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveCreatorOnboardingProgressHash() =>
    r'9b0adc6622a9262f4411f71db4923263c40f0c1f';

/// Persists the current draft to `creator_profiles/{uid}` and updates
/// `creatorOnboardingProgress` so the router stops redirecting.
///
/// Safe to call multiple times (idempotent merge). After the third step
/// (reveal screen) it also calls the setUserRole Cloud Function with
/// `creatorOnboardingCompletedAt` so the dashboard is reachable.

final class SaveCreatorOnboardingProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, int> {
  SaveCreatorOnboardingProgressFamily._()
    : super(
        retry: null,
        name: r'saveCreatorOnboardingProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Persists the current draft to `creator_profiles/{uid}` and updates
  /// `creatorOnboardingProgress` so the router stops redirecting.
  ///
  /// Safe to call multiple times (idempotent merge). After the third step
  /// (reveal screen) it also calls the setUserRole Cloud Function with
  /// `creatorOnboardingCompletedAt` so the dashboard is reachable.

  SaveCreatorOnboardingProgressProvider call({required int progress}) =>
      SaveCreatorOnboardingProgressProvider._(argument: progress, from: this);

  @override
  String toString() => r'saveCreatorOnboardingProgressProvider';
}
