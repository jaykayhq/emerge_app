import 'dart:ui' as ui;

import 'package:emerge_app/core/theme/attribute_colors.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/string_extensions.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:flutter/material.dart';

/// Glassmorphic dock component floating on the World Map showcasing the
/// Next Best Action (NBA) / Next Identity Vote to stoke the realm's bonfire.
class WorldStokingDock extends StatelessWidget {
  final NextIdentityVote vote;
  final VoidCallback? onCastVote;
  final VoidCallback? onOpenHabit;
  final VoidCallback? onOpenRecap;
  final VoidCallback? onNewHabit;

  const WorldStokingDock({
    super.key,
    required this.vote,
    this.onCastVote,
    this.onOpenHabit,
    this.onOpenRecap,
    this.onNewHabit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the accent color based on vote type and recovery state
    final Color accentColor;
    if (vote.isRecovery) {
      accentColor = const Color(0xFFA855F7); // Violet for recovery
    } else if (vote.isHarmonized) {
      accentColor = EmergeColors.warmGold; // Gold for harmonized
    } else if (vote.isEmpty) {
      accentColor = EmergeColors.neonTeal; // Green for starting out
    } else {
      accentColor = attributeColor(vote.attribute ?? HabitAttribute.vitality);
    }

    return Semantics(
      container: true,
      label: 'World Stoking Dock',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xD9120E20), // rgba(18, 14, 32, 0.85)
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildContent(context, theme, accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    switch (vote.type) {
      case NextVoteType.harmonized:
        return _buildHarmonizedState(context, theme, accentColor);
      case NextVoteType.empty:
        return _buildEmptyState(context, theme, accentColor);
      case NextVoteType.actionable:
        return _buildActionableState(context, theme, accentColor);
    }
  }

  Widget _buildActionableState(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    final habit = vote.habit!;
    final attributeName = (vote.attribute?.name ?? 'vitality').toUpperCase();
    final tagLabel = vote.isRecovery
        ? 'RECOVERY ACTION • $attributeName'
        : 'NEXT IDENTITY VOTE • $attributeName';
    final rewardLabel = vote.isRecovery
        ? 'DISPELS FOG'
        : '+${vote.vitalityImpactPercent}% VITALITY';
    final subtitle = vote.isRecovery
        ? 'Critical recovery for ${(vote.attribute?.name ?? 'realm').capitalize()} • Clear realm decay'
        : 'Empowers ${(vote.attribute?.name ?? 'realm').capitalize()} • Cast vote to fuel hearth';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Tag Pill & Reward Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TagPill(label: tagLabel, accentColor: accentColor),
            _RewardBadge(
              label: rewardLabel,
              accentColor: vote.isRecovery
                  ? const Color(0xFFA855F7)
                  : EmergeColors.neonTeal,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom row: Habit title/subtitle (tappable for details) + Action Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenHabit,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'CAST VOTE',
              icon: Icons.bolt_rounded,
              backgroundColor: vote.isRecovery
                  ? const Color(0xFFA855F7)
                  : EmergeColors.neonTeal,
              foregroundColor: Colors.black,
              onPressed: onCastVote,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHarmonizedState(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TagPill(
              label: 'REALM HARMONIZED',
              accentColor: EmergeColors.warmGold,
            ),
            const _RewardBadge(
              label: '100% VITALITY',
              accentColor: EmergeColors.warmGold,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Realm in Golden Bloom',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'All offerings complete for today • Realm at peak vitality',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'VIEW RECAP',
              icon: Icons.auto_awesome,
              backgroundColor: EmergeColors.warmGold,
              foregroundColor: Colors.black,
              onPressed: onOpenRecap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    Color accentColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TagPill(
              label: 'REALM DORMANT',
              accentColor: EmergeColors.neonTeal,
            ),
            const _RewardBadge(
              label: 'FIRST SPARK',
              accentColor: EmergeColors.neonTeal,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ignite Your First Archetype',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Create a habit to spark your realm\'s bonfire',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'ADD HABIT',
              icon: Icons.add_rounded,
              backgroundColor: EmergeColors.neonTeal,
              foregroundColor: Colors.black,
              onPressed: onNewHabit,
            ),
          ],
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _TagPill({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _RewardBadge({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 18, color: foregroundColor),
        label: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
