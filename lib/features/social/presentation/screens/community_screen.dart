import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/data/repositories/social_repository.dart'
    hide tribesProvider;
import 'package:emerge_app/features/social/presentation/widgets/challenge_card.dart';
import 'package:emerge_app/features/social/presentation/widgets/club_card.dart';
import 'package:emerge_app/features/social/presentation/widgets/friends_leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

import 'package:emerge_app/features/social/presentation/screens/create_tribe_screen.dart';

/// Sweatcoin-inspired Community Screen with 3 tabs:
/// - Challenges (sponsored + community)
/// - Clubs (former Tribes)
/// - Friends (leaderboard)
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search friends & clubs...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Community',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondaryDark,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Challenges'),
            Tab(text: 'Clubs'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChallengesTab(), _buildClubsTab(), _buildFriendsTab()],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        if (_tabController.index == 2) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: 'community_fab',
          onPressed: () {
            if (_tabController.index == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Challenge coming soon!')),
              );
            } else if (_tabController.index == 1) {
              _createClub(context, ref);
            }
          },
          label: Text(
            _tabController.index == 0 ? 'Create Challenge' : 'Create Club',
          ),
          icon: const Icon(Icons.add),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
        ).animate().scale();
      },
    );
  }

  void _createClub(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a club.')),
      );
      return;
    }

    final userStatsAsync = ref.read(userStatsStreamProvider);
    userStatsAsync.when(
      data: (stats) {
        if (stats.avatarStats.level >= 5) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTribeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Level 5 required. Current: ${stats.avatarStats.level}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      loading: () {},
      error: (e, s) {},
    );
  }

  // ==========================================================================
  // CHALLENGES TAB
  // ==========================================================================
  Widget _buildChallengesTab() {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
        // Mock sponsored challenges for demo
        final sponsoredChallenges = [
          ChallengeCard(
            id: 'sponsored-1',
            title: '30-Day Running Streak',
            description: 'Run at least 1 mile every day for 30 days straight.',
            xpReward: 500,
            daysRemaining: 30,
            sponsorName: 'Nike',
            prizeDescription: '20% Off',
            onJoin: () => _onJoinChallenge('sponsored-1'),
          ),
          ChallengeCard(
            id: 'sponsored-2',
            title: '21-Day Meditation Practice',
            description: 'Meditate for at least 10 minutes daily for 21 days.',
            xpReward: 300,
            daysRemaining: 21,
            sponsorName: 'Headspace',
            prizeDescription: '30 Days Free',
            onJoin: () => _onJoinChallenge('sponsored-2'),
          ),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Featured Challenges Header
            _SectionHeader(title: 'Featured Challenges', onSeeAll: () {}),
            const Gap(12),
            // Sponsored
            ...sponsoredChallenges.map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
            ),
            const Gap(8),
            // Community Challenges
            _SectionHeader(title: 'Community Challenges', onSeeAll: () {}),
            const Gap(12),
            if (challenges.isEmpty)
              const _EmptyState(
                message: 'No active challenges.',
                icon: Icons.emoji_events_outlined,
              )
            else
              ...challenges.map(
                (challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChallengeCard(
                    id: challenge.id,
                    title: challenge.title,
                    description: challenge.description,
                    xpReward: 100,
                    daysRemaining: challenge.daysLeft,
                    onJoin: () => _onJoinChallenge(challenge.id),
                  ),
                ),
              ),
            const Gap(80), // FAB spacing
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(error: err.toString()),
    );
  }

  void _onJoinChallenge(String challengeId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Joined challenge: $challengeId')));
  }

  // ==========================================================================
  // CLUBS TAB
  // ==========================================================================
  Widget _buildClubsTab() {
    final tribesAsync = ref.watch(tribesProvider);

    return tribesAsync.when(
      data: (tribes) {
        final featuredClubs = tribes.take(5).toList();
        final leaderboardClubs = List<Tribe>.from(tribes)
          ..sort((a, b) => b.totalXp.compareTo(a.totalXp));

        if (tribes.isEmpty) {
          return _EmptyState(
            message: 'No clubs found.',
            icon: Icons.groups_outlined,
            onAction: () => _createClub(context, ref),
            actionLabel: 'Create First Club',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: 'Featured Clubs', onSeeAll: () {}),
            const Gap(12),
            // Horizontal Club Cards - remove fixed height to prevent overflow
            SizedBox(
              height: 220, // Adjusted to match actual card content height
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredClubs.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final club = featuredClubs[index];
                  return ClubCard(
                    id: club.id,
                    name: club.name,
                    coverImageUrl: club.imageUrl,
                    memberCount: club.memberCount,
                    totalXp: club.totalXp,
                    isVerified: club.memberCount > 100,
                    onJoin: () => _onJoinClub(club.id),
                  );
                },
              ),
            ),
            const Gap(24),
            _SectionHeader(title: 'Top Clubs', onSeeAll: () {}),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboardClubs.take(10).length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                return _ClubLeaderboardItem(
                  rank: index + 1,
                  tribe: leaderboardClubs[index],
                );
              },
            ),
            const Gap(80), // Fab spacing
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
    );
  }

  void _onJoinClub(String clubId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Joined club: $clubId')));
  }

  // ==========================================================================
  // FRIENDS TAB (Updated with Search)
  // ==========================================================================
  Widget _buildFriendsTab() {
    final userAsync = ref.watch(userStatsStreamProvider);

    return userAsync.when(
      data: (profile) {
        // Mock friends for demo
        final mockFriends = [
          FriendRankEntry(id: '1', name: 'Sarah Chen', xp: 4520, streak: 21),
          FriendRankEntry(id: '2', name: 'Mike Johnson', xp: 3800, streak: 14),
          FriendRankEntry(
            id: 'me',
            name: profile.archetype != UserArchetype.none
                ? profile.archetype.name
                : 'You',
            xp: profile.avatarStats.totalXp,
            streak: profile.avatarStats.streak,
            isYou: true,
          ),
          const FriendRankEntry(
            id: '3',
            name: 'Emma Wilson',
            xp: 2100,
            streak: 7,
          ),
          const FriendRankEntry(
            id: '4',
            name: 'Alex Park',
            xp: 1850,
            streak: 5,
          ),
        ];

        // Filter friends based on search query
        final filteredFriends = mockFriends.where((f) {
          return f.name.toLowerCase().contains(_searchQuery);
        }).toList();

        // Sort descending by XP
        filteredFriends.sort((a, b) => b.xp.compareTo(a.xp));

        if (filteredFriends.isEmpty) {
          return const _EmptyState(
            message: 'No friends found.',
            icon: Icons.search_off,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: FriendsLeaderboard(
            friends: filteredFriends,
            onAddFriend: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add friend coming soon!')),
              );
            },
            onShareLink: () {
              // ignore: deprecated_member_use
              Share.share(
                'Join me on Emerge and level up your habits! 🚀\n\nhttps://emerge.app/invite/${profile.uid}',
              );
            },
            onAction: (friend, action) {
              _handleFriendAction(context, friend, action);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(error: e.toString()),
    );
  }

  void _handleFriendAction(
    BuildContext context,
    FriendRankEntry friend,
    String action,
  ) {
    if (action == 'nudge') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👋 You nudged ${friend.name}!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primary,
        ),
      );
    } else if (action == 'challenge') {
      // Show hybrid accountability sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _AccountabilityActionSheet(friend: friend),
      );
    }
  }
}

