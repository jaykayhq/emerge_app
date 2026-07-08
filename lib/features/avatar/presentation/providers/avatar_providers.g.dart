// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of avatar data for a given user from Firestore.

@ProviderFor(avatarData)
final avatarDataProvider = AvatarDataFamily._();

/// Stream of avatar data for a given user from Firestore.

final class AvatarDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<AvatarData>,
          AvatarData,
          Stream<AvatarData>
        >
    with $FutureModifier<AvatarData>, $StreamProvider<AvatarData> {
  /// Stream of avatar data for a given user from Firestore.
  AvatarDataProvider._({
    required AvatarDataFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'avatarDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$avatarDataHash();

  @override
  String toString() {
    return r'avatarDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<AvatarData> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AvatarData> create(Ref ref) {
    final argument = this.argument as String;
    return avatarData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvatarDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$avatarDataHash() => r'c725e6ace5b17fc7736f579c11980deb3d06f2dc';

/// Stream of avatar data for a given user from Firestore.

final class AvatarDataFamily extends $Family
    with $FunctionalFamilyOverride<Stream<AvatarData>, String> {
  AvatarDataFamily._()
    : super(
        retry: null,
        name: r'avatarDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream of avatar data for a given user from Firestore.

  AvatarDataProvider call(String userId) =>
      AvatarDataProvider._(argument: userId, from: this);

  @override
  String toString() => r'avatarDataProvider';
}

/// Local state for unsaved customization changes (edit in customizer
/// before saving to Firestore).

@ProviderFor(AvatarCustomizationNotifier)
final avatarCustomizationProvider = AvatarCustomizationNotifierProvider._();

/// Local state for unsaved customization changes (edit in customizer
/// before saving to Firestore).
final class AvatarCustomizationNotifierProvider
    extends $NotifierProvider<AvatarCustomizationNotifier, AvatarData> {
  /// Local state for unsaved customization changes (edit in customizer
  /// before saving to Firestore).
  AvatarCustomizationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarCustomizationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarCustomizationNotifierHash();

  @$internal
  @override
  AvatarCustomizationNotifier create() => AvatarCustomizationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarData>(value),
    );
  }
}

String _$avatarCustomizationNotifierHash() =>
    r'955e161532cd506cff0e789a6bca63c3e7b1a2fd';

/// Local state for unsaved customization changes (edit in customizer
/// before saving to Firestore).

abstract class _$AvatarCustomizationNotifier extends $Notifier<AvatarData> {
  AvatarData build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AvatarData, AvatarData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AvatarData, AvatarData>,
              AvatarData,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
