// test/features/world_map/presentation/widgets/world_type_node_test.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldTypeNode', () {
    testWidgets('renders node, text, and responds to taps', (tester) async {
      bool tapped = false;
      const attribute = HabitAttribute.focus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WorldTypeNode(
                attribute: attribute,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify the node renders the icon and text
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Lightning'), findsOneWidget); 

      // Tap the node
      await tester.tap(find.byType(WorldTypeNode));
      await tester.pumpAndSettle();

      // Verify it responds to taps
      expect(tapped, isTrue);
    });
  });
}
