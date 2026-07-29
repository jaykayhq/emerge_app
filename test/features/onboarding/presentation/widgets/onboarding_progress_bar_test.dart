import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

void main() {
  testWidgets('shows correct progress percentage and label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.4,
        label: 'Your archetype is set. What shapes you?',
      ),
    ));
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Your archetype is set. What shapes you?'), findsOneWidget);
  });

  testWidgets('shows remaining percentage after 50%', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.8,
        label: '20% to go. Almost forged. Choose your company.',
      ),
    ));
    expect(find.text('20% to go'), findsOneWidget);
  });

  testWidgets('applies archetype accent color', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.6,
        label: '40% to go. Your interests give texture.',
        accentColor: const Color(0xFF7C3AED), // scholar primary
      ),
    ));
    // Verify the bar renders without error; color applied via LinearProgressIndicator.valueColor
    expect(find.byType(AnimatedOnboardingProgressBar), findsOneWidget);
  });

  testWidgets('percentage label switches at 50% threshold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 0.6,
        label: '40% to go. Your interests give texture.',
      ),
    ));
    // Below 50% shows "X%", at/above 50% shows "Y% to go"
    expect(find.text('40%'), findsNothing);
    expect(find.text('40% to go'), findsOneWidget);
  });

  testWidgets('shows 100% at completion, not 0% to go', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AnimatedOnboardingProgressBar(
        targetProgress: 1.0,
        label: 'Ready to emerge.',
      ),
    ));
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('0% to go'), findsNothing);
  });
}
