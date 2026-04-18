// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Avatar state controller.
///
/// Manages avatar archetype and evolution phase. Skin tone and hairstyle
/// selection is no longer part of the rendering pipeline — the avatar is
/// fully defined by archetype and evolution phase in the silhouette-reveal model.

@ProviderFor(AvatarController)
final avatarControllerProvider = AvatarControllerProvider._();

/// Avatar state controller.
///
/// Manages avatar archetype and evolution phase. Skin tone and hairstyle
/// selection is no longer part of the rendering pipeline — the avatar is
/// fully defined by archetype and evolution phase in the silhouette-reveal model.
final class AvatarControllerProvider
    extends $NotifierProvider<AvatarController, AvatarState> {
  /// Avatar state controller.
  ///
  /// Manages avatar archetype and evolution phase. Skin tone and hairstyle
  /// selection is no longer part of the rendering pipeline — the avatar is
  /// fully defined by archetype and evolution phase in the silhouette-reveal model.
  AvatarControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarControllerHash();

  @$internal
  @override
  AvatarController create() => AvatarController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarState>(value),
    );
  }
}

String _$avatarControllerHash() => r'adf837aef1e12389b22c0479cab8d2dc832d0bed';

/// Avatar state controller.
///
/// Manages avatar archetype and evolution phase. Skin tone and hairstyle
/// selection is no longer part of the rendering pipeline — the avatar is
/// fully defined by archetype and evolution phase in the silhouette-reveal model.

abstract class _$AvatarController extends $Notifier<AvatarState> {
  AvatarState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AvatarState, AvatarState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AvatarState, AvatarState>,
              AvatarState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
