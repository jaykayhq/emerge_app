import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
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
  Widget _buildClubsTab() {
    final profileAsync = ref.watch(userStatsStreamProvider);

    return profileAsync.when(
      data: (profile) {
        final theme = ArchetypeTheme.forArchetype(profile.archetype);

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
              _ContributorsSection().animate().fadeIn(delay: 300.ms),

              const Gap(32),

              // ===== RECENT ACTIVITY =====
              _ActivitySection().animate().fadeIn(delay: 400.ms),

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

class _ContributorsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contributors = [
      {'name': 'Sarah', 'status': 'Online'},
      {'name': 'Leo', 'status': 'Online'},
      {'name': 'Maya', 'status': 'Top 1'},
      {'name': 'Kai', 'status': 'Online'},
      {'name': 'Elena', 'status': 'Top 1'},
    ];

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
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contributors.length,
            itemBuilder: (context, index) {
              final c = contributors[index];
              final isOnline = c['status'] == 'Online';
              return Transform.translate(
                offset: Offset(index == 0 ? 0 : -index * 15.0, 0),
                child: _ContributorAvatar(
                  name: c['name']!,
                  status: c['status']!,
                  isOnline: isOnline,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContributorAvatar extends StatelessWidget {
  final String name;
  final String status;
  final bool isOnline;

  const _ContributorAvatar({
    required this.name,
    required this.status,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
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
                    EmergeColors.violet.withValues(alpha: 0.6),
                    EmergeColors.teal.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(color: EmergeColors.background, width: 3),
              ),
              child: Center(
                child: Text(
                  name[0],
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
          ],
        ),
        const Gap(4),
        Text(
          status,
          style: TextStyle(
            fontSize: 9,
            color: isOnline ? EmergeColors.teal : EmergeColors.yellow,
          ),
        ),
      ],
    );
  }
}

// ============ RECENT ACTIVITY (Simple list, no heavy cards) ============

class _ActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'icon': '🏆',
        'text': 'Alex T. earned "Cosmic Pioneer" badge',
        'time': '1:30 pm',
      },
      {
        'icon': '💬',
        'text': 'Sarah M. posted in "Stargazing" discussion',
        'time': '1:00 pm',
      },
      {'icon': '🎯', 'text': 'New Club Goal: Reach Level 11', 'time': ''},
    ];

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

        ...activities.asMap().entries.map((entry) {
          final activity = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['icon']!, style: const TextStyle(fontSize: 20)),
                const Gap(12),
                Expanded(
                  child: Text(
                    activity['text']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                if (activity['time']!.isNotEmpty)
                  Text(
                    activity['time']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
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
