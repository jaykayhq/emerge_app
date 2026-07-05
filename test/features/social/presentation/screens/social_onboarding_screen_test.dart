import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/social_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SocialOnboardingScreen renders two options', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(home: SocialOnboardingScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('YOUR TRIBE AWAITS'), findsOneWidget);
    expect(find.text('ARCHETYPE COLLECTIVE'), findsOneWidget);
    expect(find.text('CREATOR CIRCLE'), findsOneWidget);
  });
}
