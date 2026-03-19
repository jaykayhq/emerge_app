import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_bundle.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:emerge_app/features/social/presentation/widgets/challenges_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Challenges Screen - Optimized with bundle provider to prevent double refresh
/// Uses single consolidated data fetch instead of multiple independent providers
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Active Solo',
    'Weekly Spotlight',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    // Watch the consolidated bundle - single async operation
    final bundleAsync = ref.watch(challengeBundleProvider);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black.withValues(alpha: 0.6),
            builder: (context) => const CreateSoloChallengeDialog(),
          );
        },
        backgroundColor: EmergeColors.teal,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content - hidden during initial load
              Opacity(
                opacity: bundleAsync.isLoading ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: bundleAsync.isLoading,
                  child: _buildContent(bundleAsync.value),
                ),
              ),
              // Unified skeleton loader during initial load
              if (bundleAsync.isLoading) const ChallengesSkeletonLoader(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ChallengeBundleData? bundle) {
    return CustomScrollView(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _FilterPillsRow(
              filters: _filters,
              selected: _selectedFilter,
              onSelected: (i) => setState(() => _selectedFilter = i),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(20)),

        if (_selectedFilter == 0 || _selectedFilter == 2) ...[
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
          SliverToBoxAdapter(child: _WeeklySpotlightSection(bundle: bundle)),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0) ...[
          // Daily Quest Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.today, size: 18, color: EmergeColors.coral),
                  const Gap(8),
                  const Text(
                    'Daily Quest',
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
          SliverToBoxAdapter(child: _DailyQuestSection(bundle: bundle)),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0 || _selectedFilter == 1) ...[
          // Your Quests Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solo Quests',
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
          SliverToBoxAdapter(child: _QuestCardsSection(bundle: bundle)),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0) ...[
          // Archetype Challenges Section
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
                    'For Your Path',
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
          SliverToBoxAdapter(
            child: _ArchetypeChallengesSection(bundle: bundle),
          ),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 3) ...[
          // Completed Challenges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: EmergeColors.teal,
                  ),
                  const Gap(8),
                  const Text(
                    'Completed',
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
          SliverToBoxAdapter(
            child: _CompletedChallengesSection(bundle: bundle),
          ),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        const SliverToBoxAdapter(child: Gap(80)),
      ],
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

// ============ WEEKLY SPOTLIGHT (from Bundle) ============

class _WeeklySpotlightSection extends StatelessWidget {
  final ChallengeBundleData? bundle;

  const _WeeklySpotlightSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final challenge = bundle?.weeklySpotlight;

    if (challenge == null) {
      return _EmptySpotlightCard();
    }
    return _SpotlightCard(challenge: challenge);
  }
}

class _SpotlightCard extends ConsumerWidget {
  final Challenge challenge;

  const _SpotlightCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(challengeRepositoryProvider);
    final user = ref.watch(authStateChangesProvider).value;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1A6B), Color(0xFF2D1B4E)],
          ),
        ),
        child: Stack(
          children: [
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
                        const Icon(
                          Icons.bolt,
                          size: 14,
                          color: EmergeColors.teal,
                        ),
                        const Gap(4),
                        Text(
                          '+${challenge.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: EmergeColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    challenge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: EmergeColors.coral,
                          ),
                          const Gap(6),
                          Text(
                            '${challenge.daysLeft} days left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EmergeColors.coral,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (user == null) return;
                          try {
                            final result = await repository.joinChallenge(
                              user.id,
                              challenge.id,
                            );
                            result.fold(
                              (failure) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error: ${failure.message}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Quest accepted! Good luck!',
                                      ),
                                      backgroundColor: EmergeColors.teal,
                                    ),
                                  );
                                }
                              },
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A0A2E),
                            ),
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
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }
}

