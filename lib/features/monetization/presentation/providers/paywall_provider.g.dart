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

String _$paywallControllerHash() => r'fd1ae22db66eddf73fb4a85bf8f1be4b5d7c3408';

abstract class _$PaywallController extends $Notifier<PaywallState> {
  PaywallState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PaywallState, PaywallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaywallState, PaywallState>,
              PaywallState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
