// test/features/world_map/presentation/widgets/world_type_node_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  group('WorldTypeNode', () {
    testWidgets('displays correct label and responds to taps', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.strength,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Strength'), findsOneWidget);

      // Tap the node
      await tester.tap(find.byType(WorldTypeNode));
      await tester.pumpAndSettle();

      // Verify it responds to taps
      expect(tapped, isTrue);
    });

    testWidgets('with NodeHealthStatus.complete renders completion check badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.strength,
              nodeState: const ArchetypeNodeState(
                status: NodeHealthStatus.complete,
                completedCount: 2,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('with NodeHealthStatus.pending renders pending badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.intellect,
              nodeState: const ArchetypeNodeState(
                status: NodeHealthStatus.pending,
                pendingCount: 3,
                completedCount: 1,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('with NodeHealthStatus.decaying renders decay warning badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.vitality,
              nodeState: const ArchetypeNodeState(
                status: NodeHealthStatus.decaying,
                pendingCount: 1,
                hasDecay: true,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('without nodeState or with idle status does not render status badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.focus,
              nodeState: const ArchetypeNodeState(status: NodeHealthStatus.idle),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('renders accessible Semantics label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorldTypeNode(
              attribute: HabitAttribute.vitality,
              nodeState: const ArchetypeNodeState(
                status: NodeHealthStatus.decaying,
                pendingCount: 2,
                hasDecay: true,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == 'Vitality archetype: decaying, 2 pending' &&
            w.properties.hint == 'Double tap to view Vitality details',
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}
