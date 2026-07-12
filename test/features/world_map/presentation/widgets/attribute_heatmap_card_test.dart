import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/attribute_heatmap_card.dart';
import 'package:emerge_app/features/world_map/presentation/providers/attribute_completions_provider.dart';

void main() {
  testWidgets('AttributeHeatmapCard shows loading and then chart', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attributeCompletionsProvider('strength').overrideWith((ref) => Future.value([10, 20, 0, 0, 50, 0, 100])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AttributeHeatmapCard(attribute: HabitAttribute.strength),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Last 7 Days XP'), findsOneWidget);
  });
}
