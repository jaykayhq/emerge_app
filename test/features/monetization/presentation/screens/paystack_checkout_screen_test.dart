import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/monetization/data/repositories/paystack_payment_repository.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paystack_checkout_screen.dart';

class MockPaystackPaymentRepository extends Mock
    implements PaystackPaymentRepository {}

Widget createTest(MockPaystackPaymentRepository mock) {
  return ProviderScope(
    overrides: [
      paystackPaymentRepositoryProvider.overrideWith((ref) => mock),
    ],
    child: const MaterialApp(
      home: PaystackCheckoutScreen(
        amount: 10.0,
        email: 'test@example.com',
        identityType: 'premium',
      ),
    ),
  );
}

void main() {
  testWidgets('renders loading state', (tester) async {
    final mock = MockPaystackPaymentRepository();
    final completer = Completer<String>();
    when(
      () => mock.initializeTransaction(
        amount: any(named: 'amount'),
        email: any(named: 'email'),
        identityType: any(named: 'identityType'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createTest(mock));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders error state on failure', (tester) async {
    final mock = MockPaystackPaymentRepository();
    when(
      () => mock.initializeTransaction(
        amount: any(named: 'amount'),
        email: any(named: 'email'),
        identityType: any(named: 'identityType'),
      ),
    ).thenThrow(Exception('Failed'));

    await tester.pumpWidget(createTest(mock));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Failed to initialize payment. Please try again.'),
        findsOneWidget);
  });
}
