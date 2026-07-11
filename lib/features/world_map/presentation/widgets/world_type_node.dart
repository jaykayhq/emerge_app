// lib/features/world_map/presentation/widgets/world_type_node.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:flutter/material.dart';

class WorldTypeNode extends StatelessWidget {
  final HabitAttribute attribute;
  final VoidCallback onTap;

  const WorldTypeNode({
    super.key,
    required this.attribute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = WorldTypeConfig.forAttribute(attribute);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(color: config.primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              config.fallbackIcon,
              color: config.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.worldName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
