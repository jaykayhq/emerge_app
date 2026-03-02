import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// Bottom sheet showing detailed information about a world map node
class NodeDetailSheet extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final VoidCallback? onAction;
  final UserAvatarStats userStats; // User's current attribute XP

  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.primaryColor,
    required this.userStats,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Node icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor),
                ),
                child: Icon(node.icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textMainDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Node type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            node.type.name.toUpperCase(),
                            style: TextStyle(
                              color: _getTypeColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Level ${node.requiredLevel}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tier badge
              _buildTierBadge(context),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            node.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMainDark,
              height: 1.5,
            ),
          ),

          if (node.directive.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assistant_direction,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DIRECTIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.directive,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMainDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Targeted Attributes section
          Text(
            'ATTRIBUTE BOOSTS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondaryDark,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: node.targetedAttributes.map((attr) {
              final xpBoost = node.xpBoosts[attr] ?? 10;
              final currentXp = _getXpForAttribute(userStats, attr);
              return _AttributeChip(
                attribute: attr,
                xpBoost: xpBoost,
                currentXp: currentXp,
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Progress bar
          if (node.state != NodeState.locked) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                Text(
                  '${node.progress}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: node.progress / 100,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(primaryColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  node.state == NodeState.locked ||
                      node.state == NodeState.completed ||
                      node.state == NodeState.mastered
                  ? null
                  : onAction,
              icon: Icon(
                node.state == NodeState.locked
                    ? Icons.lock
                    : node.state == NodeState.completed ||
                          node.state == NodeState.mastered
                    ? Icons.check_circle
                    : node.state == NodeState.inProgress
                    ? Icons.task_alt
                    : Icons.play_arrow,
              ),
              label: Text(_getActionButtonLabel()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    node.state == NodeState.completed ||
                        node.state == NodeState.mastered
                    ? primaryColor.withValues(alpha: 0.5)
                    : Colors.grey.shade700,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonLabel() {
    switch (node.state) {
      case NodeState.locked:
        return 'Locked (Reach Level ${node.requiredLevel})';
      case NodeState.available:
        return 'Begin Mission';
      case NodeState.inProgress:
        return 'Complete Mission';
      case NodeState.completed:
      case NodeState.mastered:
        return 'Completed';
    }
  }

  Widget _buildTierBadge(BuildContext context) {
    final tierColors = {
      NodeTier.dormant: Colors.grey,
      NodeTier.awakened: Colors.blue,
      NodeTier.thriving: Colors.green,
      NodeTier.radiant: Colors.purple,
      NodeTier.legendary: Colors.amber,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tierColors[node.tier]!.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColors[node.tier]!),
      ),
      child: Text(
        node.tier.name.toUpperCase(),
        style: TextStyle(
          color: tierColors[node.tier],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (node.type) {
      case NodeType.waypoint:
        return EmergeColors.teal;
      case NodeType.milestone:
        return Colors.amber;
      case NodeType.challenge:
        return EmergeColors.coral;
      case NodeType.resource:
        return Colors.green;
      case NodeType.landmark:
        return EmergeColors.violet;
    }
  }

  int _getXpForAttribute(UserAvatarStats stats, HabitAttribute attr) {
    switch (attr) {
      case HabitAttribute.vitality:
        return stats.vitalityXp;
      case HabitAttribute.strength:
        return stats.strengthXp;
      case HabitAttribute.focus:
        return stats.focusXp;
      case HabitAttribute.intellect:
        return stats.intellectXp;
      case HabitAttribute.creativity:
        return stats.creativityXp;
      case HabitAttribute.spirit:
        return stats.spiritXp;
    }
  }
}

/// Chip showing an attribute, the user's current XP, and the potential boost
class _AttributeChip extends StatelessWidget {
  final HabitAttribute attribute;
  final int xpBoost;
  final int currentXp;

  const _AttributeChip({
    required this.attribute,
    required this.xpBoost,
    required this.currentXp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getAttributeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAttributeColor().withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Attribute Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getAttributeIcon(), color: _getAttributeColor(), size: 18),
              const SizedBox(width: 6),
              Text(
                attribute.name[0].toUpperCase() + attribute.name.substring(1),
                style: TextStyle(
                  color: _getAttributeColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Current XP
          Text(
            'Current: $currentXp XP',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          // Row 3: Reward Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getAttributeColor(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '🚀 +$xpBoost XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttributeColor() {
    switch (attribute) {
      case HabitAttribute.vitality:
        return const Color(0xFF00E5FF);
      case HabitAttribute.intellect:
        return const Color(0xFFE040FB);
      case HabitAttribute.creativity:
        return const Color(0xFF76FF03);
      case HabitAttribute.focus:
        return const Color(0xFFFFAB00);
      case HabitAttribute.strength:
        return const Color(0xFFFF5252);
      case HabitAttribute.spirit:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getAttributeIcon() {
    switch (attribute) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.intellect:
        return Icons.menu_book;
      case HabitAttribute.creativity:
        return Icons.palette;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.strength:
        return Icons.fitness_center;
      case HabitAttribute.spirit:
        return Icons.auto_awesome;
    }
  }
}
