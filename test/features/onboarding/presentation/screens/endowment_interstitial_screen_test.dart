import 'package:emerge_app/features/onboarding/presentation/screens/endowment_interstitial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows welcome message and starter items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EndowmentInterstitialScreen(userName: 'Alex'),
      ),
    );

    expect(find.text('Welcome, Alex'), findsWidgets);
    expect(find.text('Starter habit pack'), findsOneWidget);
    expect(find.text('Archetype tribe'), findsOneWidget);
    expect(find.text('Your world map'), findsOneWidget);
    expect(find.text('BEGIN FORGING →'), findsOneWidget);
  });
}
