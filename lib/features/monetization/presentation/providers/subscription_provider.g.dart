// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(monetizationRepository)
final monetizationRepositoryProvider = MonetizationRepositoryProvider._();

final class MonetizationRepositoryProvider
    extends
        $FunctionalProvider<
          MonetizationRepository,
          MonetizationRepository,
          MonetizationRepository
        >
    with $Provider<MonetizationRepository> {
  MonetizationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monetizationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monetizationRepositoryHash();

  @$internal
  @override
  $ProviderElement<MonetizationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MonetizationRepository create(Ref ref) {
    return monetizationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MonetizationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MonetizationRepository>(value),
    );
  }
}

String _$monetizationRepositoryHash() =>
    r'f79b9a3db446c65f59a8406009b481c1743b0d7e';

@ProviderFor(IsPremium)
final isPremiumProvider = IsPremiumProvider._();

final class IsPremiumProvider extends $AsyncNotifierProvider<IsPremium, bool> {
  IsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPremiumProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPremiumHash();

  @$internal
  @override
  IsPremium create() => IsPremium();
}

String _$isPremiumHash() => r'de64ab857006fb1121caee606df69397b98c88f2';

abstract class _$IsPremium extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
