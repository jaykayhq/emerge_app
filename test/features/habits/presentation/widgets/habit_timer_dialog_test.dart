import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a MaterialApp with a navigator so Dialog widgets render.
Future<void> pumpDialog(
  WidgetTester tester, {
  required String habitTitle,
  required int durationMinutes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => HabitTimerDialog(
              habitTitle: habitTitle,
              neonColor: Colors.green,
              durationMinutes: durationMinutes,
              onComplete: () => Navigator.of(context).pop(),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );

  // Tap the button to open the dialog
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('HabitTimerDialog', () {
    testWidgets('shows habit title and default duration button', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        habitTitle: 'Morning Meditation',
        durationMinutes: 2,
      );

      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.text('Start 2-Min Timer'), findsOneWidget);
    });

    testWidgets('shows duration picker chips', (tester) async {
      await pumpDialog(tester, habitTitle: 'Test', durationMinutes: 5);

      expect(find.text('1m'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('tapping a duration chip updates selected duration', (
      tester,
    ) async {
      await pumpDialog(tester, habitTitle: 'Test', durationMinutes: 2);

      // Default is 2m, button says "Start 2-Min Timer"
      expect(find.text('Start 2-Min Timer'), findsOneWidget);

      // Tap 5m chip
      await tester.tap(find.text('5m'));
      await tester.pump();

      // Button should now say "Start 5-Min Timer"
      expect(find.text('Start 5-Min Timer'), findsOneWidget);
    });

    testWidgets('start button is present', (tester) async {
      await pumpDialog(tester, habitTitle: 'Test', durationMinutes: 2);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('cancel button is present', (tester) async {
      await pumpDialog(tester, habitTitle: 'Test', durationMinutes: 2);

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button dismisses the dialog', (tester) async {
      await pumpDialog(tester, habitTitle: 'Test', durationMinutes: 2);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should be dismissed
      expect(find.text('Start 2-Min Timer'), findsNothing);
    });
  });
}
