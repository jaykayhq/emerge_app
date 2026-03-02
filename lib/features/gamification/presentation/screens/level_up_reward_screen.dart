import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Level Up Reward Screen - Stitch Design
/// Shows when a user completes a level with celebration animation
/// Features: Persona avatar, level title, XP progress bar, stats panel, and unlocks
class LevelUpRewardScreen extends ConsumerStatefulWidget {
  final int celebratedLevel;

  const LevelUpRewardScreen({super.key, required this.celebratedLevel});

  @override
  ConsumerState<LevelUpRewardScreen> createState() =>
      _LevelUpRewardScreenState();
}

class _LevelUpRewardScreenState extends ConsumerState<LevelUpRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Cosmic void dark
      body: statsAsync.when(
        data: (profile) {
          final stats = profile.avatarStats;
          final level = widget.celebratedLevel;
          final archetype = profile.archetype;
          final archetypeName = _getArchetypeDisplayName(archetype);
          final title = _getLevelTitle(level);

          return Stack(
            children: [
              // Background with subtle effects
              _buildBackground(),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(context),

                    // Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Persona Avatar with Level
                            AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: _buildPersonaAvatar(
                                    level,
                                    title,
                                    archetypeName,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // XP Progress Bar
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return _buildProgressBar(
                                  stats,
                                  _progressAnimation.value,
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Stats Panel
                            _buildStatsPanel(stats),

                            const SizedBox(height: 24),

                            // Next Level Unlocks
                            _buildUnlocksSection(level),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.neonGreen),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppTheme.textMainDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A1A), Color(0xFF1A0A2A), Color(0xFF0A0A1A)],
            ),
          ),
        ),

        // Subtle cosmic particles
        ...List.generate(20, (index) {
          return Positioned(
            left: (index * 47.3) % MediaQuery.of(context).size.width,
            top: (index * 31.7) % MediaQuery.of(context).size.height,
            child: Container(
              width: 2 + (index % 3),
              height: 2 + (index % 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 3 == 0
                    ? AppTheme.neonGreen.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Leveling Up Your Persona',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaAvatar(int level, String title, String archetypeName) {
    return Column(
      children: [
        // Glowing orb/avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.neonGreen.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.white70),
        ),

        const SizedBox(height: 16),

        // Level title
        Text(
          'Level $level $archetypeName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle
        Text(
          title,
          style: TextStyle(
            color: AppTheme.neonGreen.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 16),

        // Customize button
        Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Text(
              'Customize Persona',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(UserAvatarStats stats, double progress) {
    final xpInLevel = stats.totalXp % 500;
    final xpForNextLevel = 500;
    final xpProgress = (xpInLevel / xpForNextLevel).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress to Next Level',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$xpInLevel / $xpForNextLevel XP',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              widthFactor: xpProgress * progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(UserAvatarStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Habits',
                '${stats.totalXp ~/ 50}', // Approximate
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Current Streak',
                '${stats.streak} Days',
                Icons.local_fire_department,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total XP Earned',
          '${stats.totalXp}',
          Icons.stars,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnlocksSection(int level) {
    final nextLevel = level + 1;
    final unlocks = _getUnlocksForLevel(nextLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Level Unlocks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: unlocks.map((unlock) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        unlock['icon'] as IconData,
                        color: AppTheme.neonGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlock['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            unlock['description'] as String,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getArchetypeDisplayName(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Warrior';
      case UserArchetype.scholar:
        return 'Sage';
      case UserArchetype.creator:
        return 'Artist';
      case UserArchetype.stoic:
        return 'Guardian';
      case UserArchetype.zealot:
        return 'Zealot';
      case UserArchetype.none:
        return 'Explorer';
    }
  }

  String _getLevelTitle(int level) {
    if (level >= 50) return 'The Legendary';
    if (level >= 30) return 'The Master';
    if (level >= 15) return 'The Resilient';
    if (level >= 10) return 'The Dedicated';
    if (level >= 5) return 'The Rising';
    return 'The Beginning';
  }

  List<Map<String, dynamic>> _getUnlocksForLevel(int level) {
    // Return appropriate unlocks based on level
    if (level % 5 == 0) {
      // Milestone level
      return [
        {
          'title': 'New Archetype Ability',
          'description': 'Unlock a unique power for your archetype',
          'icon': Icons.bolt,
        },
        {
          'title': 'Cosmetic Upgrade',
          'description': 'New avatar customization option',
          'icon': Icons.palette,
        },
        {
          'title': 'Streak Bonus Multiplier',
          'description': 'Increased XP from consistent habits',
          'icon': Icons.trending_up,
        },
      ];
    }

    return [
      {
        'title': 'Habit Slot Unlock',
        'description': 'Add one more habit to your routine',
        'icon': Icons.add_circle_outline,
      },
      {
        'title': 'XP Boost',
        'description': '5% increase in XP earned',
        'icon': Icons.auto_graph,
      },
    ];
  }
}
