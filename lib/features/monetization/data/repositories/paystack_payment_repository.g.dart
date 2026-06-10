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
    r'cb48f883fe1fdf853d7a7913d8099414c1e34259';
