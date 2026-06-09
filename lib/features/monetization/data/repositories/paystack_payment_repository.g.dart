// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paystack_payment_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paystackPaymentRepository)
final paystackPaymentRepositoryProvider = PaystackPaymentRepositoryProvider._();

final class PaystackPaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaystackPaymentRepository,
          PaystackPaymentRepository,
          PaystackPaymentRepository
        >
    with $Provider<PaystackPaymentRepository> {
  PaystackPaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paystackPaymentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paystackPaymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaystackPaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaystackPaymentRepository create(Ref ref) {
    return paystackPaymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaystackPaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaystackPaymentRepository>(value),
    );
  }
}

String _$paystackPaymentRepositoryHash() =>
    r'2dde3b9a78ddc9e94678d2c2f7cf5cf69a13c9fb';