class _AccountabilityActionSheet extends StatelessWidget {
  final FriendRankEntry friend;

  const _AccountabilityActionSheet({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: friend.avatarUrl != null
                    ? NetworkImage(friend.avatarUrl!)
                    : null,
                child: friend.avatarUrl == null ? Text(friend.name[0]) : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenge ${friend.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${friend.xp} XP • Ahead of you',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Gap(24),
          _ActionOption(
            icon: Icons.timer,
            title: 'Race to 5k Steps',
            subtitle: 'First to hit 5,000 steps today wins 50 XP',
            onTap: () {
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Challenge sent: Race to 5k Steps'),
                ),
              );
            },
          ),
          const Gap(12),
          _ActionOption(
            icon: Icons.monetization_on_outlined,
            title: 'Wager Challenge',
            subtitle: 'Bet \$5 on who keeps their streak this week',
            isPremium: true,
            onTap: () {
              // Navigate to Accountability Screen for details
              Navigator.pop(context);
              context.push('/community/accountability');
            },
          ),
          const Gap(12),
          _ActionOption(
            icon: Icons.edit_note,
            title: 'Custom Challenge',
            subtitle: 'create your own rules...',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom challenge coming soon')),
              );
            },
          ),
          const Gap(24),
        ],
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;

  const _ActionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPremium = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isPremium) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryDark),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// HELPER WIDGETS
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainDark,
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _ClubLeaderboardItem extends StatelessWidget {
  final int rank;
  final Tribe tribe;

  const _ClubLeaderboardItem({required this.rank, required this.tribe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank <= 3
                  ? Colors.amber
                  : AppTheme.surfaceDark.withValues(alpha: 0.8),
            ),
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.black : Colors.white,
              ),
            ),
          ),
          const Gap(16),
          CircleAvatar(
            backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
            radius: 20,
            backgroundImage: NetworkImage(tribe.imageUrl),
            onBackgroundImageError: (_, __) {},
            child: tribe.imageUrl.isEmpty
                ? Icon(
                    Icons.groups,
                    size: 20,
                    color: AppTheme.textSecondaryDark,
                  )
                : null,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tribe.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
                Text(
                  '${tribe.totalXp} XP',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.message,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
          ),
          const Gap(16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondaryDark),
          ),
          if (onAction != null) ...[
            const Gap(24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(actionLabel ?? 'Action'),
            ),
          ],
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
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const Gap(16),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
