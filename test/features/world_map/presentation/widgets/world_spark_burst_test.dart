import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_spark_burst.dart';

void main() {
  group('WorldSparkBurst', () {
    testWidgets('renders CustomPaint and triggers onComplete on animation end', (
      tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldSparkBurst(
              startOffset: const Offset(200, 600),
              targetOffset: const Offset(200, 200),
              sparkColor: const Color(0xFF2BEE79),
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      // Initially renders CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
      expect(completed, isFalse);

      // Advance halfway
      await tester.pump(const Duration(milliseconds: 450));
      expect(completed, isFalse);

      // Advance to completion
      await tester.pump(const Duration(milliseconds: 550));
      expect(completed, isTrue);
    });

    testWidgets('immediately calls onComplete when disableAnimations is true', (
      tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: WorldSparkBurst(
                startOffset: const Offset(200, 600),
                targetOffset: const Offset(200, 200),
                onComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('custom spark color is supported without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldSparkBurst(
              startOffset: const Offset(100, 500),
              targetOffset: const Offset(100, 100),
              sparkColor: const Color(0xFFA855F7),
              onComplete: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WorldSparkBurst), findsOneWidget);
    });
  });
}
