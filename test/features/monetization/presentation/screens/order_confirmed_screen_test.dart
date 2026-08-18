import 'package:emerge_app/features/monetization/presentation/screens/order_confirmed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders confirmation with the reference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OrderConfirmedScreen(reference: 'PSK_abc123')),
    );

    expect(find.text('Order complete'), findsOneWidget);
    expect(find.textContaining('PSK_abc123'), findsOneWidget);
    expect(find.text('Start exploring'), findsOneWidget);
  });

  testWidgets('renders fallback copy when reference is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OrderConfirmedScreen(reference: null)),
    );

    expect(find.text('Order complete'), findsOneWidget);
    expect(find.textContaining('PSK'), findsNothing);
    expect(find.textContaining('Payment received'), findsOneWidget);
  });
}
