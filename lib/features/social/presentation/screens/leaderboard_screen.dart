import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/friends_leaderboard.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

export 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart'
    show TribeStats;

class LeaderboardScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const LeaderboardScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'LEADERBOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.backgroundDark,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondaryDark,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'FRIENDS'),
                    Tab(text: 'TRIBE'),
                    Tab(text: 'WORLD'),
                  ],
                ),
                const Gap(16),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FriendsLeaderboardTab(),
                _TribeLeaderboardTab(),
                _WorldLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersListProvider);

    return partnersAsync.when(
      data: (partners) {
        if (partners.isEmpty) {
          return const Center(
            child: Text(
              'No partners found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final entries = partners.map((p) {
          return FriendRankEntry(
            id: p.id,
            name: p.name,
            xp: p.xp,
            streak: p.streak,
            isYou: false,
          );
        }).toList();

        // Sort by XP
        entries.sort((a, b) => b.xp.compareTo(a.xp));

        return SingleChildScrollView(
          child: FriendsLeaderboard(friends: entries),
        );
      },
      loading: () =>
          const EmergeLoadingSkeleton(itemCount: 8, showAvatar: true),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load partners',
        onRetry: () => ref.invalidate(partnersListProvider),
      ),
    );
  }
}

class _TribeLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    return userStatsAsync.when(
      data: (profile) {
        if (profile.uid.isEmpty) {
          return const Center(
            child: Text(
              'No profile found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final clubId = profile.archetype.name;
        final leaderboardAsync = ref.watch(clubLeaderboardProvider(clubId));

        return Column(
          children: [
            // Tribe Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    profile.archetype.color.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: profile.archetype.color.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      profile.archetype.icon,
                      color: profile.archetype.color,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.archetype.name.toUpperCase()} TRIBE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Ranked by lifetime XP contribution',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: leaderboardAsync.when(
                data: (entries) => _LeaderboardList(entries: entries),
                loading: () =>
                    const EmergeLoadingSkeleton(itemCount: 5, showAvatar: true),
                error: (err, _) => AppErrorWidget(
                  message: 'Could not load tribe leaderboard',
                  onRetry: () =>
                      ref.invalidate(clubLeaderboardProvider(clubId)),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 1),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load user profile',
        onRetry: () => ref.invalidate(userStatsStreamProvider),
      ),
    );
  }
}

class _WorldLeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);

    return tribesAsync.when(
      data: (tribes) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tribes.length,
          itemBuilder: (context, index) {
            final tribe = tribes[index];
            // Watch real-time stats for each tribe
            final statsAsync = ref.watch(realTimeTribeStatsProvider(tribe.id));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: statsAsync.when(
                data: (stats) {
                  // Sort by real-time total XP
                  final sortedIndex = tribes.indexWhere(
                    (t) => t.id == tribe.id,
                  );
                  return _TribeLeaderboardItem(
                    tribe: tribe,
                    stats: stats,
                    rank: sortedIndex + 1,
                  );
                },
                loading: () => _TribeLeaderboardItem(
                  tribe: tribe,
                  stats: TribeStats(
                    memberCount: 0,
                    totalXp: 0,
                    totalHabitsCompleted: 0,
                    totalChallengesCompleted: 0,
                  ),
                  rank: index + 1,
                  isLoading: true,
                ),
                error: (_, _) => _TribeLeaderboardItem(
                  tribe: tribe,
                  stats: TribeStats(
                    memberCount: 0,
                    totalXp: 0,
                    totalHabitsCompleted: 0,
                    totalChallengesCompleted: 0,
                  ),
                  rank: index + 1,
                  isError: true,
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const EmergeLoadingSkeleton(itemCount: 5, showAvatar: true),
      error: (err, _) => AppErrorWidget(
        message: 'Could not load world rankings',
        onRetry: () => ref.invalidate(allArchetypeClubsProvider),
      ),
    );
  }
}

class _TribeLeaderboardItem extends StatelessWidget {
  final dynamic tribe;
  final TribeStats stats;
  final int rank;
  final bool isLoading;
  final bool isError;

  const _TribeLeaderboardItem({
    required this.tribe,
    required this.stats,
    required this.rank,
    this.isLoading = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayXp = isLoading
        ? '...'
        : isError
        ? 'Error'
        : '${stats.totalXp} XP';
    final displayMembers = isLoading
        ? '...'
        : isError
        ? 'Error'
        : '${stats.memberCount} members';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(
              color: rank <= 3 ? AppTheme.primary : AppTheme.textSecondaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Gap(16),
          CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.shield, color: AppTheme.primary, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tribe.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  displayMembers,
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayXp,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LEVEL ${tribe.level}',
                style: TextStyle(
                  color: AppTheme.textSecondaryDark,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<dynamic> entries;

  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries yet', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index < 3
                          ? AppTheme.primary
                          : AppTheme.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    entry.userName.isNotEmpty
                        ? entry.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Level ${entry.level}',
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.xp} XP',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
