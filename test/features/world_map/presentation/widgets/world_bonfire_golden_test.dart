import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the bonfire silhouette stable across health states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 240);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> capture(String name, double health) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0A1A),
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('world-bonfire-golden'),
                child: CustomPaint(
                  size: const Size(216, 216),
                  painter: WorldBonfirePainter(
                    visualState: WorldBonfireVisualState.fromHealth(health),
                    animationValue: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('world-bonfire-golden')),
        matchesGoldenFile('goldens/world_bonfire_$name.png'),
      );
    }

    await capture('low', 0.0);
    await capture('neutral', 0.5);
    await capture('thriving', 1.0);
  });
}
