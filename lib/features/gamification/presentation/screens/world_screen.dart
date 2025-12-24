import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Your World'),
        backgroundColor: Colors.transparent,
      ),
      child: statsAsync.when(
        data: (profile) {
          final world = profile.worldState;
          return Stack(
            children: [
              // World Visualization (Dynamic Forest)
              Positioned.fill(
                child: _buildForest(world.forestLevel, world.entropy),
              ),

              // Stats Overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildWorldStats(world),
              ),

              // Goldilocks Suggestion (if applicable)
              if (world.entropy > 0.5)
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: _buildGoldilocksSuggestion(context),
                ),

              // Daily Recap Button (Bottom Part of Screen)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'world_recap_fab',
                  onPressed: () => context.go('/world/recap'),
                  label: const Text('Daily Recap'),
                  icon: const Icon(Icons.movie_filter),
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading world: $e')),
      ),
    );
  }

  Widget _buildForest(int level, double entropy) {
    // In a real app, this would be a custom painter or Rive animation.
    // For now, we simulate it with icons and colors.
    final isDecayed = entropy > 0.5;
    final treeColor = isDecayed ? Colors.brown : Colors.green;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                Icons.forest,
                size: 100 + (level * 10).toDouble(),
                color: treeColor.withValues(alpha: 1.0 - entropy * 0.5),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2.seconds,
              ),
          const Gap(16),
          Text(
            isDecayed
                ? 'The forest is withering...'
                : 'The forest is thriving!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldStats(dynamic world) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _WorldStat(
            label: 'Forest Lvl',
            value: '${world.forestLevel}',
            icon: Icons.nature,
            color: Colors.green,
          ),
          _WorldStat(
            label: 'City Lvl',
            value: '${world.cityLevel}',
            icon: Icons.location_city,
            color: Colors.blue,
          ),
          _WorldStat(
            label: 'Entropy',
            value: '${(world.entropy * 100).toInt()}%',
            icon: Icons.warning,
            color: world.entropy > 0.5 ? Colors.red : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildGoldilocksSuggestion(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primary),
              const Gap(16),
              Expanded(
                child: Text(
                  'The Goldilocks Engine suggests:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'Your world is decaying. Consider lowering the difficulty of your habits to regain momentum.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Implement difficulty adjustment logic
                  // For now, we just log the adjustment
                  debugPrint('Adjusting difficulty based on performance...');
                },
                child: const Text('Adjust Difficulty'),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms);
  }
}

class _WorldStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WorldStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
