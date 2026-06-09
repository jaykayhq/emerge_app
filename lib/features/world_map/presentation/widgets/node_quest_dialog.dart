import 'dart:ui';

import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// RPG-style dialog box that appears when tapping a locked world map node
/// Shows node info, directive, and locked indicator
class NodeQuestDialog extends StatelessWidget {
  final WorldNode node;
  final Color primaryColor;
  final int userLevel;

  const NodeQuestDialog({
    super.key,
    required this.node,
    required this.primaryColor,
    required this.userLevel,
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

  Widget _buildButtons(BuildContext context) {
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
        // Locked indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'LOCKED (LVL ${node.requiredLevel})',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
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
}
