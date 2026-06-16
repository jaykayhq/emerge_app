import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';

import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import '../widgets/tribe_header_widgets.dart';
import '../widgets/tribe_quests_section.dart';
import '../widgets/tribe_activity_feed.dart';
import '../widgets/tribe_accountability_section.dart';

/// Tribe Tab Content - Shared between CommunityScreen (tab) and TribesScreen (standalone)
class TribeTabContent extends ConsumerStatefulWidget {
  const TribeTabContent({super.key});

  @override
  ConsumerState<TribeTabContent> createState() => _TribeTabContentState();
}

class _TribeTabContentState extends ConsumerState<TribeTabContent> {
  bool _showGlobalActivity = false;
  final GlobalKey _emblemKey = GlobalKey();
  final GlobalKey _bondsKey = GlobalKey();
  final GlobalKey _feedKey = GlobalKey();

  bool _showFirstVisitGuide = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/tribes')) {
        repo.markVisited('/tribes');
        ref
            .read(companionEngineProvider.notifier)
            .triggerEvent(
              eventType: CompanionEventType.firstFeatureVisit,
              userContext: {'route': '/tribes'},
            );
        setState(() => _showFirstVisitGuide = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return Stack(
      children: [
        clubsAsync.when(
          data: (clubs) {
            return profileAsync.when(
              data: (profile) {
                final theme = ArchetypeTheme.forArchetype(profile.archetype);

                // Find the club that matches the user's archetype
                // First try exact archetype match, then fall back to multi-archetype clubs
                final matchingIndex = clubs.isNotEmpty
                    ? clubs.indexWhere(
                        (club) => club.archetypeId == profile.archetype.name,
                      )
                    : -1;
                final userClub = matchingIndex != -1
                    ? clubs[matchingIndex]
                    : clubs
                          .where(
                            (club) =>
                                club.archetypeId == null ||
                                club.archetypeId!.isEmpty,
                          )
                          .firstOrNull;

                if (userClub == null) {
                  return const _EmptyState(
                    message: 'No clubs available for your archetype yet.',
                    icon: Icons.groups,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allArchetypeClubsProvider);
                    ref.invalidate(userStatsStreamProvider);
                  },
                  color: EmergeColors.teal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Gap(16),

                        // ===== CLUB EMBLEM (Archetype-colored) =====
                        ArchetypeClubEmblem(
                          key: _emblemKey,
                          theme: theme,
                        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                        const Gap(16),

                        // ===== CLUB NAME & SUBTITLE =====
                        Text(
                          userClub.name.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                        ).animate().fadeIn(delay: 100.ms),
                        const Gap(4),
                        Text(
                          userClub.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ).animate().fadeIn(delay: 150.ms),

                        const Gap(16),

                        // ===== MEMBER COUNT (Real-time from members array) =====
                        RealTimeMemberCount(
                          tribeId: userClub.id,
                        ).animate().fadeIn(delay: 200.ms),

                        const Gap(32),

                        // ===== TOP CONTRIBUTORS =====
                        ContributorsSection(
                          clubId: userClub.id,
                        ).animate().fadeIn(delay: 300.ms),

                        const Gap(32),

                        // ===== PROGRESS METRICS (Real-time stats) =====
                        RealTimeTribeProgressMetrics(
                          isGlobal: _showGlobalActivity,
                          tribeId: userClub.id,
                          theme: theme,
                        ).animate().fadeIn(delay: 350.ms),

                        const Gap(32),

                        // ===== LEADERBOARD =====
                        _TribeLeaderboardSection(
                          clubId: userClub.id,
                          archetypeName: profile.archetype.name,
                          isGlobal: _showGlobalActivity,
                        ).animate().fadeIn(delay: 370.ms),

                        const Gap(32),

                        TribeAccountabilitySection(
                          key: _bondsKey,
                        ).animate().fadeIn(delay: 400.ms),

                        const Gap(32),

                        // ===== ACTIVE QUESTS =====
                        const TribeQuestsSection().animate().fadeIn(delay: 450.ms),

                        const Gap(32),

                        // ===== ACTIVITY FEED HEADER CON toggle =====
                        Row(
                          key: _feedKey,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _showGlobalActivity
                                  ? 'Global Activity'
                                  : 'Recent Activity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: EmergeColors.glassWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EmergeColors.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  _ToggleItem(
                                    label: 'Tribe',
                                    isSelected: !_showGlobalActivity,
                                    onTap: () =>
                                        setState(() => _showGlobalActivity = false),
                                  ),
                                  _ToggleItem(
                                    label: 'Global',
                                    isSelected: _showGlobalActivity,
                                    onTap: () =>
                                        setState(() => _showGlobalActivity = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 500.ms),

                        const Gap(16),

                        // ===== ACTIVITY FEED =====
                        TribeActivitySection(
                          clubId: _showGlobalActivity ? null : userClub.id,
                          isGlobal: _showGlobalActivity,
                        ).animate().fadeIn(delay: 550.ms),

                        const Gap(32),

                        // ===== SEE ALL TRIBES =====
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/social/all'),
                            icon: const Icon(Icons.explore_outlined, size: 20),
                            label: const Text('SEE ALL'),
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

                        const Gap(48),
                      ],
                    ),
                  ),
                );
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
        ),
        if (_showFirstVisitGuide)
          FeatureCoachMark(
            title: "Tribe Sanctum",
            primaryColor: EmergeColors.green,
            items: const [
              CoachItemData(
                icon: Icons.shield_outlined,
                title: "Tribe Momentum Score",
                body: "Check your team's current weekly momentum, active members, and territory tier.",
              ),
              CoachItemData(
                icon: Icons.people_outline,
                title: "Tribe Accountability",
                body: "Track who completed which habits today and maintain your collective streak.",
              ),
            ],
            onDismiss: () => setState(() => _showFirstVisitGuide = false),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmergeColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// ============ LEADERBOARD SECTION ============

class _TribeLeaderboardSection extends ConsumerWidget {
  final String clubId;
  final String archetypeName;
  final bool isGlobal;

  const _TribeLeaderboardSection({
    required this.clubId,
    required this.archetypeName,
    this.isGlobal = false,
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
            if (entries.isEmpty) {
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
            final top = entries.length > 5 ? entries.sublist(0, 5) : entries;
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map(
                    (e) => _LeaderboardRow(entry: e.value, rank: e.key + 1)
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

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const _LeaderboardRow({required this.entry, required this.rank});

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
