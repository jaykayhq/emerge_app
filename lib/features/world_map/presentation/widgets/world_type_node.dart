// lib/features/world_map/presentation/widgets/world_type_node.dart
import 'package:emerge_app/core/utils/string_extensions.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:flutter/material.dart';

class WorldTypeNode extends StatelessWidget {
  final HabitAttribute attribute;
  final VoidCallback onTap;
  final bool isFocused;
  final ArchetypeNodeState? nodeState;

  const WorldTypeNode({
    super.key,
    required this.attribute,
    required this.onTap,
    this.isFocused = false,
    this.nodeState,
  });

  @override
  Widget build(BuildContext context) {
    final config = WorldTypeConfig.forAttribute(attribute);
    final theme = Theme.of(context);
    final String labelName = attribute.name.capitalize();
    final statusText = switch (nodeState?.status) {
      NodeHealthStatus.complete => 'completed today',
      NodeHealthStatus.pending => '${nodeState?.pendingCount ?? 0} pending',
      NodeHealthStatus.decaying =>
        'decaying, ${nodeState?.pendingCount ?? 0} pending',
      _ => 'idle',
    };
    final badge = _buildBadge(context);

    return Semantics(
      button: true,
      label: '$labelName archetype: $statusText',
      hint: 'Double tap to view $labelName details',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        scale: isFocused ? 1.4 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: badge,
                  ),
              ],
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
    ),
  );
}

  Widget? _buildBadge(BuildContext context) {
    if (nodeState == null || nodeState!.status == NodeHealthStatus.idle) {
      return null;
    }

    final status = nodeState!.status;

    switch (status) {
      case NodeHealthStatus.complete:
        return _BadgeContainer(
          backgroundColor: const Color(0xFF2BEE79),
          child: const Icon(
            Icons.check,
            size: 13,
            color: Colors.black,
          ),
        );
      case NodeHealthStatus.pending:
        return _BadgeContainer(
          backgroundColor: const Color(0xFFFFB74D),
          child: nodeState!.pendingCount > 0
              ? Text(
                  '${nodeState!.pendingCount}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(
                  Icons.priority_high,
                  size: 13,
                  color: Colors.black,
                ),
        );
      case NodeHealthStatus.decaying:
        return _BadgeContainer(
          backgroundColor: const Color(0xFFA855F7),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 13,
            color: Colors.white,
          ),
        );
      case NodeHealthStatus.idle:
        return null;
    }
  }
}

class _BadgeContainer extends StatelessWidget {
  final Color backgroundColor;
  final Widget child;

  const _BadgeContainer({
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black87,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
