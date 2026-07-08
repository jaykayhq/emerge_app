import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/presentation/providers/social_preload_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/world_reveal_screen.dart';
import '../../../../helpers/widget_test_utils.dart';

Widget _buildTest() {
  return createScreenUnderTest(
    screen: const WorldRevealScreen(),
    overrides: [
      socialDataPreloadProvider.overrideWithValue(
        const AsyncValue.data(null),
      ),
    ],
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders initial message without crashing', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Your identity is forming...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('shows enter button after animation sequence', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('ENTER YOUR WORLD'), findsOneWidget);
  });
}
