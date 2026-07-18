// lib/features/world_map/presentation/widgets/world_ring_layout.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
import 'package:emerge_app/features/world_map/utils/ring_layout_geometry.dart';
import 'package:flutter/material.dart';

class WorldRingLayout extends StatelessWidget {
  final double radius;
  final ValueChanged<HabitAttribute> onNodeTap;
  final String? focusAttribute;

  const WorldRingLayout({
    super.key,
    required this.radius,
    required this.onNodeTap,
    this.focusAttribute,
  });

  @override
  Widget build(BuildContext context) {
    final attributes = HabitAttribute.values;
    final nodeCount = attributes.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
            
        final size = Size(width, height);
        final positions = calculateRingNodePositions(
          size: size,
          radius: radius,
          nodeCount: nodeCount,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(nodeCount, (index) {
            final attr = attributes[index];
            final pos = positions[index];

            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: WorldTypeNode(
                  attribute: attr,
                  isFocused: focusAttribute == attr.name,
                  onTap: () => onNodeTap(attr),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
