import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';

void main() {
  testWidgets('shows correct progress percentage and label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingProgressBar(
        progress: 0.4,
        label: 'Your archetype is set. What shapes you?',
      ),
    ));
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Your archetype is set. What shapes you?'), findsOneWidget);
  });
}
