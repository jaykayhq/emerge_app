import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_header_widgets.dart';

class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const LeaderboardRow({super.key, required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? EmergeColors.yellow : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(8),
          CircleAvatar(
            radius: 16,
            backgroundColor: EmergeColors.teal.withValues(alpha: 0.2),
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
              style: TextStyle(
                color: EmergeColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              entry.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: const TextStyle(
                  color: EmergeColors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Level ${entry.level}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorldRankingRow extends StatelessWidget {
  final Tribe club;
  final int rank;

  const _WorldRankingRow({required this.club, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? EmergeColors.yellow : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(8),
          CircleAvatar(
            radius: 16,
            backgroundColor: EmergeColors.violet.withValues(alpha: 0.2),
            child: Icon(Icons.shield, size: 16, color: EmergeColors.violet),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              club.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${club.totalXp} XP',
                style: const TextStyle(
                  color: EmergeColors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${club.memberCount} members',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorldLeaderboardSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldAsync = ref.watch(worldLeaderboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.public, size: 18, color: EmergeColors.teal),
                Gap(8),
                Text(
                  'WORLD RANKINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/social/leaderboard?tab=world'),
              child: const Text(
                'View All >',
                style: TextStyle(fontSize: 12, color: EmergeColors.teal),
              ),
            ),
          ],
        ),
        const Gap(16),
        worldAsync.when(
          data: (entries) {
            if (entries.isEmpty) return const SizedBox.shrink();
            final top = entries.length > 5 ? entries.sublist(0, 5) : entries;
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map(
                    (e) =>
                        _WorldRankingRow(club: e.value.tribe, rank: e.key + 1)
                            .animate(delay: (e.key * 50).ms)
                            .fadeIn()
                            .slideX(begin: 0.03),
                  )
                  .toList(),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 3),
          error: (err, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class TribeLeaderboardSection extends ConsumerWidget {
  final String clubId;
  final String archetypeName;
  final bool isGlobal;

  /// Member ids of the tribe. When non-empty, users who left are hidden
  /// from the ranking display (history kept — B10). Empty = unfiltered.
  final List<String> members;

  const TribeLeaderboardSection({
    super.key,
    required this.clubId,
    required this.archetypeName,
    this.isGlobal = false,
    this.members = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGlobal) {
      return _WorldLeaderboardSection();
    }

    final leaderboardAsync = ref.watch(clubLeaderboardProvider(clubId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard,
                  size: 18,
                  color: EmergeColors.yellow,
                ),
                const Gap(8),
                Text(
                  '${archetypeName.toUpperCase()} TRIBE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/social/leaderboard?tab=tribe'),
              child: const Text(
                'View All >',
                style: TextStyle(fontSize: 12, color: EmergeColors.teal),
              ),
            ),
          ],
        ),
        const Gap(16),
        leaderboardAsync.when(
          data: (entries) {
            final visible = members.isEmpty
                ? entries
                : entries.where((e) => members.contains(e.userId)).toList();
            if (visible.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmergeColors.glassWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergeColors.glassBorder),
                ),
                child: const Center(
                  child: Text(
                    'No rankings yet. Complete habits to earn XP!',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }
            final top = visible.length > 5 ? visible.sublist(0, 5) : visible;
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map(
                    (e) => LeaderboardRow(entry: e.value, rank: e.key + 1)
                        .animate(delay: (e.key * 50).ms)
                        .fadeIn()
                        .slideX(begin: 0.03),
                  )
                  .toList(),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 3),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class TribeMembersTab extends ConsumerStatefulWidget {
  const TribeMembersTab({super.key});

  @override
  ConsumerState<TribeMembersTab> createState() => _TribeMembersTabState();
}

class _TribeMembersTabState extends ConsumerState<TribeMembersTab> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);
    final activeMembership = ref.watch(activeMembershipProvider).value;

    return clubsAsync.when(
      data: (clubs) {
        return profileAsync.when(
          data: (profile) {
            if (activeMembership == null) {
              return const Center(
                child: Text(
                  'No active tribe',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final tribeId = activeMembership.tribeId;
            final userClub = clubs.where((c) => c.id == tribeId).firstOrNull;

            if (userClub == null) {
              return const Center(
                child: Text(
                  'No clubs available for your archetype yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return _buildMembersTab(userClub, profile);
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 1),
          error: (error, stack) => AppErrorWidget(
            message: 'Could not load your profile',
            onRetry: () => ref.invalidate(userStatsStreamProvider),
          ),
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 5),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load tribes',
        onRetry: () => ref.invalidate(allArchetypeClubsProvider),
      ),
    );
  }

  Widget _buildMembersTab(Tribe userClub, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          ContributorsSection(
            clubId: userClub.id,
            members: userClub.members,
          ).animate().fadeIn(delay: 300.ms),
          const Gap(32),
          TribeLeaderboardSection(
            clubId: userClub.id,
            archetypeName: profile.archetype.name,
            isGlobal: false,
            members: userClub.members,
          ).animate().fadeIn(delay: 370.ms),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/social/all'),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('SEE ALL TRIBES'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const Gap(32),
        ],
      ),
    );
  }
}
