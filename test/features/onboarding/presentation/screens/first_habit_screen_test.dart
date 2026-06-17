import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habit_screen.dart';
import '../../../../helpers/widget_test_utils.dart';

Widget _buildTest() {
  return createScreenUnderTest(
    screen: const FirstHabitScreen(),
    overrides: [
      enhancedOnboardingProvider.overrideWithValue(
        const EnhancedOnboardingState(),
      ),
      userStatsStreamProvider.overrideWithValue(
        AsyncValue.data(const UserProfile(uid: '')),
      ),
    ],
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders title, subtitle, and skip button', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Your First Identity Vote'), findsOneWidget);
    expect(find.textContaining('Prove to yourself'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('CREATE MY FIRST HABIT'), findsOneWidget);
  });

  testWidgets('create habit button is disabled before selection', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(seconds: 5));

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('CREATE MY FIRST HABIT'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
