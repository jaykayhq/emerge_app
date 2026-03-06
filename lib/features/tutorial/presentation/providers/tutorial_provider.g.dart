// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing tutorial state

@ProviderFor(TutorialNotifier)
final tutorialProvider = TutorialNotifierProvider._();

/// Provider for managing tutorial state
final class TutorialNotifierProvider
    extends $NotifierProvider<TutorialNotifier, TutorialState> {
  /// Provider for managing tutorial state
  TutorialNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialNotifierHash();

  @$internal
  @override
  TutorialNotifier create() => TutorialNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorialState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TutorialState>(value),
    );
  }
}

String _$tutorialNotifierHash() => r'bd358413a68394a49a71627a538ced1b190ed87d';

/// Provider for managing tutorial state

abstract class _$TutorialNotifier extends $Notifier<TutorialState> {
  TutorialState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TutorialState, TutorialState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TutorialState, TutorialState>,
              TutorialState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
