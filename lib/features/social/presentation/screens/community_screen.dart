import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Community Screen - Stitch Design "Identity Club Home"
/// Features: Club stats card, Weekly goal, Top contributors, Activity feed
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_isSearching)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: EmergeColors.glassWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EmergeColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search friends & clubs...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'TRIBES',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textMainDark,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: EmergeColors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isSearching) {
                            _isSearching = false;
                            _searchController.clear();
                          } else {
                            _isSearching = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: EmergeColors.glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EmergeColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: EmergeColors.teal,
                  unselectedLabelColor: AppTheme.textSecondaryDark,
                  indicatorColor: EmergeColors.teal,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Challenges'),
                    Tab(text: 'Clubs'),
                    Tab(text: 'Friends'),
                  ],
                ),
              ),

              const Gap(16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const ChallengesTabContent(),
                    _buildClubsTab(),
                    const FriendsTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CLUBS TAB - Fixed Archetype Club
  // ==========================================================================

  String _getClubId(UserArchetype archetype) {
    return '${archetype.name}_club';
  }

  Widget _buildClubsTab() {
    final profileAsync = ref.watch(userStatsStreamProvider);

    return profileAsync.when(
      data: (profile) {
        final theme = ArchetypeTheme.forArchetype(profile.archetype);
        final clubId = _getClubId(profile.archetype);

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
                'THE ${theme.archetypeName.toUpperCase()}S',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const Gap(4),
              Text(
                theme.tagline,
                style: TextStyle(fontSize: 14, color: theme.primaryColor),
              ).animate().fadeIn(delay: 150.ms),

              const Gap(32),

              // ===== ARCHETYPE STATS =====
              _ArchetypeStatsRow(
                theme: theme,
                profile: profile,
              ).animate().fadeIn(delay: 200.ms),

              const Gap(32),

              // ===== TOP CONTRIBUTORS =====
              _ContributorsSection(clubId: clubId).animate().fadeIn(delay: 300.ms),

              const Gap(32),

              // ===== RECENT ACTIVITY =====
              _ActivitySection(clubId: clubId).animate().fadeIn(delay: 400.ms),

              const Gap(32),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: EmergeColors.teal),
      ),
      error: (error, stack) => _ErrorState(error: error.toString()),
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

// ============ ARCHETYPE STATS ROW ============

class _ArchetypeStatsRow extends StatelessWidget {
  final ArchetypeTheme theme;
  final UserProfile profile;

  const _ArchetypeStatsRow({required this.theme, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(
            label: 'Your Level',
            value: '${profile.avatarStats.level}',
            trend: '↗',
            trendColor: theme.primaryColor,
          ),
          Container(width: 1, height: 50, color: EmergeColors.glassBorder),
          _StatColumn(
            label: 'Streak',
            value: '${profile.avatarStats.streak}',
            trend: '🔥',
            trendColor: theme.accentColor,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color trendColor;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.7),
          ),
        ),
        const Gap(4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
          ],
        ),
      ],
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
                Text(
                  'View All >',
                  style: TextStyle(fontSize: 12, color: EmergeColors.teal),
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
                  final name = c['displayName'] as String? ?? 'User';
                  final xp = c['contributionCount'] as int? ?? 0;
                  final isOnline = c['isOnline'] as bool? ?? false;

                  return Transform.translate(
                    offset: Offset(index == 0 ? 0 : -index * 15.0, 0),
                    child: _ContributorAvatar(
                      name: name,
                      xp: xp,
                      isOnline: isOnline,
                      rank: index + 1,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
      ),
      error: (error, _) => _SectionErrorState(
        message: 'Failed to load contributors',
        onRetry: () => ref.invalidate(clubContributorsProvider(clubId)),
      ),
    );
  }
}

class _ContributorAvatar extends StatelessWidget {
  final String name;
  final int xp;
  final bool isOnline;
  final int rank;

  const _ContributorAvatar({
    required this.name,
    required this.xp,
    required this.isOnline,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

// ============ RECENT ACTIVITY (Simple list, no heavy cards) ============

class _ActivitySection extends ConsumerWidget {
  final String clubId;

  const _ActivitySection({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivityProvider(clubId));

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(16),

            ...activities.map((activity) {
              return _ActivityTile(activity: activity);
            }),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
      ),
      error: (error, _) => _SectionErrorState(
        message: 'Failed to load activity',
        onRetry: () => ref.invalidate(clubActivityProvider(clubId)),
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
    final actionText = activity['actionText'] as String? ?? 'did something';
    final timestamp = activity['timestamp'] as Timestamp?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getActivityIcon(type),
            style: const TextStyle(fontSize: 20),
          ),
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

class _SectionErrorState extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_outlined, size: 24, color: EmergeColors.coral),
          const Gap(8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          const Gap(8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: EmergeColors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: EmergeColors.coral),
            const Gap(16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: EmergeColors.coral,
              ),
            ),
            const Gap(8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
