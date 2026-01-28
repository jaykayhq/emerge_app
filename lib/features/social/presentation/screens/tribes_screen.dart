import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart'
    hide Tribe;
import 'package:emerge_app/features/social/data/repositories/social_repository.dart'
    hide tribesProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:emerge_app/features/social/presentation/screens/create_tribe_screen.dart';

class TribesScreen extends ConsumerStatefulWidget {
  const TribesScreen({super.key});

  @override
  ConsumerState<TribesScreen> createState() => _TribesScreenState();
}

class _TribesScreenState extends ConsumerState<TribesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Tribes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Tribes'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTribesTab(), _buildChallengesTab()],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      heroTag: 'community_fab',
      onPressed: () {
        final index = _tabController.index;
        if (index == 0) {
          _createTribe(context, ref);
        } else {
          // Create Challenge logic or nav
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Challenge coming soon!')),
          );
        }
      },
      label: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Text(
            _tabController.index == 0 ? 'Create Tribe' : 'Create Challenge',
          );
        },
      ),
      icon: const Icon(Icons.add),
      backgroundColor: AppTheme.primary,
    );
  }

  void _createTribe(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a tribe.')),
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

  Widget _buildTribesTab() {
    final tribesAsync = ref.watch(tribesProvider);

    return tribesAsync.when(
      data: (tribes) {
        final featuredTribes = tribes.take(5).toList();
        final leaderboardTribes = List<Tribe>.from(tribes)
          ..sort((a, b) => b.totalXp.compareTo(a.totalXp));

        if (tribes.isEmpty) {
          return _EmptyState(
            message: 'No tribes found.',
            icon: Icons.groups_outlined,
            onAction: () => _createTribe(context, ref),
            actionLabel: 'Create First Tribe',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: 'Featured Tribes', onSeeAll: () {}),
            const Gap(12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredTribes.length,
                separatorBuilder: (context, index) => const Gap(16),
                itemBuilder: (context, index) {
                  return _FeaturedTribeCard(tribe: featuredTribes[index]);
                },
              ),
            ),
            const Gap(24),
            _SectionHeader(title: 'Top Tribes', onSeeAll: () {}),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboardTribes.take(10).length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                return _LeaderboardItem(
                  rank: index + 1,
                  tribe: leaderboardTribes[index],
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

  Widget _buildChallengesTab() {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return const _EmptyState(
            message: 'No active challenges.',
            icon: Icons.emoji_events_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) {
            return _ChallengeCard(
              challenge: challenges[index],
            ).animate().fadeIn(delay: (100 * index).ms).slideY();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(error: err.toString()),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainDark,
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _FeaturedTribeCard extends ConsumerWidget {
  final Tribe tribe;

  const _FeaturedTribeCard({required this.tribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              color: AppTheme.primary.withValues(alpha: 0.2),
              child: Image.network(
                tribe.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 100,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.groups, size: 40, color: AppTheme.primary),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tribe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMainDark,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '${tribe.memberCount} Members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Join logic
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final Tribe tribe;

  const _LeaderboardItem({required this.rank, required this.tribe});

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

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppTheme.secondary,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${challenge.daysLeft} days left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(16),
            LinearProgressIndicator(
              value: 0.7, // Mock progress
              backgroundColor: AppTheme.backgroundDark,
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
