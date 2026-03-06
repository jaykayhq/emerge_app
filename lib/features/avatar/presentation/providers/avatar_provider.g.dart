// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Avatar state controller for managing avatar configuration.
///
/// Handles avatar customization (archetype, skin tone, hairstyle) and
/// evolution state updates. Each config change maps to a different
/// pre-generated character image.

@ProviderFor(AvatarController)
final avatarControllerProvider = AvatarControllerProvider._();

/// Avatar state controller for managing avatar configuration.
///
/// Handles avatar customization (archetype, skin tone, hairstyle) and
/// evolution state updates. Each config change maps to a different
/// pre-generated character image.
final class AvatarControllerProvider
    extends $NotifierProvider<AvatarController, AvatarState> {
  /// Avatar state controller for managing avatar configuration.
  ///
  /// Handles avatar customization (archetype, skin tone, hairstyle) and
  /// evolution state updates. Each config change maps to a different
  /// pre-generated character image.
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

String _$avatarControllerHash() => r'64c82e0326b44d778bf4935fcd9dc1eb4f002386';

/// Avatar state controller for managing avatar configuration.
///
/// Handles avatar customization (archetype, skin tone, hairstyle) and
/// evolution state updates. Each config change maps to a different
/// pre-generated character image.

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
