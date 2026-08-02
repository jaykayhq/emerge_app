// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manage_premium_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(managePremiumService)
final managePremiumServiceProvider = ManagePremiumServiceProvider._();

final class ManagePremiumServiceProvider
    extends
        $FunctionalProvider<
          ManagePremiumService,
          ManagePremiumService,
          ManagePremiumService
        >
    with $Provider<ManagePremiumService> {
  ManagePremiumServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'managePremiumServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$managePremiumServiceHash();

  @$internal
  @override
  $ProviderElement<ManagePremiumService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManagePremiumService create(Ref ref) {
    return managePremiumService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManagePremiumService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManagePremiumService>(value),
    );
  }
}

String _$managePremiumServiceHash() =>
    r'95c21d5a81e7044d3b5ed7e870e25f9810a96271';
