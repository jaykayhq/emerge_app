import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

/// Identity-first status row that sits between the lobby hero and the live
/// feed. Shows four minimal chips: LIVE signals, MOMENTUM state, STREAK,
/// and active QUESTS count.
class TribePulseStatusRow extends ConsumerWidget {
  final Tribe userClub;
  final UserProfile profile;

  const TribePulseStatusRow({
    super.key,
    required this.userClub,
    required this.profile,
  });

  static const _flame = Color(0xFFFF7F50);
  static const _liveGreen = Color(0xFF2BEE79);
  static const _questCyan = Color(0xFF00D2FF);

  static String labelForStreakState(HabitStreakState s) {
    switch (s) {
      case HabitStreakState.onFire:
        return 'On Fire';
      case HabitStreakState.strong:
        return 'Strong';
      case HabitStreakState.building:
        return 'Building';
      case HabitStreakState.atRisk:
        return 'At Risk';
      case HabitStreakState.recovery:
        return 'Recovery';
      case HabitStreakState.reset:
        return 'Reset';
    }
  }

  static Color colorForStreakState(HabitStreakState s) {
    switch (s) {
      case HabitStreakState.onFire:
        return const Color(0xFFFF7F50);
      case HabitStreakState.strong:
        return EmergeColors.neonTeal;
      case HabitStreakState.building:
        return EmergeColors.nebulaPrimary;
      case HabitStreakState.atRisk:
        return EmergeColors.warmGold;
      case HabitStreakState.recovery:
        return EmergeColors.nebulaSecondary;
      case HabitStreakState.reset:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivityProvider(userClub.id));
    final activityCount = activityAsync.value?.length ?? 0;

    final challengesAsync = ref.watch(userChallengesProvider);
    final activeCount = challengesAsync.value
            ?.where((c) => c.status == ChallengeStatus.active)
            .length ??
        0;

    final momentum = profile.avatarStats.momentumState;
    final momentumLabel = labelForStreakState(momentum);
    final momentumColor = colorForStreakState(momentum);
    final streakDays = profile.avatarStats.streak;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _PulseChip(
            dotColor: _liveGreen,
            label: 'LIVE',
            value: '$activityCount signals',
            onTap: () =>
                context.push('/social/activity?tribeId=${userClub.id}'),
          ),
          const Gap(8),
          _PulseChip(
            dotColor: momentumColor,
            label: 'MOMENTUM',
            value: momentumLabel,
          ),
          const Gap(8),
          _PulseChip(
            dotColor: _flame,
            label: 'STREAK',
            value: '${streakDays}d',
          ),
          const Gap(8),
          _PulseChip(
            dotColor: _questCyan,
            label: 'QUESTS',
            value: '$activeCount active',
            onTap: () => context.push('/social/challenges'),
          ),
        ],
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PulseChip({
    required this.dotColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const Gap(8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
