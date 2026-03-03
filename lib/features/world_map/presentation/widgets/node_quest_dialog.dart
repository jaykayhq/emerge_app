import 'dart:ui';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// RPG-style dialog box that appears when tapping a world map node
/// Shows node info, directive, XP boosts, progress, and an "Enter Level" button
class NodeQuestDialog extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final int userLevel;
  final VoidCallback? onEnterLevel;
  final VoidCallback? onAction;

  const NodeQuestDialog({
    super.key,
    required this.node,
    required this.primaryColor,
    required this.userLevel,
    this.onEnterLevel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildDescription(context),
                if (node.directive.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDirective(context),
                ],
                const SizedBox(height: 16),
                _buildAttributeChips(context),
                const SizedBox(height: 16),
                _buildProgressBar(context),
                const SizedBox(height: 20),
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Node emoji
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(node.emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        // Name + badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildBadge(node.type.name.toUpperCase(), _getTypeColor()),
                  const SizedBox(width: 6),
                  _buildBadge(
                    'STAGE ${node.stage}',
                    Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tier badge
        _buildBadge(node.tier.name.toUpperCase(), _getTierColor()),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      node.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.7),
        height: 1.4,
      ),
    );
  }

  Widget _buildDirective(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIRECTIVE',
            style: TextStyle(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.directive,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: node.targetedAttributes.map((attr) {
        final xp = node.xpBoosts[attr] ?? 10;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getAttributeColor(attr).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getAttributeColor(attr).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getAttributeIcon(attr),
                color: _getAttributeColor(attr),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${attr.name[0].toUpperCase()}${attr.name.substring(1)} +$xp XP',
                style: TextStyle(
                  color: _getAttributeColor(attr),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURRENT PROGRESS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${node.progress}%',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: node.progress / 100,
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(primaryColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    final isLocked = node.state == NodeState.locked;
    final isCompleted =
        node.state == NodeState.completed || node.state == NodeState.mastered;

    return Row(
      children: [
        // Close button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '✕ CLOSE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        // Enter Level button
        ElevatedButton.icon(
          onPressed: isLocked
              ? null
              : () {
                  Navigator.pop(context);
                  onEnterLevel?.call();
                },
          icon: Icon(
            isLocked
                ? Icons.lock_outline
                : isCompleted
                ? Icons.check_circle
                : Icons.bolt,
            size: 18,
          ),
          label: Text(
            isLocked
                ? 'LOCKED (LVL ${node.requiredLevel})'
                : isCompleted
                ? 'VIEW LEVEL'
                : 'ENTER LEVEL',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted
                ? primaryColor.withValues(alpha: 0.6)
                : primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade800,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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

  Color _getTierColor() {
    switch (node.tier) {
      case NodeTier.dormant:
        return Colors.grey;
      case NodeTier.awakened:
        return Colors.blue;
      case NodeTier.thriving:
        return Colors.green;
      case NodeTier.radiant:
        return Colors.purple;
      case NodeTier.legendary:
        return Colors.amber;
    }
  }

  Color _getAttributeColor(HabitAttribute attr) {
    switch (attr) {
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

  IconData _getAttributeIcon(HabitAttribute attr) {
    switch (attr) {
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
