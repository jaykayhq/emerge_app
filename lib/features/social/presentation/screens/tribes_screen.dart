import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text(
          'Tribes Community',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Tribes'),
            Tab(text: 'World Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(),
          _buildMyTribesTab(),
          _buildWorldMapTab(),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tribes_fab',
        onPressed: () {
          final user = ref.read(authStateChangesProvider).value;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please sign in to create a tribe.'),
              ),
            );
            return;
          }

          final userStatsAsync = ref.read(userStatsStreamProvider);

          userStatsAsync.when(
            data: (stats) {
              if (stats.avatarStats.level >= 5) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTribeScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Level 5 required to create a Tribe. Current: ${stats.avatarStats.level}',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            loading: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checking level requirement...')),
            ),
            error: (e, s) => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error checking level: $e'))),
          );
        },
        label: const Text('Create Tribe'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final tribesAsync = ref.watch(tribesProvider);

    return tribesAsync.when(
      data: (tribes) {
        final featuredTribes = tribes.take(5).toList();
        final leaderboardTribes = List<Tribe>.from(tribes)
          ..sort((a, b) => b.totalXp.compareTo(a.totalXp));
        final topTribes = leaderboardTribes.take(10).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.emoji_events,
                    label: 'Challenges',
                    color: Colors.amber,
                    onTap: () => context.push('/tribes/challenges'),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.handshake,
                    label: 'Accountability',
                    color: Colors.blue,
                    onTap: () => context.push('/tribes/accountability'),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Featured Tribes Carousel
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

            // Leaderboard
            _SectionHeader(title: 'Top Tribes Leaderboard', onSeeAll: () {}),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topTribes.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                return _LeaderboardItem(
                  rank: index + 1,
                  tribe: topTribes[index],
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMyTribesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: AppTheme.textSecondaryDark,
          ),
          const Gap(16),
          Text(
            'You haven\'t joined any tribes yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0); // Go to Discover
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.backgroundDark,
            ),
            child: const Text('Explore Tribes'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldMapTab() {
    return Center(
      child: Text(
        'Community World Map\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppTheme.textMainDark,
              ),
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
          style: GoogleFonts.outfit(
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  );
                },
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
                      onPressed: () async {
                        try {
                          final userAsync = ref.read(authStateChangesProvider);
                          final user = userAsync.value;

                          if (user != null) {
                            final repo = ref.read(tribeRepositoryProvider);
                            // 1. Join Tribe
                            await repo.joinTribe(user.id, tribe.id);

                            // Log Activity for XP
                            final userStatsRepo = ref.read(
                              userStatsRepositoryProvider,
                            );
                            await userStatsRepo.logActivity(
                              userId: user.id,
                              sourceId: tribe.id,
                              type: 'joined_tribe',
                              date: DateTime.now(),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Joined ${tribe.name}! (+50 XP)',
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please sign in to join tribes.',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to join: $e')),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      child: const Text('Join'),
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
            child: ClipOval(
              child: Image.network(
                tribe.imageUrl,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.groups, color: AppTheme.textSecondaryDark),
              ),
            ),
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
