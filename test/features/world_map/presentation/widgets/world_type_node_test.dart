// test/features/world_map/presentation/widgets/world_type_node_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  testWidgets('WorldTypeNode displays correct label and styled container', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorldTypeNode(attribute: HabitAttribute.strength, onTap: () {}),
      ),
    ));

    expect(find.text('Strength'), findsOneWidget);
  });
}
