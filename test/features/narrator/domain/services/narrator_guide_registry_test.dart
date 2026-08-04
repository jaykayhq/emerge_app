import 'package:emerge_app/features/narrator/domain/services/narrator_guide_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorGuideRegistry', () {
    test('registers exactly the 9 live nodes', () {
      expect(NarratorGuideRegistry.all.length, 9);
      expect(NarratorGuideRegistry.all.map((n) => n.nodeId).toSet(), {
        'timeline',
        'habit_create',
        'streak_recovery',
        'world_map',
        'leveling',
        'future_self',
        'challenges',
        'all_tribes',
        'tribe_lobby',
      });
    });

    test('node ids are unique', () {
      final ids = NarratorGuideRegistry.all.map((n) => n.nodeId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every node has 2-4 steps, each with a script and a targetKey', () {
      for (final node in NarratorGuideRegistry.all) {
        expect(
          node.steps.length,
          inInclusiveRange(2, 4),
          reason: 'node ${node.nodeId}',
        );
        for (final step in node.steps) {
          expect(
            step.script.trim(),
            isNotEmpty,
            reason: '${node.nodeId} script',
          );
          expect(
            step.targetKey.trim(),
            isNotEmpty,
            reason: '${node.nodeId} target',
          );
        }
      }
    });

    test('targetKeys are unique within a node', () {
      for (final node in NarratorGuideRegistry.all) {
        final keys = node.steps.map((s) => s.targetKey).toList();
        expect(keys.toSet().length, keys.length, reason: 'node ${node.nodeId}');
      }
    });

    test('forNode returns null for unknown nodes', () {
      expect(NarratorGuideRegistry.forNode('nope'), isNull);
    });

    test('forNode returns the matching definition for a known node', () {
      expect(NarratorGuideRegistry.forNode('timeline')?.nodeId, 'timeline');
      expect(NarratorGuideRegistry.forNode('timeline')?.steps.length, 3);
    });
  });
}
