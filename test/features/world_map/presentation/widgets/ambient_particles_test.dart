import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';

void main() {
  testWidgets('AmbientParticles creates a CustomPaint and animates', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmbientParticles(particleCount: 50),
        ),
      ),
    );

    expect(find.byType(AmbientParticles), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  });
}
