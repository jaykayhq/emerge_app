// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable Firebase Functions handle — tests override this with a mock
/// instead of touching the live `FirebaseFunctions.instance`.

@ProviderFor(firebaseFunctions)
final firebaseFunctionsProvider = FirebaseFunctionsProvider._();

/// Injectable Firebase Functions handle — tests override this with a mock
/// instead of touching the live `FirebaseFunctions.instance`.

final class FirebaseFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions,
          FirebaseFunctions,
          FirebaseFunctions
        >
    with $Provider<FirebaseFunctions> {
  /// Injectable Firebase Functions handle — tests override this with a mock
  /// instead of touching the live `FirebaseFunctions.instance`.
  FirebaseFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFunctionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions create(Ref ref) {
    return firebaseFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$firebaseFunctionsHash() => r'd93861c0944a5de507eaed64d4c4ecf0b90ae818';

/// Generates single-use creator invite codes via the
/// `generateCreatorInviteCode` callable (server-verified creator, 10-code
/// outstanding cap, 7-day expiry). State holds the last generated code
/// (null until the first successful generation) so reopening the dialog
/// doesn't burn another code.

@ProviderFor(CreatorInviteController)
final creatorInviteControllerProvider = CreatorInviteControllerProvider._();

/// Generates single-use creator invite codes via the
/// `generateCreatorInviteCode` callable (server-verified creator, 10-code
/// outstanding cap, 7-day expiry). State holds the last generated code
/// (null until the first successful generation) so reopening the dialog
/// doesn't burn another code.
final class CreatorInviteControllerProvider
    extends $NotifierProvider<CreatorInviteController, String?> {
  /// Generates single-use creator invite codes via the
  /// `generateCreatorInviteCode` callable (server-verified creator, 10-code
  /// outstanding cap, 7-day expiry). State holds the last generated code
  /// (null until the first successful generation) so reopening the dialog
  /// doesn't burn another code.
  CreatorInviteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorInviteControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorInviteControllerHash();

  @$internal
  @override
  CreatorInviteController create() => CreatorInviteController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$creatorInviteControllerHash() =>
    r'c9382eebb1a3cca30851a66a50fc28bdf7d2ae49';

/// Generates single-use creator invite codes via the
/// `generateCreatorInviteCode` callable (server-verified creator, 10-code
/// outstanding cap, 7-day expiry). State holds the last generated code
/// (null until the first successful generation) so reopening the dialog
/// doesn't burn another code.

abstract class _$CreatorInviteController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
