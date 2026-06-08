import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/domain/services/identity_engine.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/presentation/widgets/oracle_card.dart';

class GoldilocksScreen extends ConsumerStatefulWidget {
  const GoldilocksScreen({super.key});

  @override
  ConsumerState<GoldilocksScreen> createState() => _GoldilocksScreenState();
}

class _GoldilocksScreenState extends ConsumerState<GoldilocksScreen> {
  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.backgroundDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return const Center(
                        child: Text(
                          'No habits to analyze yet.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return FutureBuilder<List<GoldilocksAdjustment>>(
                      future: ref
                          .read(aiPersonalizationServiceProvider)
                          .analyzeHabitPerformance(
                            habits,
                            dominantMotive: ref
                                .read(userStatsStreamProvider)
                                .value
                                ?.dominantMotive,
                            archetype: IdentityEngine.calculateDominantArchetype(
                              ref.read(userStatsStreamProvider).value?.identityVotes ?? {},
                            ).name,
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: 2,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) => Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SkeletonShimmer.circular(size: 48),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SkeletonShimmer(
                                              width: 200,
                                              height: 16,
                                            ),
                                            SizedBox(height: 8),
                                            SkeletonShimmer(
                                              width: 150,
                                              height: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  SkeletonShimmer(
                                    width: double.infinity,
                                    height: 48,
                                    borderRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Analysis failed: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final adjustments = snapshot.data ?? [];
                        if (adjustments.isEmpty) {
                          return const Center(
                            child: Text(
                              'Goldilocks says: Everything is just right!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: adjustments.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _GoldilocksCard(
                              adjustment: adjustments[index],
                              onAccept: () =>
                                  _applyAdjustment(habits, adjustments[index]),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 2,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SkeletonShimmer.circular(size: 48),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SkeletonShimmer(width: 200, height: 16),
                                    SizedBox(height: 8),
                                    SkeletonShimmer(width: 150, height: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          SkeletonShimmer(
                            width: double.infinity,
                            height: 48,
                            borderRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
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
      }
      if (habit.difficulty == HabitDifficulty.medium) {
        newDifficulty = HabitDifficulty.hard;
      }
    } else if (adjustment.type == AdjustmentType.decrease) {
      if (habit.difficulty == HabitDifficulty.hard) {
        newDifficulty = HabitDifficulty.medium;
      }
      if (habit.difficulty == HabitDifficulty.medium) {
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Text(
                'Goldilocks Engine',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI Training Partner',
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The Goldilocks Engine keeps your habits perfectly balanced - not too hard, not too easy, but just right for growth.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TODAY\'S ADJUSTMENTS',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black54,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Center(
        child: Text(
          'Powered by Emerge AI',
          style: GoogleFonts.lexend(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }
}

class _GoldilocksCard extends StatelessWidget {
  final GoldilocksAdjustment adjustment;
  final VoidCallback onAccept;

  const _GoldilocksCard({required this.adjustment, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return OracleCard(
      title: '${adjustment.habitTitle}: ${_getTypeTitle(adjustment.type)}',
      description: adjustment.reason,
      quote: adjustment.suggestion,
      icon: _getIcon(adjustment.type),
      iconColor: _getColor(adjustment.type),
      footer: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: const StadiumBorder(),
                foregroundColor: Colors.white,
              ),
              child: const Text('Maybe Later'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextButton(
              onPressed: onAccept,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: const StadiumBorder(),
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.increase:
        return Icons.trending_up;
      case AdjustmentType.decrease:
        return Icons.trending_down;
      case AdjustmentType.maintain:
        return Icons.horizontal_rule;
    }
  }

  Color _getColor(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.increase:
        return AppTheme.vitalityGreen;
      case AdjustmentType.decrease:
        return Colors.amber;
      case AdjustmentType.maintain:
        return AppTheme.primary;
    }
  }

  String _getTypeTitle(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.increase:
        return 'Level Up!';
      case AdjustmentType.decrease:
        return 'Recalibrate';
      case AdjustmentType.maintain:
        return 'Stay the Course';
    }
  }
}
