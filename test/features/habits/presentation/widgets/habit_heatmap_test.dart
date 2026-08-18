import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_heatmap.dart';

void main() {
  testWidgets('HabitHeatmap renders at least 80 containers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitHeatmap(data: List.generate(90, (i) => i % 3 == 0)),
        ),
      ),
    );

    expect(find.byType(Container), findsAtLeastNWidgets(80));
  });
}
