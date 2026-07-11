// test/features/world_map/presentation/widgets/world_type_node_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  testWidgets('WorldTypeNode displays correct label and responds to taps', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorldTypeNode(
          attribute: HabitAttribute.strength,
          onTap: () {
            tapped = true;
          },
        ),
      ),
    ));

    expect(find.text('Strength'), findsOneWidget);

    // Tap the node
    await tester.tap(find.byType(WorldTypeNode));
    await tester.pumpAndSettle();

    // Verify it responds to taps
    expect(tapped, isTrue);
  });
}
