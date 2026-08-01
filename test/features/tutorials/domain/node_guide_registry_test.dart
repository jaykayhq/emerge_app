import 'package:emerge_app/features/tutorials/domain/node_guide_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NodeGuideRegistry', () {
    test('every registered node has a definition', () {
      for (final d in NodeGuideRegistry.all) {
        expect(d.nodeId, isNotEmpty);
        expect(d.title, isNotEmpty);
        expect(d.items, isNotEmpty, reason: '${d.nodeId} has no items');
      }
    });

    test('node ids are unique', () {
      final ids = NodeGuideRegistry.all.map((d) => d.nodeId).toSet();
      expect(ids.length, NodeGuideRegistry.all.length);
    });

    test('forNode finds known nodes and misses unknown ones', () {
      expect(NodeGuideRegistry.forNode('timeline'), isNotNull);
      expect(NodeGuideRegistry.forNode('does_not_exist'), isNull);
    });

    test('every item has title and body', () {
      for (final d in NodeGuideRegistry.all) {
        for (final item in d.items) {
          expect(item.title, isNotEmpty);
          expect(item.body, isNotEmpty);
        }
      }
    });
  });
}
