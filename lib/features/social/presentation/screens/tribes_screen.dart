import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        title: Text(
          'Tribes Community',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildDiscoverTab() {
    final tribes = ref.watch(tribesProvider);
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
            return _LeaderboardItem(rank: index + 1, tribe: topTribes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMyTribesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
          const Gap(16),
          Text(
            'You haven\'t joined any tribes yet.',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
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
        style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
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

class _FeaturedTribeCard extends StatelessWidget {
  final Tribe tribe;

  const _FeaturedTribeCard({required this.tribe});

  @override
  Widget build(BuildContext context) {
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
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              image: DecorationImage(
                image: NetworkImage(tribe.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tribe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(4),
                Text(
                  '${tribe.memberCount} Members',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
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
              color: rank <= 3 ? Colors.amber : Colors.grey[800],
            ),
            child: Text(
              '#$rank',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.black : Colors.white,
              ),
            ),
          ),
          const Gap(16),
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            backgroundImage: NetworkImage(tribe.imageUrl),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tribe.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
                Text(
                  '${tribe.totalXp} XP',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
