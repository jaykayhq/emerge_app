// lib/features/world_map/presentation/widgets/world_type_node.dart
import 'package:emerge_app/core/utils/string_extensions.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:flutter/material.dart';

class WorldTypeNode extends StatelessWidget {
  final HabitAttribute attribute;
  final VoidCallback onTap;
  final bool isFocused;

  const WorldTypeNode({
    super.key,
    required this.attribute,
    required this.onTap,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = WorldTypeConfig.forAttribute(attribute);
    final theme = Theme.of(context);
    final String labelName = attribute.name.capitalize();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 1.0, end: isFocused ? 1.4 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.primaryColor.withValues(alpha: 0.15),
                border: Border.all(color: config.primaryColor, width: 2),
                // 3D pop effect
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                config.fallbackIcon,
                color: config.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                labelName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: config.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
