import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Challenges Screen - Wired to Firestore via providers
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

              // Weekly Spotlight Card — from Firestore
              SliverToBoxAdapter(child: _WeeklySpotlightSection()),

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

              // Quest Cards — from Firestore
              SliverToBoxAdapter(child: _QuestCardsSection()),

              const SliverToBoxAdapter(child: Gap(28)),

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

              // Archetype Challenges — from Firestore
              SliverToBoxAdapter(child: _ArchetypeChallengesSection()),

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

// ============ WEEKLY SPOTLIGHT (Firestore) ============

class _WeeklySpotlightSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotlightAsync = ref.watch(weeklySpotlightProvider);

    return spotlightAsync.when(
      data: (challenge) {
        if (challenge == null) {
          return _EmptySpotlightCard();
        }
        return _SpotlightCard(challenge: challenge);
      },
      loading: () => _ShimmerCard(height: 220),
      error: (_, __) => _EmptySpotlightCard(),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Challenge challenge;

  const _SpotlightCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        'Join',
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

// ============ QUEST CARDS (Firestore) ============

class _QuestCardsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(userChallengesProvider);

    return questsAsync.when(
      data: (challenges) {
        final active = challenges
            .where((c) => c.status == ChallengeStatus.active)
            .toList();
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
                      'No active quests yet',
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Browse archetype challenges below to get started',
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark.withValues(
                          alpha: 0.5,
                        ),
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
      },
      loading: () => Column(
        children: [
          _ShimmerCard(height: 140),
          const Gap(16),
          _ShimmerCard(height: 140),
        ],
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Failed to load quests',
          style: TextStyle(color: Colors.white70),
        ),
      ),
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
                    const Icon(Icons.stars, size: 12, color: EmergeColors.teal),
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
    ).animate().fadeIn(delay: 100.ms);
  }
}

// ============ ARCHETYPE CHALLENGES (Firestore) ============

class _ArchetypeChallengesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(archetypeChallengesProvider);

    return challengesAsync.when(
      data: (challenges) {
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
              .map((c) => _ArchetypeChallengeCard(challenge: c, ref: ref))
              .toList(),
        );
      },
      loading: () => Column(
        children: [
          _ShimmerCard(height: 100),
          const Gap(12),
          _ShimmerCard(height: 100),
        ],
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Failed to load challenges',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _ArchetypeChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final WidgetRef ref;

  const _ArchetypeChallengeCard({required this.challenge, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

// ============ SHIMMER LOADER ============

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: height,
          decoration: BoxDecoration(
            color: EmergeColors.glassWhite,
            borderRadius: BorderRadius.circular(16),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.08),
        );
  }
}

// ============ TAB CONTENT WRAPPER (for embedding in TabBarView) ============

class ChallengesTabContent extends ConsumerWidget {
  const ChallengesTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotlightAsync = ref.watch(weeklySpotlightProvider);
    final questsAsync = ref.watch(userChallengesProvider);
    final archetypeAsync = ref.watch(archetypeChallengesProvider);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: Gap(16)),

        // Weekly Spotlight
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
        SliverToBoxAdapter(
          child: spotlightAsync.when(
            data: (challenge) {
              if (challenge == null) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 120,
                  decoration: BoxDecoration(
                    color: EmergeColors.glassWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EmergeColors.glassBorder),
                  ),
                  child: Center(
                    child: Text(
                      'No spotlight challenge yet',
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A1A6B), Color(0xFF2D1B4E)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: EmergeColors.teal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${challenge.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: EmergeColors.teal,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${challenge.daysLeft}d left',
                          style: const TextStyle(
                            fontSize: 11,
                            color: EmergeColors.coral,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      challenge.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.05);
            },
            loading: () => _ShimmerCard(height: 140),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Active Quests
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Your Quests',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Gap(12)),
        SliverToBoxAdapter(
          child: questsAsync.when(
            data: (challenges) {
              final active = challenges
                  .where((c) => c.status == ChallengeStatus.active)
                  .toList();
              if (active.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EmergeColors.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmergeColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(
                        'No active quests — browse below to start',
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: active.map((c) {
                  final progress = c.totalDays > 0
                      ? c.currentDay / c.totalDays
                      : 0.0;
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EmergeColors.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmergeColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: EmergeColors.teal.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flag,
                            size: 18,
                            color: EmergeColors.teal,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Gap(4),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: EmergeColors.glassWhite,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  EmergeColors.teal,
                                ),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Day ${c.currentDay}/${c.totalDays}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => _ShimmerCard(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Archetype Challenges
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
        const SliverToBoxAdapter(child: Gap(12)),
        SliverToBoxAdapter(
          child: archetypeAsync.when(
            data: (challenges) {
              if (challenges.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EmergeColors.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmergeColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Archetype challenges coming soon',
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: challenges.map((c) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EmergeColors.glassWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EmergeColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: EmergeColors.teal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.flag_circle,
                            color: EmergeColors.teal,
                            size: 22,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${c.totalDays}d • +${c.xpReward} XP',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
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
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => _ShimmerCard(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(80)),
      ],
    );
  }
}
