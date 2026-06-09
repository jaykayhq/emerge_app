import 'package:emerge_app/features/profile/presentation/widgets/attribute_radar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttributeRadarChart', () {
    testWidgets('renders without error with animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttributeRadarChart(
              attributes: const {
                'Creativity': 0.8,
                'Focus': 0.6,
                'Output': 0.7,
                'Resilience': 0.5,
                'Vitality': 0.9,
                'Discipline': 0.4,
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(AttributeRadarChart), findsOneWidget);
    });

    testWidgets('re-animates when attributes change', (tester) async {
      final attributes = ValueNotifier(<String, double>{
        'Creativity': 0.8,
        'Focus': 0.6,
        'Output': 0.7,
        'Resilience': 0.5,
        'Vitality': 0.9,
        'Discipline': 0.4,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<Map<String, double>>(
              valueListenable: attributes,
              builder: (context, attrs, _) => AttributeRadarChart(
                attributes: attrs,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change attributes to trigger re-animation
      attributes.value = {
        'Creativity': 0.9,
        'Focus': 0.7,
        'Output': 0.8,
        'Resilience': 0.6,
        'Vitality': 0.95,
        'Discipline': 0.5,
      };

      await tester.pump();

      expect(find.byType(AttributeRadarChart), findsOneWidget);
    });

    testWidgets('produces correct static assets', (tester) async {
      expect(AttributeRadarChart.attributeNames.length, 6);
      expect(AttributeRadarChart.attributeIcons.length, 6);
      expect(AttributeRadarChart.attributeColors.length, 6);
    });
  });
}
