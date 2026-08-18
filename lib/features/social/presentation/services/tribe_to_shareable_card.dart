// lib/features/social/presentation/services/tribe_to_shareable_card.dart
import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Maps a creator's tribe stats into a branded share card (9:16).
/// Pure — unit-testable.
ShareableCardData tribeToShareableCard({
  required String tribeName,
  required String creatorName,
  required int memberCount,
  required int totalXp,
  required int totalHabitsCompleted,
  required int totalChallengesCompleted,
}) {
  String formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return xp.toString();
  }

  return ShareableCardData(
    headline: tribeName.toUpperCase(),
    subheadline: 'by $creatorName',
    stats: [
      ShareableStat(
        label: 'Members',
        value: '$memberCount',
        color: EmergeColors.neonTeal,
        icon: Icons.groups_rounded,
      ),
      ShareableStat(
        label: 'Tribe XP',
        value: formatXp(totalXp),
        color: EmergeColors.warmGold,
        icon: Icons.bolt_rounded,
      ),
      ShareableStat(
        label: 'Habits Done',
        value: '$totalHabitsCompleted',
        color: EmergeColors.blue,
        icon: Icons.check_circle_outline_rounded,
      ),
      ShareableStat(
        label: 'Challenges',
        value: '$totalChallengesCompleted',
        color: EmergeColors.purple,
        icon: Icons.emoji_events_rounded,
      ),
    ],
    footer: 'Join my tribe on Emerge',
  );
}