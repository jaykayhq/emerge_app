import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/week_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/daily_summary_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/ai_coach_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/progress_recap_section.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/reflection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Main Timeline screen - the daily command center
/// Shows calendar, daily summary, progress/recaps, AI coach, and reflection
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _aiInsight;
  String? _suggestedHabit;
  bool _isLoadingInsight = true;

  @override
  void initState() {
    super.initState();
    _loadAiInsight();
  }

  Future<void> _loadAiInsight() async {
    try {
      final aiService = ref.read(aiPersonalizationServiceProvider);
      final habits = ref.read(habitsProvider).valueOrNull ?? [];

      if (habits.isNotEmpty) {
        final insights = await aiService.generateIdentityInsights(habits);
        if (insights.isNotEmpty && mounted) {
          setState(() {
            _aiInsight = insights.first.description;
            // Try to get a habit suggestion
            if (insights.length > 1) {
              _suggestedHabit = insights[1].action;
            }
            _isLoadingInsight = false;
          });
        } else if (mounted) {
          setState(() {
            _aiInsight = "Keep building consistency! Every vote counts.";
            _isLoadingInsight = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _aiInsight =
                "Create your first habit to start your identity journey!";
            _isLoadingInsight = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = "Focus on one small win today.";
          _isLoadingInsight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final userProfile = ref.watch(userStatsStreamProvider).valueOrNull;
    final archetypeTheme = ArchetypeTheme.forArchetype(
      userProfile?.archetype ?? UserArchetype.none,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            // Calculate completed today
            final now = DateTime.now();
            final completedToday = habits.where((h) {
              final lastCompleted = h.lastCompletedDate;
              if (lastCompleted == null) return false;
              return lastCompleted.year == now.year &&
                  lastCompleted.month == now.month &&
                  lastCompleted.day == now.day;
            }).toList();

            // Calculate total XP today
            final xpToday = completedToday.fold<int>(
              0,
              (sum, h) => sum + _calculateXp(h),
            );

            // Calculate best streak
            final bestStreak = habits.isEmpty
                ? 0
                : habits
                      .map((h) => h.currentStreak)
                      .reduce((a, b) => a > b ? a : b);

            // Calculate total votes (using longestStreak as a proxy)
            final totalVotes = habits.fold<int>(
              0,
              (sum, h) => sum + h.longestStreak,
            );

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  title: Column(
                    children: [
                      Text(
                        'TIMELINE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textMainDark,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'IDENTITY PROTOCOL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EmergeColors.teal,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),

                // Calendar Strip
                SliverToBoxAdapter(
                  child: WeekCalendarStrip(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Daily Summary Card
                SliverToBoxAdapter(
                  child: DailySummaryCard(
                    completedHabits: completedToday.length,
                    totalHabits: habits.length,
                    xpToday: xpToday,
                    currentStreak: bestStreak,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Progress / Recaps Section
                SliverToBoxAdapter(
                  child: ProgressRecapSection(
                    habits: habits,
                    completedToday: completedToday,
                    totalVotes: totalVotes,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // AI Coach Card
                SliverToBoxAdapter(
                  child: AiCoachCard(
                    insight: _aiInsight,
                    suggestedHabit: _suggestedHabit,
                    isLoading: _isLoadingInsight,
                    accentColor: archetypeTheme.primaryColor,
                    onReflect: () => context.push('/profile/reflections'),
                    onAddHabit: () => context.push('/create-habit'),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Reflection Card
                SliverToBoxAdapter(
                  child: ReflectionCard(
                    onLogReflection: (value, note) =>
                        _saveReflection(value, note),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: EmergeColors.teal),
          ),
          error: (e, s) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: EmergeColors.coral, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textMainDark,
                  ),
                ),
                Text(
                  '$e',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateXp(dynamic habit) {
    int base = 10;
    // Simple XP calculation based on difficulty
    if (habit.difficulty.toString().contains('medium')) {
      base = 20;
    } else if (habit.difficulty.toString().contains('hard')) {
      base = 30;
    }
    // Streak bonus
    final streakBonus = (habit.currentStreak * 0.1).clamp(0.0, 0.5);
    return (base * (1 + streakBonus)).toInt();
  }

  Future<void> _saveReflection(double moodValue, String? note) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    final now = DateTime.now();
    final reflection = Reflection(
      id: const Uuid().v4(),
      date:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      title: _getMoodTitle(moodValue),
      content: (note == null || note.isEmpty)
          ? 'Daily reflection logged'
          : note,
      type: 'daily',
      moodValue: moodValue,
      createdAt: now,
    );

    try {
      await ref
          .read(insightsRepositoryProvider)
          .saveReflection(user.id, reflection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reflection saved!'),
            backgroundColor: EmergeColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: EmergeColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getMoodTitle(double value) {
    if (value >= 0.8) return 'Feeling Great';
    if (value >= 0.6) return 'Feeling Good';
    if (value >= 0.4) return 'Feeling Okay';
    if (value >= 0.2) return 'Feeling Low';
    return 'Struggling';
  }
}
