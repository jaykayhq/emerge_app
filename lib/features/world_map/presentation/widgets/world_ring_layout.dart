// lib/features/world_map/presentation/widgets/world_ring_layout.dart
import 'dart:math' as math;
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_type_node.dart';
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
    final angleStep = (2 * math.pi) / nodeCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
            
        final center = Offset(width / 2, height / 2);

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(nodeCount, (index) {
            final attr = attributes[index];
            // Start at top (-pi/2) and go clockwise
            final angle = -math.pi / 2 + (index * angleStep);
            
            final dx = center.dx + (radius * math.cos(angle));
            final dy = center.dy + (radius * math.sin(angle));

            return Positioned(
              left: dx,
              top: dy,
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
