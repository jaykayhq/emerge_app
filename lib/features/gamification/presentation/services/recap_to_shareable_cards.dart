// lib/features/gamification/presentation/services/recap_to_shareable_cards.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

/// Maps a weekly recap into branded share cards (9:16).
/// Pure — no Flutter rendering; unit-testable.
List<ShareableCardData> recapToShareableCards(UserWeeklyRecap recap) {
  final df = DateFormat('MMM dd');
  final range = '${df.format(recap.startDate)} – ${df.format(recap.endDate)}';
  final cards = <ShareableCardData>[];

  // Stats card
  cards.add(
    ShareableCardData(
      headline: 'MY WEEK IN NUMBERS',
      subheadline: range,
      stats: [
        ShareableStat(
          label: 'Habits Completed',
          value: '${recap.totalHabitsCompleted}',
          color: EmergeColors.teal,
          icon: Icons.check_circle_outline_rounded,
        ),
        ShareableStat(
          label: 'Perfect Days',
          value: '${recap.perfectDays}',
          color: EmergeColors.warmGold,
          icon: Icons.whatshot_rounded,
        ),
        ShareableStat(
          label: 'XP Earned',
          value: '+${recap.totalXpEarned}',
          color: EmergeColors.violet,
          icon: Icons.stars_rounded,
        ),
      ],
      footer: 'Level ${recap.currentLevel}',
    ),
  );

  // Top habit card
  cards.add(
    ShareableCardData(
      headline: 'MY MVP',
      subheadline: 'Most consistent habit',
      stats: [
        ShareableStat(
          label: 'Top Habit',
          value: recap.topHabitName.toUpperCase(),
          color: EmergeColors.warmGold,
          icon: Icons.emoji_events_rounded,
        ),
      ],
      footer: 'Built with Emerge',
    ),
  );

  // Identity card (only when available)
  final identity = recap.dominantIdentityThisWeek;
  if (identity != null && identity.isNotEmpty) {
    cards.add(
      ShareableCardData(
        headline: 'THIS WEEK I WAS A',
        subheadline: recap.identityHeadline,
        stats: [
          ShareableStat(
            label: 'Identity',
            value: identity.toUpperCase(),
            color: EmergeColors.neonTeal,
            icon: Icons.auto_awesome_rounded,
          ),
        ],
        footer: 'Every habit counts toward building your identity',
      ),
    );
  }

  return cards;
}
