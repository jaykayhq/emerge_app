// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PaywallController)
final paywallControllerProvider = PaywallControllerProvider._();

final class PaywallControllerProvider
    extends $NotifierProvider<PaywallController, PaywallState> {
  PaywallControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paywallControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paywallControllerHash();

  @$internal
  @override
  PaywallController create() => PaywallController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaywallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaywallState>(value),
    );
  }
}

String _$paywallControllerHash() => r'1a4a5a28afadefca56c915db3f39e9ccb5cddc9d';

abstract class _$PaywallController extends $Notifier<PaywallState> {
  PaywallState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PaywallState, PaywallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaywallState, PaywallState>,
              PaywallState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
