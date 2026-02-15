import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Challenges Screen - Exact Stitch Design Match
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Solo', 'Group', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: EmergeColors.teal,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: EmergeColors.cosmicGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'ACTIVE CHALLENGES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                centerTitle: true,
              ),

              // Filter Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _FilterPillsRow(
                    filters: _filters,
                    selected: _selectedFilter,
                    onSelected: (i) => setState(() => _selectedFilter = i),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(20)),

              // Weekly Spotlight Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: EmergeColors.yellow,
                      ),
                      const Gap(8),
                      Text(
                        'Weekly Spotlight',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(12)),

              // Weekly Spotlight Card
              SliverToBoxAdapter(child: _WeeklySpotlightCard()),

              const SliverToBoxAdapter(child: Gap(28)),

              // Your Quests Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Quests',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: EmergeColors.teal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(16)),

              // Quest Cards
              SliverToBoxAdapter(child: _QuestCardsList()),

              const SliverToBoxAdapter(child: Gap(28)),

              // Galactic Top 3 Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 18,
                        color: EmergeColors.yellow,
                      ),
                      const Gap(8),
                      const Text(
                        'Galactic Top 3',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(16)),

              // Leaderboard
              SliverToBoxAdapter(child: _LeaderboardSection()),

              const SliverToBoxAdapter(child: Gap(80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ FILTER PILLS ============

class _FilterPillsRow extends StatelessWidget {
  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelected;

  const _FilterPillsRow({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = entry.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? EmergeColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? EmergeColors.teal
                        : EmergeColors.glassBorder,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondaryDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============ WEEKLY SPOTLIGHT CARD ============

class _WeeklySpotlightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4A1A6B), const Color(0xFF2D1B4E)],
        ),
      ),
      child: Stack(
        children: [
          // Cosmic background effect
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.purple.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EmergeColors.teal.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: EmergeColors.teal),
                      const Gap(4),
                      const Text(
                        '+500 XP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: EmergeColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(16),

                const Text(
                  'Cosmic Clarity: Deep Focus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Gap(6),

                Text(
                  'Master your mind with 7 days of uninterrupted meditation sessions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const Spacer(),

                // Bottom row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: EmergeColors.coral,
                        ),
                        const Gap(6),
                        Text(
                          'Ends in 2 days',
                          style: TextStyle(
                            fontSize: 12,
                            color: EmergeColors.coral,
                          ),
                        ),
                      ],
                    ),

                    // Check In button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Check In',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A0A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}

// ============ QUEST CARDS LIST ============

class _QuestCardsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final quests = [
      {
        'icon': Icons.self_improvement,
        'title': '7-Day Meditation Streak',
        'daysLeft': '3 days left',
        'xp': 150,
        'progress': 0.5,
        'participants': 24,
      },
      {
        'icon': Icons.water_drop,
        'title': 'Morning Hydration',
        'daysLeft': 'Ends today',
        'xp': 50,
        'progress': 0.8,
        'participants': 5,
      },
    ];

    return Column(
      children: quests
          .map(
            (quest) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _QuestCard(
                icon: quest['icon'] as IconData,
                title: quest['title'] as String,
                daysLeft: quest['daysLeft'] as String,
                xp: quest['xp'] as int,
                progress: quest['progress'] as double,
                participants: quest['participants'] as int,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String daysLeft;
  final int xp;
  final double progress;
  final int participants;

  const _QuestCard({
    required this.icon,
    required this.title,
    required this.daysLeft,
    required this.xp,
    required this.progress,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EmergeColors.teal.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: EmergeColors.teal),
              ),
              const Gap(12),

              // Title and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      daysLeft,
                      style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                    ),
                  ],
                ),
              ),

              // XP Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: EmergeColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: EmergeColors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 12, color: EmergeColors.teal),
                    const Gap(4),
                    Text(
                      '+$xp XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: EmergeColors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(16),

          // Progress section
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
          const Gap(8),

          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: EmergeColors.glassWhite,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: EmergeColors.neonGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          const Gap(16),

          // Bottom row with avatars and continue
          Row(
            children: [
              // Overlapping avatars
              SizedBox(
                width: 70,
                height: 28,
                child: Stack(
                  children: List.generate(
                    3,
                    (i) => Positioned(
                      left: i * 18.0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EmergeColors.violet,
                          border: Border.all(
                            color: EmergeColors.background,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            ['A', 'J', 'M'][i],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Participant count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EmergeColors.glassWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$participants',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ),

              const Spacer(),

              // Continue link
              Row(
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppTheme.textSecondaryDark,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

// ============ LEADERBOARD SECTION ============

class _LeaderboardSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final leaders = [
      {
        'name': 'Aria Nova',
        'level': 42,
        'title': 'Cosmic Pioneer',
        'xp': 12450,
        'rank': 1,
      },
      {
        'name': 'Jax Stellar',
        'level': 38,
        'title': 'Star Walker',
        'xp': 10200,
        'rank': 2,
      },
      {
        'name': 'Mira Void',
        'level': 35,
        'title': 'Nebulizer',
        'xp': 9850,
        'rank': 3,
      },
    ];

    return Column(
      children: leaders
          .map(
            (leader) => _LeaderboardEntry(
              name: leader['name'] as String,
              level: leader['level'] as int,
              title: leader['title'] as String,
              xp: leader['xp'] as int,
              rank: leader['rank'] as int,
            ),
          )
          .toList(),
    );
  }
}

class _LeaderboardEntry extends StatelessWidget {
  final String name;
  final int level;
  final String title;
  final int xp;
  final int rank;

  const _LeaderboardEntry({
    required this.name,
    required this.level,
    required this.title,
    required this.xp,
    required this.rank,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isFirst ? 12 : 8),
      padding: EdgeInsets.all(isFirst ? 16 : 12),
      decoration: BoxDecoration(
        color: isFirst ? EmergeColors.glassWhite : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isFirst ? Border.all(color: EmergeColors.glassBorder) : null,
      ),
      child: Row(
        children: [
          // Rank (only for #2, #3)
          if (!isFirst) ...[
            SizedBox(
              width: 24,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ),
            const Gap(8),
          ],

          // Trophy for #1
          if (isFirst) ...[
            Icon(Icons.emoji_events, size: 20, color: _rankColor),
            const Gap(12),
          ],

          // Avatar
          Stack(
            children: [
              Container(
                width: isFirst ? 48 : 40,
                height: isFirst ? 48 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      EmergeColors.violet.withValues(alpha: 0.6),
                      EmergeColors.teal.withValues(alpha: 0.4),
                    ],
                  ),
                  border: Border.all(color: _rankColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: TextStyle(
                      fontSize: isFirst ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isFirst)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _rankColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EmergeColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isFirst ? 15 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lvl $level • $title',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xp.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                ),
                style: TextStyle(
                  fontSize: isFirst ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: EmergeColors.teal,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ TAB CONTENT WRAPPER (for embedding in TabBarView) ============

class ChallengesTabContent extends ConsumerStatefulWidget {
  const ChallengesTabContent({super.key});

  @override
  ConsumerState<ChallengesTabContent> createState() =>
      _ChallengesTabContentState();
}

class _ChallengesTabContentState extends ConsumerState<ChallengesTabContent> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Solo', 'Group', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Filter Pills
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _FilterPillsRow(
              filters: _filters,
              selected: _selectedFilter,
              onSelected: (i) => setState(() => _selectedFilter = i),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(12)),

        // Weekly Spotlight Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: EmergeColors.yellow,
                ),
                const Gap(8),
                const Text(
                  'Weekly Spotlight',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(12)),

        // Weekly Spotlight Card
        SliverToBoxAdapter(child: _WeeklySpotlightCard()),

        const SliverToBoxAdapter(child: Gap(28)),

        // Your Quests Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Quests',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(color: EmergeColors.teal, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(16)),

        // Quest Cards
        SliverToBoxAdapter(child: _QuestCardsList()),

        const SliverToBoxAdapter(child: Gap(28)),

        // Galactic Top 3 Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: EmergeColors.yellow,
                ),
                const Gap(8),
                const Text(
                  'Galactic Top 3',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(16)),

        // Leaderboard
        SliverToBoxAdapter(child: _LeaderboardSection()),

        const SliverToBoxAdapter(child: Gap(80)),
      ],
    );
  }
}
