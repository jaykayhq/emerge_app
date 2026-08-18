import 'package:emerge_app/features/timeline/presentation/widgets/all_done_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('narrator one-liner is hidden until show() is called', (
    tester,
  ) async {
    final key = GlobalKey<AllDoneCelebrationState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AllDoneCelebration(key: key)),
      ),
    );

    final fadeFinder = find.descendant(
      of: find.byType(AllDoneCelebration),
      matching: find.byType(FadeTransition),
    );

    // Initially not visible (opacity 0).
    expect(find.text('All done. Your future self thanks you.'), findsOneWidget);
    final opacityBefore = tester.widget<FadeTransition>(fadeFinder);
    expect(opacityBefore.opacity.value, 0.0);

    // Trigger show() via the GlobalKey.
    key.currentState!.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final opacityAfter = tester.widget<FadeTransition>(fadeFinder);
    expect(opacityAfter.opacity.value, greaterThan(0.0));
  });
}
