// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'future_self_studio_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to track recovery animation state

@ProviderFor(RecoveryAnimating)
final recoveryAnimatingProvider = RecoveryAnimatingProvider._();

/// Provider to track recovery animation state
final class RecoveryAnimatingProvider
    extends $NotifierProvider<RecoveryAnimating, bool> {
  /// Provider to track recovery animation state
  RecoveryAnimatingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recoveryAnimatingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recoveryAnimatingHash();

  @$internal
  @override
  RecoveryAnimating create() => RecoveryAnimating();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$recoveryAnimatingHash() => r'99f43003f59abeea1c4748255ee714aa9795e14b';

/// Provider to track recovery animation state

abstract class _$RecoveryAnimating extends $Notifier<bool> {
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

/// Provider to enable the new 2D isometric avatar renderer
/// Set to true to use the new AvatarRenderer instead of EvolvingSilhouetteWidget

@ProviderFor(UseNewAvatarRenderer)
final useNewAvatarRendererProvider = UseNewAvatarRendererProvider._();

/// Provider to enable the new 2D isometric avatar renderer
/// Set to true to use the new AvatarRenderer instead of EvolvingSilhouetteWidget
final class UseNewAvatarRendererProvider
    extends $NotifierProvider<UseNewAvatarRenderer, bool> {
  /// Provider to enable the new 2D isometric avatar renderer
  /// Set to true to use the new AvatarRenderer instead of EvolvingSilhouetteWidget
  UseNewAvatarRendererProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'useNewAvatarRendererProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$useNewAvatarRendererHash();

  @$internal
  @override
  UseNewAvatarRenderer create() => UseNewAvatarRenderer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$useNewAvatarRendererHash() =>
    r'c0db6f64a79b2e700560efd7fec8e59e475b6ef9';

/// Provider to enable the new 2D isometric avatar renderer
/// Set to true to use the new AvatarRenderer instead of EvolvingSilhouetteWidget

abstract class _$UseNewAvatarRenderer extends $Notifier<bool> {
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
