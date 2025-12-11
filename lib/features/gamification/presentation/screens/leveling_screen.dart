import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class LevelingScreen extends ConsumerWidget {
  const LevelingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);
    final theme = Theme.of(context);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Level Progress'),
        backgroundColor: Colors.transparent,
      ),
      child: statsAsync.when(
        data: (profile) {
          final stats = profile.avatarStats;
          // Calculate XP for next level (simplified: 100 XP per level)
          final xpForNextLevel = 100;
          final currentLevelXp = stats.totalXp % xpForNextLevel;
          final progress = currentLevelXp / xpForNextLevel;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Gap(24),
                // Level Circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceDark,
                    border: Border.all(color: AppTheme.primary, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LEVEL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondaryDark,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '${stats.level}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const Gap(48),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress to Level ${stats.level + 1}',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '$currentLevelXp / $xpForNextLevel XP',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 16,
                        backgroundColor: AppTheme.surfaceDark,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const Gap(48),

                // Rewards Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.amber),
                          const Gap(12),
                          Text(
                            'Next Level Rewards',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      _RewardItem(
                        icon: Icons.auto_awesome,
                        text: 'New Attribute Point',
                        theme: theme,
                      ),
                      const Gap(12),
                      _RewardItem(
                        icon: Icons.lock_open,
                        text: 'Unlock "Master" Challenges',
                        theme: theme,
                      ),
                      const Gap(12),
                      _RewardItem(
                        icon: Icons.palette,
                        text: 'New Avatar Customization',
                        theme: theme,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _RewardItem({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.amber, size: 20),
        ),
        const Gap(12),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
