import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';

void main() {
  group('NodeHealthStatus', () {
    test('contains all expected enum values', () {
      expect(NodeHealthStatus.values, containsAll([
        NodeHealthStatus.complete,
        NodeHealthStatus.pending,
        NodeHealthStatus.decaying,
        NodeHealthStatus.idle,
      ]));
    });
  });

  group('ArchetypeNodeState', () {
    test('instantiates with defaults', () {
      const state = ArchetypeNodeState(status: NodeHealthStatus.idle);
      expect(state.status, NodeHealthStatus.idle);
      expect(state.pendingCount, 0);
      expect(state.completedCount, 0);
      expect(state.hasDecay, false);
      expect(state.isComplete, false);
    });

    test('instantiates with custom properties', () {
      const state = ArchetypeNodeState(
        status: NodeHealthStatus.pending,
        pendingCount: 3,
        completedCount: 2,
        hasDecay: true,
      );
      expect(state.status, NodeHealthStatus.pending);
      expect(state.pendingCount, 3);
      expect(state.completedCount, 2);
      expect(state.hasDecay, true);
      expect(state.isComplete, false);
    });

    test('isComplete returns true only when status is complete', () {
      const completeState = ArchetypeNodeState(
        status: NodeHealthStatus.complete,
        completedCount: 4,
      );
      expect(completeState.isComplete, true);

      const pendingState = ArchetypeNodeState(status: NodeHealthStatus.pending);
      expect(pendingState.isComplete, false);

      const decayingState = ArchetypeNodeState(status: NodeHealthStatus.decaying);
      expect(decayingState.isComplete, false);

      const idleState = ArchetypeNodeState(status: NodeHealthStatus.idle);
      expect(idleState.isComplete, false);
    });

    test('supports value equality and copyWith', () {
      const state1 = ArchetypeNodeState(
        status: NodeHealthStatus.pending,
        pendingCount: 2,
        completedCount: 1,
        hasDecay: false,
      );
      const state2 = ArchetypeNodeState(
        status: NodeHealthStatus.pending,
        pendingCount: 2,
        completedCount: 1,
        hasDecay: false,
      );
      final state3 = state1.copyWith(pendingCount: 5);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state3.pendingCount, 5);
      expect(state3.status, NodeHealthStatus.pending);
    });
  });
}
