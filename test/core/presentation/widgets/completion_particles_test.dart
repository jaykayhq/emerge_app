import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/widgets/completion_particles.dart';

/// Builds a [CompletionParticles] widget with a no-op [onComplete].
Widget buildTestWidget({
  required Color color,
  Key? key,
  VoidCallback? onComplete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CompletionParticles(
        color: color,
        key: key,
        onComplete: onComplete ?? () {},
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

    testWidgets('calls onComplete callback and CustomPaint disappears after animation',
        (tester) async {
      bool callbackFired = false;

      // We wrap CompletionParticles in a parent that removes it on onComplete,
      // mirroring the real OneTapCompletionZone behaviour.
      await tester.pumpWidget(
        _RemovableParticlesHost(
          color: Colors.green,
          onCompleteCallback: () => callbackFired = true,
        ),
      );

      // Widget should be present initially with CustomPaint
      expect(find.byType(CompletionParticles), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CompletionParticles),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      // Advance past the 800 ms animation
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The callback should have fired
      expect(callbackFired, isTrue);

      // The parent should have removed CompletionParticles from the tree
      expect(find.byType(CompletionParticles), findsNothing);
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

    testWidgets('creates 30 particles', (tester) async {
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
    // Helper: generate a deterministic list of 30 particles for painter tests.
    List<ParticleData> makeParticles() =>
        List.generate(30, (_) => const ParticleData(
              offsetDx: 0,
              offsetDy: 0,
              angle: 0,
              speed: 1,
              size: 3,
            ));

    test('particles have expected count', () {
      final particles = makeParticles();
      final painter = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
        particles: particles,
      );

      expect(painter.particles.length, 30);
    });

    test('particles from ParticleData.random have positions near center', () {
      final particles =
          List.generate(30, (_) => ParticleData.random());

      for (final p in particles) {
        expect(p.offsetDx.abs(), lessThan(20));
        expect(p.offsetDy.abs(), lessThan(20));
      }
    });

    test('shouldRepaint returns true for different progress', () {
      final particles = makeParticles();
      final painter1 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
        particles: particles,
      );
      final painter2 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.5,
        particles: particles,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false for same progress', () {
      final particles = makeParticles();
      final painter1 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
        particles: particles,
      );
      final painter2 = ParticleBurstPainter(
        color: Colors.red,
        progress: 0.0,
        particles: particles,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper widget — mirrors OneTapCompletionZone's removal logic in miniature
// ---------------------------------------------------------------------------

class _RemovableParticlesHost extends StatefulWidget {
  final Color color;
  final VoidCallback onCompleteCallback;

  const _RemovableParticlesHost({
    required this.color,
    required this.onCompleteCallback,
  });

  @override
  State<_RemovableParticlesHost> createState() =>
      _RemovableParticlesHostState();
}

class _RemovableParticlesHostState extends State<_RemovableParticlesHost> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _show
            ? CompletionParticles(
                color: widget.color,
                onComplete: () {
                  widget.onCompleteCallback();
                  if (mounted) setState(() => _show = false);
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
