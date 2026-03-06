// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_mode_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IsFocusModeEnabled)
final isFocusModeEnabledProvider = IsFocusModeEnabledProvider._();

final class IsFocusModeEnabledProvider
    extends $NotifierProvider<IsFocusModeEnabled, bool> {
  IsFocusModeEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isFocusModeEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isFocusModeEnabledHash();

  @$internal
  @override
  IsFocusModeEnabled create() => IsFocusModeEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isFocusModeEnabledHash() =>
    r'6b90fc2dca889a7bad7371573eddef113e568eb8';

abstract class _$IsFocusModeEnabled extends $Notifier<bool> {
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
