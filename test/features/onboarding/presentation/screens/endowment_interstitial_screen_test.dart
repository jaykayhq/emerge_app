import 'package:emerge_app/features/onboarding/presentation/screens/endowment_interstitial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows anonymous welcome and starter items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const EndowmentInterstitialScreen(),
      ),
    );

    expect(find.text('✨ Welcome, Future You'), findsOneWidget);
    expect(find.text('Starter habit pack'), findsOneWidget);
    expect(find.text('Archetype tribe'), findsOneWidget);
    expect(find.text('Your world map'), findsOneWidget);
    expect(find.text('CLAIM YOUR WORLD →'), findsOneWidget);
    expect(find.text('Already a member?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
