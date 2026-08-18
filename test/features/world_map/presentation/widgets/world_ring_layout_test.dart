// test/features/world_map/presentation/widgets/world_ring_layout_test.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldRingLayout', () {
    testWidgets('positions 6 nodes around the center', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldRingLayout(radius: 120, onNodeTap: (attr) {}),
          ),
        ),
      );

      expect(find.byType(WorldTypeNode), findsNWidgets(6));
    });

    testWidgets('passes nodeStates to corresponding WorldTypeNodes', (tester) async {
      final nodeStates = {
        HabitAttribute.vitality: const ArchetypeNodeState(
          status: NodeHealthStatus.complete,
          completedCount: 2,
        ),
        HabitAttribute.focus: const ArchetypeNodeState(
          status: NodeHealthStatus.decaying,
          pendingCount: 1,
          hasDecay: true,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldRingLayout(
              radius: 120,
              onNodeTap: (attr) {},
              nodeStates: nodeStates,
            ),
          ),
        ),
      );

      final nodes = tester.widgetList<WorldTypeNode>(find.byType(WorldTypeNode)).toList();
      expect(nodes.length, 6);

      final vitalityNode = nodes.firstWhere((n) => n.attribute == HabitAttribute.vitality);
      expect(vitalityNode.nodeState?.status, NodeHealthStatus.complete);

      final focusNode = nodes.firstWhere((n) => n.attribute == HabitAttribute.focus);
      expect(focusNode.nodeState?.status, NodeHealthStatus.decaying);

      final intellectNode = nodes.firstWhere((n) => n.attribute == HabitAttribute.intellect);
      expect(intellectNode.nodeState, isNull);

      // Verify complete badge (check icon) and decaying badge (warning icon) rendered
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
