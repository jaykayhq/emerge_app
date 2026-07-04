import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/core/presentation/widgets/oracle_card.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/gamification/domain/services/identity_engine.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';

class AiReflectionsScreen extends ConsumerStatefulWidget {
  const AiReflectionsScreen({super.key});

  @override
  ConsumerState<AiReflectionsScreen> createState() =>
      _AiReflectionsScreenState();
}

class _AiReflectionsScreenState extends ConsumerState<AiReflectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScreenFirstVisit(
        '/profile/reflections',
        const NarratorAppearance(
          trigger: NarratorTrigger.screenFirstVisit,
          shellText:
              'This is your memory... Every session your Narrator watches gets stored here...',
          buttonA: 'Show me my patterns',
          buttonB: 'What does the Narrator watch for',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                if (!isPremium) _buildPremiumDiscovery(context),
                Expanded(
                  child: habitsAsync.when(
                    data: (habits) {
                      return FutureBuilder<List<dynamic>>(
                        future: Future.wait([
                          ref
                              .read(aiPersonalizationServiceProvider)
                              .generateIdentityInsights(
                                habits,
                                dominantMotive: ref
                                    .read(userStatsStreamProvider)
                                    .value
                                    ?.dominantMotive,
                                archetype:
                                    IdentityEngine.calculateDominantArchetype(
                                      ref
                                              .read(userStatsStreamProvider)
                                              .value
                                              ?.identityVotes ??
                                          {},
                                    ).name,
                              ),
                          ref
                              .read(aiPersonalizationServiceProvider)
                              .analyzeHabitPerformance(
                                habits,
                                dominantMotive: ref
                                    .read(userStatsStreamProvider)
                                    .value
                                    ?.dominantMotive,
                                archetype:
                                    IdentityEngine.calculateDominantArchetype(
                                      ref
                                              .read(userStatsStreamProvider)
                                              .value
                                              ?.identityVotes ??
                                          {},
                                    ).name,
                              ),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              itemCount: 3,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 20),
                              itemBuilder: (context, index) =>
                                  const _InsightSkeleton(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: EmergeColors.teal.withValues(
                                      alpha: 0.3,
                                    ),
                                    size: 64,
                                  ),
                                  const Gap(16),
                                  Text(
                                    'The Oracle is meditating...',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final results = snapshot.data ?? [[], []];
                          final insights = results[0] as List<AiInsight>;
                          final adjustments =
                              results[1] as List<GoldilocksAdjustment>;

                          // Combine both into a single list of cards
                          final allItems = <dynamic>[
                            ...insights,
                            ...adjustments,
                          ];

                          if (allItems.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: EmergeColors.teal.withValues(
                                      alpha: 0.1,
                                    ),
                                    size: 48,
                                  ),
                                  const Gap(16),
                                  Text(
                                    "Continue your journey to receive guidance.",
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            itemCount: allItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              if (item is AiInsight) {
                                return _InsightCard(insight: item);
                              } else {
                                return _GoldilocksAdjustmentCard(
                                  adjustment: item as GoldilocksAdjustment,
                                  onAccept: () =>
                                      _applyAdjustment(habits, item),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) => const _InsightSkeleton(),
                    ),
                    error: (e, s) => Center(
                      child: Text(
                        "Connection issue with the Oracle",
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkScreenFirstVisit(String route, NarratorAppearance appearance) {
    final trigger = NarratorTriggerEngine.shouldTrigger(
      stats: const NarratorUserStats(
        momentumScore: 0.5,
        consecutiveActiveDays: 1,
        totalHabitsToday: 0,
        completedHabitsToday: 0,
        currentLevel: 1,
        previousLevel: 1,
        hasStreakBreak: false,
        currentStreak: 0,
        longestStreak: 0,
        consecutiveMisses: 0,
        isFirstVisitToRoute: true,
        isFirstVisitToNode: false,
        hasCompletedEveningReflectionToday: false,
        hasCompletedOnboarding: true,
        archetypeSelected: true,
      ),
      context: AppOpenContext(
        currentRoute: route,
        now: DateTime.now(),
        isFirstAppOpen: false,
        daysSinceInstall: 10,
        daysSinceLastOpen: 0,
      ),
      recentTriggers: const {},
    );
    if (trigger == NarratorTrigger.screenFirstVisit && mounted) {
      NarratorSheet.show(context, appearance);
    }
  }

  Future<void> _applyAdjustment(
    List<Habit> habits,
    GoldilocksAdjustment adjustment,
  ) async {
    // 1. Find the habit
    final habit = habits.firstWhere(
      (h) => h.title == adjustment.habitTitle,
      orElse: () => throw Exception('Habit not found'),
    );

    // 2. Calculate new difficulty
    HabitDifficulty newDifficulty = habit.difficulty;
    if (adjustment.type == AdjustmentType.increase) {
      if (habit.difficulty == HabitDifficulty.easy) {
        newDifficulty = HabitDifficulty.medium;
      } else if (habit.difficulty == HabitDifficulty.medium) {
        newDifficulty = HabitDifficulty.hard;
      }
    } else if (adjustment.type == AdjustmentType.decrease) {
      if (habit.difficulty == HabitDifficulty.hard) {
        newDifficulty = HabitDifficulty.medium;
      } else if (habit.difficulty == HabitDifficulty.medium) {
        newDifficulty = HabitDifficulty.easy;
      }
    }

    if (newDifficulty == habit.difficulty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Difficulty is already at limit.')),
      );
      return;
    }

    // 3. Update Habit
    final updatedHabit = habit.copyWith(difficulty: newDifficulty);
    final result = await ref
        .read(habitRepositoryProvider)
        .updateHabit(updatedHabit);

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${failure.message}'))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adjusted ${habit.title} to ${newDifficulty.name}!'),
          ),
        );
        setState(() {}); // Refresh suggestions
      },
    );
  }

  Widget _buildPremiumDiscovery(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EmergeColors.violet, Color(0xFF9D50BB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: EmergeColors.violet.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock Oracle Coach',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Get personalized habit recalibrations and identity guidance.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/paywall'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: EmergeColors.violet,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textMainDark,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'ORACLE REFLECTIONS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMainDark,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GoldilocksAdjustmentCard extends ConsumerWidget {
  final GoldilocksAdjustment adjustment;
  final VoidCallback onAccept;

  const _GoldilocksAdjustmentCard({
    required this.adjustment,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final icon = adjustment.type == AdjustmentType.increase
        ? Icons.trending_up
        : Icons.trending_down;
    final color = adjustment.type == AdjustmentType.increase
        ? EmergeColors.green
        : Colors.amber;

    return OracleCard(
      title:
          '${adjustment.habitTitle}: Level ${adjustment.type == AdjustmentType.increase ? "Up" : "Down"}',
      description: adjustment.reason,
      quote: adjustment.suggestion,
      icon: icon,
      iconColor: color,
      isPremiumLocked: !isPremium,
      footer: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.surfaceDark,
                shape: const StadiumBorder(),
                foregroundColor: AppTheme.textSecondaryDark,
                side: BorderSide(color: EmergeColors.hexLine),
              ),
              child: const Text('Maybe Later'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isPremium ? onAccept : () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? EmergeColors.teal
                    : AppTheme.surfaceDark,
                foregroundColor: isPremium
                    ? Colors.white
                    : AppTheme.textSecondaryDark,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(isPremium ? 'Accept' : 'Unlock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends ConsumerWidget {
  final AiInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final isIdentity = insight.type == InsightType.identity;
    final iconColor = isIdentity ? EmergeColors.teal : EmergeColors.yellow;
    final icon = isIdentity ? Icons.verified_user : Icons.lightbulb;

    return OracleCard(
      title: insight.title,
      description: insight.description,
      quote: insight.action,
      icon: icon,
      iconColor: iconColor,
      isPremiumLocked: !isPremium && !isIdentity,
      footer: isIdentity
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Embrace this identity?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  Icons.close,
                  AppTheme.surfaceDark,
                  AppTheme.textSecondaryDark,
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  Icons.check,
                  EmergeColors.teal.withValues(alpha: 0.2),
                  EmergeColors.teal,
                ),
              ],
            )
          : ElevatedButton(
              onPressed: () {
                if (!isPremium) {
                  context.push('/paywall');
                  return;
                }

                // Binding to the AI Coach advice logic
                _showCoachAdviceDialog(context, ref, insight);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isPremium
                    ? EmergeColors.violet
                    : AppTheme.surfaceDark,
                foregroundColor: isPremium
                    ? Colors.white
                    : AppTheme.textSecondaryDark,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: isPremium
                    ? null
                    : BorderSide(color: EmergeColors.hexLine),
              ),
              child: Text(
                isPremium ? 'Adjust My Schedule' : 'Unlock Oracle Coach',
              ),
            ),
    );
  }

  void _showCoachAdviceDialog(
    BuildContext context,
    WidgetRef ref,
    AiInsight insight,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Oracle's Advice",
          style: TextStyle(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: FutureBuilder<String>(
          future: ref
              .read(aiPersonalizationServiceProvider)
              .enhanceUserWhy(
                "I want to adjust my schedule based on the pattern: ${insight.description}",
                dominantMotive: ref
                    .read(userStatsStreamProvider)
                    .value
                    ?.dominantMotive,
                archetype: IdentityEngine.calculateDominantArchetype(
                  ref.read(userStatsStreamProvider).value?.identityVotes ?? {},
                ).name,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonShimmer(width: 200, height: 24),
                    const SizedBox(height: 16),
                    const SkeletonShimmer(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    const SkeletonShimmer(width: 250, height: 16),
                  ],
                ),
              );
            }
            return Text(
              snapshot.data ?? "The Oracle is silent. Try again soon.",
              style: TextStyle(color: AppTheme.textMainDark),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "I Understand",
              style: TextStyle(color: EmergeColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSkeleton extends StatelessWidget {
  const _InsightSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonShimmer.circular(size: 40),
              const SizedBox(width: 12),
              const SkeletonShimmer(width: 150, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonShimmer(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const SkeletonShimmer(width: 200, height: 14),
          const SizedBox(height: 20),
          const SkeletonShimmer(
            width: double.infinity,
            height: 48,
            borderRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;

  const _CircleButton(this.icon, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 18, color: fg),
    );
  }
}
