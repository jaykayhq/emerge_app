// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_defaults_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes smart defaults for habit creation based on existing habits
/// and the user's archetype. Auto-disposes when no longer watched.

@ProviderFor(smartDefaults)
final smartDefaultsProvider = SmartDefaultsProvider._();

/// Computes smart defaults for habit creation based on existing habits
/// and the user's archetype. Auto-disposes when no longer watched.

final class SmartDefaultsProvider
    extends $FunctionalProvider<SmartDefaults, SmartDefaults, SmartDefaults>
    with $Provider<SmartDefaults> {
  /// Computes smart defaults for habit creation based on existing habits
  /// and the user's archetype. Auto-disposes when no longer watched.
  SmartDefaultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartDefaultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartDefaultsHash();

  @$internal
  @override
  $ProviderElement<SmartDefaults> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SmartDefaults create(Ref ref) {
    return smartDefaults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartDefaults value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartDefaults>(value),
    );
  }
}

String _$smartDefaultsHash() => r'07bfd36289ff7cbbb815236a68498cc29ab9f72b';
