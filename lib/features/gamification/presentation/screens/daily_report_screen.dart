import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/avatar_display.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  String? _oracleInsight;
  bool _isLoadingInsight = true;

  @override
  void initState() {
    super.initState();
    _loadOracleInsight();
  }

  Future<void> _loadOracleInsight() async {
    try {
      final aiService = ref.read(aiPersonalizationServiceProvider);
      final habits = ref.read(habitsProvider).valueOrNull ?? [];

      if (habits.isNotEmpty) {
        final insights = await aiService.generateIdentityInsights(habits);
        if (insights.isNotEmpty && mounted) {
          setState(() {
            _oracleInsight = insights.first.description;
            _isLoadingInsight = false;
          });
        } else if (mounted) {
          setState(() {
            _oracleInsight = "Your consistency is building. Keep showing up!";
            _isLoadingInsight = false;
          });
        }
      } else {
        setState(() {
          _oracleInsight = "Start your journey by creating your first habit!";
          _isLoadingInsight = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _oracleInsight = "Stay focused on your goals today.";
          _isLoadingInsight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final userAsync = ref.watch(authStateChangesProvider);
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d • EEEE').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          SafeArea(
            child: statsAsync.when(
              data: (profile) => _buildContent(
                context,
                profile,
                habitsAsync.valueOrNull ?? [],
                userAsync.valueOrNull?.displayName ?? 'Hero',
                dateFormat,
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: EmergeColors.teal),
              ),
              error: (e, s) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfile profile,
    List<Habit> habits,
    String userName,
    String dateFormat,
  ) {
    final stats = profile.avatarStats;
    final completedToday = habits.where((h) {
      final lastCompleted = h.lastCompletedDate;
      if (lastCompleted == null) return false;
      final now = DateTime.now();
      return lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
    }).toList();

    final totalXpToday = completedToday.fold<int>(
      0,
      (sum, h) => sum + _calculateXp(h),
    );

    // Calculate level progress
    const xpPerLevel = 500;
    final currentLevelXp = stats.totalXp % xpPerLevel;
    final xpToNextLevel = xpPerLevel;
    final progress = currentLevelXp / xpToNextLevel;

    // Get archetype title
    final archetypeTitle = _getArchetypeTitle(profile.archetype);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMainDark),
                  onPressed: () => context.pop(),
                ),
                Column(
                  children: [
                    Text(
                      'Daily Report',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMainDark,
                      ),
                    ),
                    Text(
                      dateFormat,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: EmergeColors.teal,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.ios_share,
                    color: AppTheme.textMainDark,
                  ),
                  onPressed: () => _shareReport(profile, completedToday),
                ),
              ],
            ),
          ),
        ),

        // Avatar & Level Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EmergeColors.teal.withValues(alpha: 0.1),
                  AppTheme.surfaceDark,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: EmergeColors.teal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Avatar with Level Badge
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: EmergeColors.teal, width: 3),
                      ),
                      child: ClipOval(
                        child: AvatarDisplay(avatar: profile.avatar, size: 74),
                      ),
                    ),
                    if (totalXpToday > 0)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EmergeColors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'LEVEL UP!',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                  color: EmergeColors.background,
                                ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EmergeColors.teal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$totalXpToday XP',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: EmergeColors.background,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                // Level Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lvl ${stats.level} $archetypeTitle',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMainDark,
                            ),
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          Text(
                            'Progress to Lvl ${stats.level + 1}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondaryDark),
                          ),
                          const Spacer(),
                          Text(
                            '$currentLevelXp / $xpToNextLevel XP',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                      const Gap(6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: EmergeColors.teal.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            EmergeColors.teal,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
        ),

        const SliverToBoxAdapter(child: Gap(16)),

        // Attribute Cards
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _AttributeCard(
                  icon: Icons.fitness_center,
                  label: 'Athlete',
                  value: '+${stats.strengthXp}',
                  subtitle:
                      'Tier ${(stats.strengthXp / 100).floor() + 1} Active',
                  color: EmergeColors.coral,
                ),
                const Gap(12),
                _AttributeCard(
                  icon: Icons.auto_stories,
                  label: 'Scholar',
                  value: '+${stats.intellectXp}',
                  subtitle:
                      '+${((stats.intellectXp % 100) / 25).toInt()}% Growth',
                  color: EmergeColors.teal,
                ),
                const Gap(12),
                _AttributeCard(
                  icon: Icons.palette,
                  label: 'Creator',
                  value: '+${stats.creativityXp}',
                  subtitle: 'Streak x${stats.focusXp ~/ 50}',
                  color: EmergeColors.violet,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
        ),

        const SliverToBoxAdapter(child: Gap(20)),

        // Oracle Insight Card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EmergeColors.violet.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: EmergeColors.violet,
                      size: 20,
                    ),
                    const Gap(8),
                    Text(
                      'ORACLE INSIGHT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: EmergeColors.violet,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                if (_isLoadingInsight)
                  const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EmergeColors.violet,
                      ),
                    ),
                  )
                else
                  Text(
                    _oracleInsight ?? "Keep building your momentum!",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textMainDark,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ),

        const SliverToBoxAdapter(child: Gap(20)),

        // Mission Log Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Mission Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EmergeColors.hexLine),
                  ),
                  child: Text(
                    '${completedToday.length}/${habits.length} Complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(12)),

        // Mission Log List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final habit = habits[index];
              final isCompleted = completedToday.contains(habit);
              final xp = _calculateXp(habit);

              return _MissionLogItem(
                title: habit.title,
                xp: xp,
                isCompleted: isCompleted,
              ).animate().fadeIn(delay: (300 + index * 50).ms);
            }, childCount: habits.length.clamp(0, 5)),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Complete Day Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [EmergeColors.teal, EmergeColors.violet],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EmergeColors.teal.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _completeDay(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'COMPLETE DAY',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Gap(8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Tomorrow's Focus
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tomorrow's Focus",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(12),
                Row(
                  children: [
                    _FocusChip(
                      icon: Icons.fitness_center,
                      label: 'Train',
                      isSelected: true,
                      color: EmergeColors.coral,
                    ),
                    const Gap(8),
                    _FocusChip(
                      icon: Icons.menu_book,
                      label: 'Study',
                      isSelected: false,
                      color: EmergeColors.teal,
                    ),
                    const Gap(8),
                    _FocusChip(
                      icon: Icons.spa,
                      label: 'Rest',
                      isSelected: false,
                      color: EmergeColors.yellow,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ),

        const SliverToBoxAdapter(child: Gap(32)),
      ],
    );
  }

  int _calculateXp(Habit habit) {
    int base = 10;
    switch (habit.difficulty) {
      case HabitDifficulty.easy:
        base = 10;
        break;
      case HabitDifficulty.medium:
        base = 20;
        break;
      case HabitDifficulty.hard:
        base = 30;
        break;
    }
    // Streak bonus
    final streakBonus = (habit.currentStreak * 0.1).clamp(0, 0.5);
    return (base * (1 + streakBonus)).toInt();
  }

  String _getArchetypeTitle(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Warrior';
      case UserArchetype.scholar:
        return 'Sage';
      case UserArchetype.creator:
        return 'Artisan';
      case UserArchetype.stoic:
        return 'Ranger';
      case UserArchetype.none:
        return 'Adventurer';
    }
  }

  void _shareReport(UserProfile profile, List<Habit> completedToday) {
    final stats = profile.avatarStats;
    final message =
        '''
🎮 Daily Report - Emerge App

Level ${stats.level} ${_getArchetypeTitle(profile.archetype)}
✅ ${completedToday.length} habits completed today
⚡ Total XP: ${stats.totalXp}

Keep building your identity! 💪
''';
    SharePlus.instance.share(ShareParams(text: message));
  }

  void _completeDay(BuildContext context) {
    // Show a celebration and close
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Day completed! Great work! 🎉'),
        backgroundColor: EmergeColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.pop();
  }
}

class _AttributeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _AttributeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Gap(6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionLogItem extends StatelessWidget {
  final String title;
  final int xp;
  final bool isCompleted;

  const _MissionLogItem({
    required this.title,
    required this.xp,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? EmergeColors.teal.withValues(alpha: 0.3)
              : EmergeColors.hexLine,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? EmergeColors.teal : Colors.transparent,
              border: Border.all(
                color: isCompleted
                    ? EmergeColors.teal
                    : AppTheme.textSecondaryDark,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: EmergeColors.background,
                  )
                : null,
          ),
          const Gap(14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: isCompleted
                    ? AppTheme.textMainDark
                    : AppTheme.textSecondaryDark,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: EmergeColors.teal,
              ),
            ),
          ),
          Text(
            '+$xp XP',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCompleted
                  ? EmergeColors.teal
                  : AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;

  const _FocusChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? color
              : AppTheme.textSecondaryDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? color : AppTheme.textSecondaryDark,
          ),
          const Gap(8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppTheme.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
