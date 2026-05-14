import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';

// ============ CLUB EMBLEM (Centered, glowing ring) ============

class ArchetypeClubEmblem extends StatelessWidget {
  final ArchetypeTheme theme;

  const ArchetypeClubEmblem({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor, theme.accentColor],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EmergeColors.background,
        ),
        child: Center(
          child: Text(theme.emoji, style: const TextStyle(fontSize: 42)),
        ),
      ),
    );
  }
}

// ============ REAL-TIME MEMBER COUNT ============

class RealTimeMemberCount extends ConsumerWidget {
  final String tribeId;

  const RealTimeMemberCount({super.key, required this.tribeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribeId));

    return statsAsync.when(
      data: (stats) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: Theme.of(context).primaryColor, size: 16),
            const Gap(4),
            Text(
              '${stats.memberCount} Members',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
      loading: () =>
          const SkeletonShimmer(width: 80, height: 16, borderRadius: 4),
      error: (error, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, color: Theme.of(context).primaryColor, size: 16),
          const Gap(4),
          const Text(
            '-- Members',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ REAL-TIME PROGRESS METRICS ============

class RealTimeTribeProgressMetrics extends ConsumerWidget {
  final bool isGlobal;
  final String tribeId;
  final ArchetypeTheme theme;

  const RealTimeTribeProgressMetrics({
    super.key,
    required this.isGlobal,
    required this.tribeId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedTribeStatsProvider(tribeId));

    return statsAsync.when(
      data: (stats) {
        final xpScore = stats.totalXp;
        final habitsCount = stats.totalHabitsCompleted;
        final questsCount = stats.totalChallengesCompleted;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EmergeColors.glassWhite.withValues(alpha: 0.1),
                EmergeColors.glassWhite.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmergeColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGlobal ? Icons.public : Icons.local_fire_department,
                    color: isGlobal ? EmergeColors.teal : EmergeColors.coral,
                    size: 20,
                  ),
                  const Gap(8),
                  Text(
                    isGlobal ? 'Global Collective Power' : 'Tribe Ascendancy',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatOrb(
                    label: 'Total XP',
                    value:
                        '${xpScore >= 1000 ? '${(xpScore / 1000).toStringAsFixed(1)}k' : xpScore}',
                    color: EmergeColors.yellow,
                    icon: Icons.electric_bolt,
                  ),
                  StatOrb(
                    label: isGlobal ? 'Habits Overcome' : 'Habits Conquered',
                    value: _formatCount(habitsCount),
                    color: EmergeColors.teal,
                    icon: Icons.check_circle_outline,
                  ),
                  StatOrb(
                    label: 'Quests Beaten',
                    value: _formatCount(questsCount),
                    color: EmergeColors.violet,
                    icon: Icons.emoji_events,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _MetricsLoadingState(),
      error: (error, _) => _MetricsErrorState(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

class StatOrb extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatOrb({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),

        const Gap(8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppTheme.textSecondaryDark,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ============ TOP CONTRIBUTORS ============

class ContributorsSection extends ConsumerWidget {
  final String clubId;

  const ContributorsSection({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributorsAsync = ref.watch(clubContributorsProvider(clubId));

    return contributorsAsync.when(
      data: (contributors) {
        if (contributors.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Contributors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/tribes/leaderboard?tab=tribe'),
                  child: const Text(
                    'View All >',
                    style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                  ),
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: contributors.length,
                itemBuilder: (context, index) {
                  final c = contributors[index];
                  final name = c['userName'] as String? ?? 'User';
                  final xp = c['contributionCount'] as int? ?? 0;

                  return Transform.translate(
                    offset: Offset(index == 0 ? 0 : -index * 15.0, 0),
                    child: ContributorAvatar(
                      userId: c['id'] as String? ?? '',
                      name: name,
                      xp: xp,
                      rank: index + 1,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const _ContributorsShimmer(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}

class ContributorAvatar extends ConsumerWidget {
  final String userId;
  final String name;
  final int xp;
  final int rank;

  const ContributorAvatar({
    super.key,
    required this.userId,
    required this.name,
    required this.xp,
    required this.rank,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(userOnlineStatusProvider(userId)).value ?? false;
    final isTopThree = rank <= 3;
    final statusText = isTopThree ? 'Top $rank' : '${xp}XP';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isTopThree
                        ? EmergeColors.yellow.withValues(alpha: 0.8)
                        : EmergeColors.violet.withValues(alpha: 0.6),
                    EmergeColors.teal.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(color: EmergeColors.background, width: 3),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: EmergeColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EmergeColors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
            if (isTopThree)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: EmergeColors.background,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Gap(4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 9,
            color: isOnline
                ? EmergeColors.teal
                : isTopThree
                ? EmergeColors.yellow
                : AppTheme.textSecondaryDark,
            fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return EmergeColors.yellow;
      case 2:
        return Colors.grey.shade300;
      case 3:
        return Colors.brown.shade400;
      default:
        return EmergeColors.violet;
    }
  }
}

class _MetricsLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const SkeletonShimmer(width: 120, height: 20),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  const SkeletonShimmer.circular(size: 48),
                  const Gap(8),
                  const SkeletonShimmer(width: 40, height: 16),
                  const Gap(4),
                  const SkeletonShimmer(width: 60, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorsShimmer extends StatelessWidget {
  const _ContributorsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonShimmer(width: 100, height: 20),
        const Gap(16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  const SkeletonShimmer.circular(size: 50),
                  const Gap(4),
                  const SkeletonShimmer(width: 40, height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricsErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: AppErrorWidget(message: 'Error loading metrics'),
      ),
    );
  }
}
