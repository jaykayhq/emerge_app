import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// Bottom sheet showing detailed information about a world map node
class NodeDetailSheet extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final VoidCallback? onFocusNode;

  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.primaryColor,
    this.onFocusNode,
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

          // Description
          Text(
            node.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMainDark,
              height: 1.5,
            ),
          ),

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
              return _AttributeChip(attribute: attr, xpBoost: xpBoost);
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
              onPressed: node.state == NodeState.locked ? null : onFocusNode,
              icon: Icon(
                node.state == NodeState.locked
                    ? Icons.lock
                    : Icons.center_focus_strong,
              ),
              label: Text(
                node.state == NodeState.locked
                    ? 'Locked (Reach Level ${node.requiredLevel})'
                    : 'Focus on This Node',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                disabledForegroundColor: Colors.grey.shade400,
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
}

/// Chip showing an attribute and its XP boost
class _AttributeChip extends StatelessWidget {
  final HabitAttribute attribute;
  final int xpBoost;

  const _AttributeChip({required this.attribute, required this.xpBoost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getAttributeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAttributeColor().withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getAttributeIcon(), color: _getAttributeColor(), size: 16),
          const SizedBox(width: 6),
          Text(
            attribute.name,
            style: TextStyle(
              color: _getAttributeColor(),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getAttributeColor(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$xpBoost XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
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
        return Colors.red;
      case HabitAttribute.strength:
        return EmergeColors.teal;
      case HabitAttribute.focus:
        return Colors.blue;
      case HabitAttribute.intellect:
        return EmergeColors.violet;
      case HabitAttribute.creativity:
        return EmergeColors.yellow;
    }
  }

  IconData _getAttributeIcon() {
    switch (attribute) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.strength:
        return Icons.schedule;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.intellect:
        return Icons.psychology;
      case HabitAttribute.creativity:
        return Icons.palette;
    }
  }
}
