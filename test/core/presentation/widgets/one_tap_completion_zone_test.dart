import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/one_tap_completion_zone.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

Widget buildTestWidget({required Color color, required VoidCallback onComplete}) {
  return MaterialApp(
    home: Scaffold(
      body: OneTapCompletionZone(
        color: color,
        onComplete: onComplete,
        key: const Key('completion-zone'),
      ),
    ),
  );
}

void main() {
  group('OneTapCompletionZone', () {
    testWidgets('renders a 48x48 circular tap target', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.green, onComplete: () {}),
      );

      // The widget should be found by its key
      expect(find.byKey(const Key('completion-zone')), findsOneWidget);

      // It should be tappable (GestureDetector)
      expect(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls onComplete when tapped', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestWidget(
          color: Colors.green,
          onComplete: () {
            completed = true;
          },
        ),
      );

      await tester.tap(find.byKey(const Key('completion-zone')));
      expect(completed, true);
    });

    testWidgets('shows CompletionParticles after tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.blue, onComplete: () {}),
      );

      // Before tap, no CompletionParticles descendant
      expect(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(CompletionParticles),
        ),
        findsNothing,
      );

      // Tap
      await tester.tap(find.byKey(const Key('completion-zone')));
      await tester.pump();

      // After tap, CompletionParticles should appear
      expect(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(CompletionParticles),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses the provided color for the circle container',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.amber, onComplete: () {}),
      );

      // Find the Container descendant of the SizedBox
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.amber);
    });
  });
}
