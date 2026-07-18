import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_bundle.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:emerge_app/features/social/presentation/widgets/challenges_skeleton.dart';
import 'package:emerge_app/features/social/presentation/widgets/quest_card_stitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';


/// Challenges Screen - Optimized with bundle provider to prevent double refresh
/// Uses single consolidated data fetch instead of multiple independent providers
class ChallengesScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const ChallengesScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Active',
    'Solo',
    'Daily',
    'Weekly',
    'Completed',
  ];

  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _createKey = GlobalKey();

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _checkFirstVisit() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _disposed) return;

    final repo = LocalSettingsRepository();
    if (repo.isFirstLaunch) return;
    if (!repo.isTutorialsEnabled()) return;

    final hasSeen = await repo.getHasSeenNodeGuide('/challenges');
    if (!hasSeen && mounted && !_disposed) {
      await repo.setHasSeenNodeGuide('/challenges');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the consolidated bundle - single async operation
    final bundleAsync = ref.watch(challengeBundleProvider);

    // Handle error state with retry
    if (bundleAsync.hasError && !bundleAsync.isLoading) {
      final errorBody = Center(
        child: AppErrorWidget(
          message: 'Could not load challenges',
          onRetry: () => ref.invalidate(challengeBundleProvider),
        ),
      );
      if (!widget.showAppBar) {
        return Container(
          decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
          child: SafeArea(child: errorBody),
        );
      }
      return Scaffold(
        backgroundColor: EmergeColors.background,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
          child: SafeArea(child: errorBody),
        ),
      );
    }

    final content = Container(
      decoration: widget.showAppBar
          ? BoxDecoration(gradient: AppTheme.cosmicGradient)
          : null,
      child: SafeArea(
        top: widget.showAppBar,
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
    );

    if (!widget.showAppBar) return content;

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
        child: Icon(Icons.add_rounded, size: 32, key: _createKey),
      ),
      body: content,
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(challengeBundleProvider);
  }

  Widget _buildContent(ChallengeBundleData? bundle) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: EmergeColors.teal,
      child: CustomScrollView(
        slivers: [
          // App Bar
          if (widget.showAppBar)
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
                key: _filterKey,
                filters: _filters,
                selected: _selectedFilter,
                onSelected: (i) => setState(() => _selectedFilter = i),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Gap(20)),

          if (_selectedFilter == 0) ...[
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

            // Daily Quest Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.today,
                      size: 18,
                      color: EmergeColors.coral,
                    ),
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

          if (_selectedFilter == 1) ...[
            // EXPLICIT ACTIVE SECTION
            SliverToBoxAdapter(child: _ActiveChallengesSection(bundle: bundle)),
          ],

          if (_selectedFilter == 0 || _selectedFilter == 2) ...[
            // Solo Quests Section
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
                    if (_selectedFilter == 2)
                      Text(
                        '${bundle?.activeSoloChallenges.length ?? 0} Active',
                        style: const TextStyle(
                          color: EmergeColors.teal,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Gap(16)),
            SliverToBoxAdapter(child: _QuestCardsSection(bundle: bundle)),
            const SliverToBoxAdapter(child: Gap(28)),
          ],

          if (_selectedFilter == 0 || _selectedFilter == 3) ...[
            // Daily Quest Section (Duplicate for filter 3)
            if (_selectedFilter == 3) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.today,
                        size: 18,
                        color: EmergeColors.coral,
                      ),
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
          ],

          if (_selectedFilter == 0 || _selectedFilter == 4) ...[
            // Weekly Spotlight (Duplicate for filter 4)
            if (_selectedFilter == 4) ...[
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
                child: _WeeklySpotlightSection(bundle: bundle),
              ),
              const SliverToBoxAdapter(child: Gap(28)),
            ],
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

          if (_selectedFilter == 5) ...[
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
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = entry.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  entry.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.5),
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
    // Show active version if joined, otherwise show featured
    final challenge = (bundle?.isWeeklySpotlightJoined == true)
        ? bundle?.activeWeeklyChallenge
        : bundle?.weeklySpotlight;

    if (challenge == null) {
      return _EmptySpotlightCard();
    }

    return QuestCardStitch(
      challenge: challenge,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
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
    // Show active version if joined, otherwise show featured
    final challenge = (widget.bundle?.isDailyQuestJoined == true)
        ? widget.bundle?.activeDailyChallenge
        : widget.bundle?.dailyQuest;

    if (challenge == null) {
      return _EmptyDailyQuestCard();
    }

    return QuestCardStitch(
      challenge: challenge,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
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
            (quest) => QuestCardStitch(
              challenge: quest,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChallengeDetailScreen(challenge: quest),
                  ),
                );
              },
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
            (quest) => QuestCardStitch(
              challenge: quest,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChallengeDetailScreen(challenge: quest),
                  ),
                );
              },
            ),
          )
          .toList(),
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
          .map(
            (c) => QuestCardStitch(
              challenge: c,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChallengeDetailScreen(challenge: c),
                  ),
                );
              },
            ),
          )
          .toList(),
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
  final List<String> _filters = [
    'All',
    'Active Solo',
    'Weekly Spotlight',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    // Watch the challenge bundle provider
    final bundleAsync = ref.watch(challengeBundleProvider);

    return bundleAsync.when(
      loading: () => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: Gap(16)),
          SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
          ),
        ],
      ),
      error: (error, stack) => CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: Gap(16)),
          SliverFillRemaining(
            child: Center(
              child: AppErrorWidget(
                message: 'Error loading challenges',
                onRetry: () => ref.invalidate(challengeBundleProvider),
              ),
            ),
          ),
        ],
      ),
      data: (bundle) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: Gap(16)),

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
              SliverToBoxAdapter(
                child: _WeeklySpotlightSection(bundle: bundle),
              ),
              const SliverToBoxAdapter(child: Gap(28)),
            ],

            if (_selectedFilter == 0) ...[
              // Daily Quest Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.today,
                        size: 18,
                        color: EmergeColors.coral,
                      ),
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

            // Floating Action Button spacer if needed, or we can add a custom button
            const SliverToBoxAdapter(child: Gap(80)),
          ],
        );
      },
    );
  }
}

class _ActiveChallengesSection extends StatelessWidget {
  final ChallengeBundleData? bundle;
  const _ActiveChallengesSection({this.bundle});

  @override
  Widget build(BuildContext context) {
    final List<Challenge> activeChallenges = [];
    if (bundle != null) {
      // Check user's active weekly/daily (not featured catalog versions)
      final activeWeekly = bundle!.activeWeeklyChallenge;
      if (activeWeekly != null) activeChallenges.add(activeWeekly);
      final activeDaily = bundle!.activeDailyChallenge;
      if (activeDaily != null) activeChallenges.add(activeDaily);
      activeChallenges.addAll(bundle!.activeSoloChallenges);
    }

    if (activeChallenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 20, color: Color(0xFF00E5FF)),
                const Gap(8),
                const Text(
                  'ACTIVE QUESTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ...activeChallenges.map(
            (c) => QuestCardStitch(
              challenge: c,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailScreen(challenge: c),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
