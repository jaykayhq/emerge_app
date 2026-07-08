import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';
import '../../../../helpers/widget_test_utils.dart';

Widget _buildTest() {
  return createScreenUnderTest(
    screen: const IdentityStudioScreen(),
    overrides: [
      enhancedOnboardingProvider.overrideWithValue(
        const EnhancedOnboardingState(),
      ),
    ],
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders archetype carousel and continue button', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Select Your Identity'), findsOneWidget);
    expect(find.text('Which path calls to you?'), findsOneWidget);
    expect(find.text('Tap to learn more'), findsOneWidget);
    expect(find.text('THIS IS ME'), findsOneWidget);
  });

  testWidgets('continue button is disabled before selection', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 5));

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('THIS IS ME'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
