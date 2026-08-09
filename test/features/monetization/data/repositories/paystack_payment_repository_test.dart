import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/monetization/data/repositories/paystack_payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late PaystackPaymentRepository repo;

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    repo = PaystackPaymentRepository(functions);
  });

  test('initializeTransaction forwards callbackUrl to the callable', () async {
    when(() => functions.httpsCallable('initializePaystackTransaction'))
        .thenReturn(callable);
    final mockResult = MockHttpsCallableResult();
    when(() => mockResult.data).thenReturn({
      'authorization_url': 'https://checkout.paystack.com/abc',
      'access_code': 'x',
      'reference': 'ref1',
    });
    when(() => callable.call<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => mockResult);

    await repo.initializeTransaction(
      amount: 15000,
      email: 'a@b.com',
      identityType: 'yearly',
      callbackUrl: 'https://emerge.web.app/order-confirmed',
    );

    final payload = verify(
            () => callable.call<Map<String, dynamic>>(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(payload['callbackUrl'], 'https://emerge.web.app/order-confirmed');
    expect(payload['amount'], 1500000); // kobo conversion unchanged
  });

  test('omits callbackUrl from the payload when not provided', () async {
    when(() => functions.httpsCallable('initializePaystackTransaction'))
        .thenReturn(callable);
    final mockResult = MockHttpsCallableResult();
    when(() => mockResult.data).thenReturn({
      'authorization_url': 'https://checkout.paystack.com/abc',
      'access_code': 'x',
      'reference': 'ref1',
    });
    when(() => callable.call<Map<String, dynamic>>(any()))
        .thenAnswer((_) async => mockResult);

    await repo.initializeTransaction(
      amount: 15000,
      email: 'a@b.com',
      identityType: 'yearly',
    );

    final payload = verify(
            () => callable.call<Map<String, dynamic>>(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(payload.containsKey('callbackUrl'), isFalse);
  });
}
