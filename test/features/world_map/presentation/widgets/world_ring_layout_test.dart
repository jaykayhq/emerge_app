// test/features/world_map/presentation/widgets/world_ring_layout_test.dart
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorldRingLayout positions 6 nodes around the center', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WorldRingLayout(
          radius: 120,
          onNodeTap: (attr) {},
        ),
      ),
    ));

    expect(find.byType(WorldTypeNode), findsNWidgets(6));
  });
}
