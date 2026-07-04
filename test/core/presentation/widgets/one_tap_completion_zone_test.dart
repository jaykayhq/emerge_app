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
      await tester.pump(const Duration(seconds: 1));
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

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('removes CompletionParticles after animation completes',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.blue, onComplete: () {}),
      );

      await tester.tap(find.byKey(const Key('completion-zone')));
      await tester.pump();

      // Particles visible immediately after tap
      expect(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(CompletionParticles),
        ),
        findsOneWidget,
      );

      // Advance past 800 ms animation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Particles removed from tree after animation
      expect(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(CompletionParticles),
        ),
        findsNothing,
      );
    });

    testWidgets('does not call onComplete twice on double tap', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        buildTestWidget(color: Colors.green, onComplete: () => callCount++),
      );

      // Tap twice in quick succession
      await tester.tap(find.byKey(const Key('completion-zone')));
      await tester.tap(find.byKey(const Key('completion-zone')));
      await tester.pump();

      // Second tap is ignored by _isProcessing guard
      expect(callCount, 1);
      
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('uses the provided color for the circle container',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.amber, onComplete: () {}),
      );

      // Fix 10: find specifically the decorated circular Container
      // (there may be multiple Containers in the tree after a tap)
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(const Key('completion-zone')),
          matching: find.byType(Container),
        ),
      ).toList();

      // The decoration container is the one with a BoxDecoration circle shape
      final decoratedContainer = containers.firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      final decoration = decoratedContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.amber);
    });
  });
}