class _EmptySpotlightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 180,
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 40,
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
            ),
            const Gap(12),
            Text(
              'No spotlight challenge yet',
              style: TextStyle(
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const Gap(4),
            Text(
              'Check back soon for featured challenges!',
              style: TextStyle(
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ DAILY QUEST SECTION (from Bundle) ============

class _DailyQuestSection extends ConsumerStatefulWidget {
  final ChallengeBundleData? bundle;

  const _DailyQuestSection({this.bundle});

  @override
  ConsumerState<_DailyQuestSection> createState() => _DailyQuestSectionState();
}

class _DailyQuestSectionState extends ConsumerState<_DailyQuestSection> {
  @override
  Widget build(BuildContext context) {
    final challenge = widget.bundle?.dailyQuest;

    if (challenge == null) {
      return _EmptyDailyQuestCard();
    }

    // Get user ID from auth state
    final user = ref.watch(authStateChangesProvider).value;
    final userId = user?.id ?? '';

    return _DailyQuestCard(challenge: challenge, userId: userId);
  }
}

class _DailyQuestCard extends ConsumerWidget {
  final Challenge challenge;
  final String userId;

  const _DailyQuestCard({required this.challenge, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(challengeRepositoryProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmergeColors.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmergeColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EmergeColors.coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EmergeColors.coral.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: EmergeColors.coral,
                      ),
                      const Gap(4),
                      const Text(
                        'Daily',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: EmergeColors.coral,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
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
                      const Icon(
                        Icons.bolt,
                        size: 14,
                        color: EmergeColors.teal,
                      ),
                      const Gap(4),
                      Text(
                        '+${challenge.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: EmergeColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    if (userId.isEmpty) return;
                    try {
                      final result = await repository.joinChallenge(
                        userId,
                        challenge.id,
                      );
                      result.fold(
                        (failure) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${failure.message}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Daily quest started!'),
                                backgroundColor: EmergeColors.teal,
                              ),
                            );
                          }
                        },
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: EmergeColors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(6),
            Text(
              challenge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }
}

class _EmptyDailyQuestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.today,
              size: 32,
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
            ),
            const Gap(8),
            Text(
              'No daily quest available',
              style: TextStyle(
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ QUEST CARDS (from Bundle) ============

class _QuestCardsSection extends StatelessWidget {
  final ChallengeBundleData? bundle;

  const _QuestCardsSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final active = bundle?.activeSoloChallenges ?? [];

    if (active.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EmergeColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmergeColors.glassBorder),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.explore,
                  size: 40,
                  color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                ),
                const Gap(12),
                Text(
                  'No active solo quests yet',
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  'Browse archetype challenges below to get started',
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: active
          .map(
            (quest) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _QuestCard(challenge: quest),
            ),
          )
          .toList(),
    );
  }
}

class _CompletedChallengesSection extends StatelessWidget {
  final ChallengeBundleData? bundle;

  const _CompletedChallengesSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final completed = bundle?.completedChallenges ?? [];

    if (completed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EmergeColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmergeColors.glassBorder),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 40,
                  color: EmergeColors.teal,
                ),
                Gap(12),
                Text(
                  'No completed quests yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: completed
          .map(
            (quest) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _QuestCard(challenge: quest),
            ),
          )
          .toList(),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Challenge challenge;

  const _QuestCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.totalDays > 0
        ? challenge.currentDay / challenge.totalDays
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmergeColors.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmergeColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    size: 20,
                    color: EmergeColors.teal,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '${challenge.daysLeft} days left',
                        style: const TextStyle(
                          fontSize: 12,
                          color: EmergeColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      const Icon(
                        Icons.stars,
                        size: 12,
                        color: EmergeColors.teal,
                      ),
                      const Gap(4),
                      Text(
                        '+${challenge.xpReward} XP',
                        style: const TextStyle(
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
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: EmergeColors.glassWhite,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: EmergeColors.neonGradient,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Text(
                  'Day ${challenge.currentDay}/${challenge.totalDays}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const Spacer(),
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
      ).animate().fadeIn(delay: 100.ms),
    );
  }
}

// ============ ARCHETYPE CHALLENGES (from Bundle) ============

class _ArchetypeChallengesSection extends StatelessWidget {
  final ChallengeBundleData? bundle;

  const _ArchetypeChallengesSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final challenges = bundle?.archetypeChallenges ?? [];

    if (challenges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EmergeColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmergeColors.glassBorder),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                ),
                const Gap(12),
                Text(
                  'Coming soon for your archetype',
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: challenges
          .map((c) => _ArchetypeChallengeCard(challenge: c))
          .toList(),
    );
  }
}

class _ArchetypeChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _ArchetypeChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmergeColors.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EmergeColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flag_circle,
                color: EmergeColors.teal,
                size: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Text(
                        '${challenge.totalDays} days',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      const Gap(8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondaryDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '+${challenge.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: EmergeColors.teal,
                        ),
                      ),
                      if (challenge.isPremium) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EmergeColors.yellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: EmergeColors.yellow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final user = ref.read(authStateChangesProvider).value;
                if (user == null) return;
                final repository = ref.read(challengeRepositoryProvider);
                try {
                  final result = await repository.joinChallenge(
                    user.id,
                    challenge.id,
                  );
                  result.fold(
                    (failure) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${failure.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quest successfully joined!'),
                            backgroundColor: EmergeColors.teal,
                          ),
                        );
                      }
                    },
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: EmergeColors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
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
  final List<String> _filters = [
    'All',
    'Active Solo',
    'Weekly Spotlight',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: Gap(16)),

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

        const SliverToBoxAdapter(child: Gap(20)),

        if (_selectedFilter == 0 || _selectedFilter == 2) ...[
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
          SliverToBoxAdapter(child: _WeeklySpotlightSection()),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0) ...[
          // Daily Quest Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.today, size: 18, color: EmergeColors.coral),
                  const Gap(8),
                  const Text(
                    'Daily Quest',
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
          SliverToBoxAdapter(child: _DailyQuestSection()),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0 || _selectedFilter == 1) ...[
          // Your Quests Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solo Quests',
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
          SliverToBoxAdapter(child: _QuestCardsSection()),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 0) ...[
          // Archetype Challenges Section
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
                    'For Your Path',
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
          SliverToBoxAdapter(child: _ArchetypeChallengesSection()),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        if (_selectedFilter == 3) ...[
          // Completed Challenges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: EmergeColors.teal,
                  ),
                  const Gap(8),
                  const Text(
                    'Completed',
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
          SliverToBoxAdapter(child: _CompletedChallengesSection()),
          const SliverToBoxAdapter(child: Gap(28)),
        ],

        // Floating Action Button spacer if needed, or we can add a custom button
        const SliverToBoxAdapter(child: Gap(80)),
      ],
    );
  }
}
