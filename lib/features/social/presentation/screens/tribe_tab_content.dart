import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Tribe Tab Content - Shared between CommunityScreen (tab) and TribesScreen (standalone)
class TribeTabContent extends ConsumerStatefulWidget {
  const TribeTabContent({super.key});

  @override
  ConsumerState<TribeTabContent> createState() => _TribeTabContentState();
}

class _TribeTabContentState extends ConsumerState<TribeTabContent> {
  bool _showGlobalActivity = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        return profileAsync.when(
          data: (profile) {
            final theme = ArchetypeTheme.forArchetype(profile.archetype);

            // Find the club that matches the user's archetype
            final userClub = clubs.isNotEmpty
                ? clubs.firstWhere(
                    (club) => club.archetypeId == profile.archetype.name,
                  )
                : null;

            if (userClub == null) {
              return const _EmptyState(
                message: 'No clubs available for your archetype yet.',
                icon: Icons.groups,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Gap(16),

                  // ===== CLUB EMBLEM (Archetype-colored) =====
                  _ArchetypeClubEmblem(
                    theme: theme,
                  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                  const Gap(16),

                  // ===== CLUB NAME & SUBTITLE =====
                  Text(
                    userClub.name.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const Gap(4),
                  Text(
                    userClub.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ).animate().fadeIn(delay: 150.ms),

                  const Gap(16),

                  // ===== MEMBER COUNT =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, color: theme.primaryColor, size: 16),
                      const Gap(4),
                      Text(
                        '${userClub.memberCount} Members',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const Gap(32),

                  // ===== TOP CONTRIBUTORS =====
                  _ContributorsSection(
                    clubId: userClub.id,
                  ).animate().fadeIn(delay: 300.ms),

                  const Gap(32),

                  // ===== PROGRESS METRICS =====
                  _TribeProgressMetrics(
                    isGlobal: _showGlobalActivity,
                    tribeStats: userClub, // Use tribe totalXp
                  ).animate().fadeIn(delay: 350.ms),

                  const Gap(32),

                  // ===== ACTIVITY FEED HEADER CON toggle =====
                  Row(
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
                  ).animate().fadeIn(delay: 400.ms),

                  const Gap(16),

                  // ===== ACTIVITY FEED =====
                  _ActivitySection(
                    clubId: _showGlobalActivity ? null : userClub.id,
                    isGlobal: _showGlobalActivity,
                  ).animate().fadeIn(delay: 500.ms),

                  const Gap(32),
                ],
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
    );
  }
}

// ============ CLUB EMBLEM (Centered, glowing ring) ============

class _ArchetypeClubEmblem extends StatelessWidget {
  final ArchetypeTheme theme;

  const _ArchetypeClubEmblem({required this.theme});

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
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EmergeColors.background,
        ),
        child: Icon(theme.journeyIcon, size: 42, color: theme.primaryColor),
      ),
    );
  }
}

// ============ TOP CONTRIBUTORS (Overlapping avatars) ============

class _ContributorsSection extends ConsumerWidget {
  final String clubId;

  const _ContributorsSection({required this.clubId});

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
                  child: Text(
                    'View All >',
                    style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Overlapping avatars row - horizontally scrollable
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
                    child: _ContributorAvatar(
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
      loading: () => const EmergeLoadingSkeleton(
        itemCount: 3,
        showAvatar: true,
        itemHeight: 60,
      ),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load contributors',
        onRetry: () => ref.invalidate(clubContributorsProvider(clubId)),
      ),
    );
  }
}

class _ContributorAvatar extends ConsumerWidget {
  final String userId;
  final String name;
  final int xp;
  final int rank;

  const _ContributorAvatar({
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

// ============ PROGRESS METRICS ============

class _TribeProgressMetrics extends ConsumerWidget {
  final bool isGlobal;
  final Tribe tribeStats;

  const _TribeProgressMetrics({
    required this.isGlobal,
    required this.tribeStats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpScore = tribeStats.totalXp;

    // Fetch real aggregate stats from the tribe document
    final tribeDocAsync = ref.watch(
      tribeAggregateProvider(tribeStats.id),
    );

    final habitsCount = tribeDocAsync.when(
      data: (data) => data['totalHabitsCompleted'] as int? ?? 0,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final questsCount = tribeDocAsync.when(
      data: (data) => data['totalChallengesCompleted'] as int? ?? 0,
      loading: () => 0,
      error: (_, _) => 0,
    );

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
              _StatOrb(
                label: 'Total XP',
                value:
                    '${xpScore >= 1000 ? '${(xpScore / 1000).toStringAsFixed(1)}k' : xpScore}',
                color: EmergeColors.yellow,
                icon: Icons.electric_bolt,
              ),
              _StatOrb(
                label: isGlobal ? 'Habits Overcome' : 'Habits Conquered',
                value: _formatCount(habitsCount),
                color: EmergeColors.teal,
                icon: Icons.check_circle_outline,
              ),
              _StatOrb(
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
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

class _StatOrb extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatOrb({
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
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
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

// ============ RECENT ACTIVITY (Simple list, no heavy cards) ============

class _ActivitySection extends ConsumerWidget {
  final String? clubId;
  final bool isGlobal;

  const _ActivitySection({this.clubId, this.isGlobal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = isGlobal
        ? ref.watch(globalActivityProvider)
        : ref.watch(clubActivityProvider(clubId!));

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: activities.map((activity) {
            return _ActivityTile(activity: activity);
          }).toList(),
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 5),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load activity',
        onRetry: () {
          if (isGlobal) {
            ref.invalidate(globalActivityProvider);
          } else {
            ref.invalidate(clubActivityProvider(clubId!));
          }
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] as String? ?? 'unknown';
    final userName = activity['userName'] as String? ?? 'Someone';
    final data = activity['data'] as Map<String, dynamic>? ?? {};
    final actionText = _buildActionText(type, data);
    final timestamp = activity['timestamp'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getActivityIcon(type), style: const TextStyle(fontSize: 20)),
          const Gap(12),
          Expanded(
            child: Text(
              '$userName $actionText',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (timestamp != null)
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _buildActionText(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'habit_complete':
        final title = data['habitTitle'] as String? ?? 'a habit';
        final streak = data['streakDay'] as int? ?? 0;
        return streak > 1
            ? 'completed $title (Day $streak 🔥)'
            : 'completed $title';
      case 'challenge_complete':
        final title = data['challengeTitle'] as String? ?? 'a challenge';
        return 'conquered $title 🏆';
      case 'level_up':
        final level = data['newLevel'] as int? ?? 0;
        return 'reached Level $level!';
      case 'streak_milestone':
        final streak = data['streakDays'] as int? ?? 0;
        return 'hit a $streak-day streak! 🔥';
      case 'node_claim':
        final nodeName = data['nodeName'] as String? ?? 'a node';
        return 'claimed the $nodeName! 🏰';
      default:
        return 'did something';
    }
  }

  String _getActivityIcon(String type) {
    switch (type) {
      case 'habit_complete':
        return '✅';
      case 'level_up':
        return '🎖️';
      case 'challenge_complete':
        return '🏆';
      case 'badge_earned':
        return '🎖️';
      case 'streak_milestone':
        return '🔥';
      case 'club_goal':
        return '🎯';
      case 'member_joined':
        return '👋';
      default:
        return '📌';
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final activityTime = timestamp.toDate();
    final difference = now.difference(activityTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${activityTime.day}/${activityTime.month}';
    }
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
