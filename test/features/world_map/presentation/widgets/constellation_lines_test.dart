import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';

void main() {
  testWidgets('ConstellationLines paints lines given coordinates', (WidgetTester tester) async {
    final nodePositions = [
      const Offset(100, 100),
      const Offset(200, 100),
      const Offset(150, 200),
    ];
    const center = Offset(150, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConstellationLines(
            center: center,
            nodePositions: nodePositions,
          ),
        ),
      ),
    );

    expect(find.byType(ConstellationLines), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
