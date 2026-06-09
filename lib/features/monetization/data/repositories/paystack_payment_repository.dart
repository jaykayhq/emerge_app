import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logger/logger.dart';

part 'paystack_payment_repository.g.dart';

/// Repository responsible for initializing Paystack transactions
/// via our secure Firebase Cloud Functions.
class PaystackPaymentRepository {
  final FirebaseFunctions _functions;
  final Logger _logger;

  PaystackPaymentRepository(this._functions) : _logger = Logger();

  /// Initializes a Paystack transaction and returns the authorization URL.
  ///
  /// The cloud function handles the secret key and specifying the channels
  /// (apple_pay, google_pay, card) to ensure it's identity-first and secure.
  Future<String> initializeTransaction({
    required double amount,
    required String email,
    required String identityType,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'initializePaystackTransaction',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'amount': amount * 100, // Paystack uses kobo/cents
        'email': email,
        'metadata': {'identity_type': identityType},
      });

      final data = result.data;
      if (data.containsKey('authorization_url')) {
        return data['authorization_url'] as String;
      } else {
        throw Exception('Authorization URL not found in response');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize Paystack transaction',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

@riverpod
PaystackPaymentRepository paystackPaymentRepository(
  PaystackPaymentRepositoryRef ref,
) {
  return PaystackPaymentRepository(FirebaseFunctions.instance);
}
