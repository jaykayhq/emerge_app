import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

Widget buildTestWidget({required Color color, Key? key}) {
  return MaterialApp(
    home: Scaffold(
      body: CompletionParticles(
        color: color,
        key: key,
      ),
    ),
  );
}

void main() {
  group('CompletionParticles', () {
    testWidgets('renders and starts animation with CustomPaint', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.green, key: const Key('particles')),
      );

      // Our widget should be in the tree
      expect(find.byKey(const Key('particles')), findsOneWidget);

      // A CustomPaint descendant should exist for the particles
      expect(
        find.descendant(
          of: find.byKey(const Key('particles')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('completes animation and returns SizedBox.shrink()',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.green, key: const Key('particles')),
      );

      // Widget should be present initially with CustomPaint
      expect(
        find.descendant(
          of: find.byKey(const Key('particles')),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      // Advance past the 800ms animation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The CompletionParticles widget still exists but renders SizedBox.shrink()
      // So CustomPaint should no longer be present as a descendant
      expect(
        find.descendant(
          of: find.byKey(const Key('particles')),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );

      // The widget should still be in tree (rendering empty)
      expect(find.byKey(const Key('particles')), findsOneWidget);
    });

    testWidgets('uses the provided color', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.amber, key: const Key('particles')),
      );

      // Find CustomPaint descendant of our widget
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const Key('particles')),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as ParticleBurstPainter;
      expect(painter.color, Colors.amber);
    });

    testWidgets('creates 30 particles by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(color: Colors.blue, key: const Key('particles')),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const Key('particles')),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as ParticleBurstPainter;
      expect(painter.particles.length, 30);
    });
  });

  group('ParticleBurstPainter', () {
    test('particles have random initial positions near center', () {
      final painter = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
      );

      // All particles should be roughly centered (near 0,0 offset)
      for (final p in painter.particles) {
        expect(p.offsetDx.abs(), lessThan(20));
        expect(p.offsetDy.abs(), lessThan(20));
      }
    });

    test('shouldRepaint returns true for different progress', () {
      final painter1 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
      );
      final painter2 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.5,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false for same progress', () {
      final painter1 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
      );
      final painter2 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });
  });
}
