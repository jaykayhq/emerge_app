import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_expansion.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Screen for viewing and purchasing land expansions
class LandExpansionScreen extends ConsumerWidget {
  const LandExpansionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Expand Your World'),
        backgroundColor: Colors.transparent,
      ),
      body: statsAsync.when(
        data: (profile) {
          final worldLevel = _calculateWorldLevel(profile.worldState);
          final totalMilestones = _calculateTotalMilestones(profile.worldState);
          final unlockedPlots = profile.worldState.unlockedLandPlots;

          final availablePlots = LandExpansionCatalog.getAvailablePlots(
            worldLevel,
            unlockedPlots,
          );
          final userPlots = LandExpansionCatalog.getUnlockedPlots(
            unlockedPlots,
          );

          return CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: _buildStatsHeader(worldLevel, totalMilestones),
              ),

              // Unlocked Plots
              if (userPlots.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Your Territories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _LandPlotCard(
                              plot: userPlots[index],
                              isUnlocked: true,
                              canAfford: true,
                              onTap: null,
                            )
                            .animate()
                            .fadeIn(delay: (index * 100).ms)
                            .slideX(begin: 0.1),
                    childCount: userPlots.length,
                  ),
                ),
              ],

              // Available Plots
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Available Expansions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (availablePlots.isEmpty)
                SliverToBoxAdapter(
                  child: _buildNoExpansionsAvailable(worldLevel),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final plot = availablePlots[index];
                    final canAfford = totalMilestones >= plot.cost;

                    return _LandPlotCard(
                          plot: plot,
                          isUnlocked: false,
                          canAfford: canAfford,
                          onTap: canAfford
                              ? () => _purchasePlot(context, ref, plot, profile)
                              : null,
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideX(begin: 0.1);
                  }, childCount: availablePlots.length),
                ),

              // Locked Plots Preview
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Future Expansions',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lockedPlots = LandExpansionCatalog.allPlots
                        .where(
                          (p) =>
                              p.requiredWorldLevel > worldLevel &&
                              !unlockedPlots.contains(p.id),
                        )
                        .toList();
                    if (index >= lockedPlots.length) return null;

                    return _LandPlotCard(
                          plot: lockedPlots[index],
                          isUnlocked: false,
                          canAfford: false,
                          isLocked: true,
                          onTap: null,
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideX(begin: 0.1);
                  },
                  childCount: LandExpansionCatalog.allPlots
                      .where(
                        (p) =>
                            p.requiredWorldLevel > worldLevel &&
                            !unlockedPlots.contains(p.id),
                      )
                      .length,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStatsHeader(int worldLevel, int totalMilestones) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 15),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'World Level',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Level $worldLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 50, width: 1, color: Colors.white24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'World Points',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$totalMilestones',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildNoExpansionsAvailable(int worldLevel) {
    final nextPlot =
        LandExpansionCatalog.allPlots
            .where((p) => p.requiredWorldLevel > worldLevel)
            .toList()
          ..sort(
            (a, b) => a.requiredWorldLevel.compareTo(b.requiredWorldLevel),
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock, color: Colors.white38, size: 48),
          const Gap(12),
          const Text(
            'No new expansions available yet',
            style: TextStyle(color: Colors.white54),
          ),
          if (nextPlot.isNotEmpty) ...[
            const Gap(8),
            Text(
              'Reach World Level ${nextPlot.first.requiredWorldLevel} to unlock "${nextPlot.first.name}"',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  int _calculateWorldLevel(UserWorldState world) {
    // World level is average of all zone levels
    if (world.zones.isEmpty) return 1;

    int totalLevel = 0;
    for (final zone in world.zones.values) {
      totalLevel += (zone['level'] as int?) ?? 1;
    }
    return (totalLevel / world.zones.length).ceil();
  }

  int _calculateTotalMilestones(UserWorldState world) {
    // Total milestones from all zones
    int total = 0;
    for (final zone in world.zones.values) {
      total += (zone['milestone'] as int?) ?? 0;
      // Add milestones from completed levels
      final level = (zone['level'] as int?) ?? 1;
      for (int i = 1; i < level; i++) {
        total += i * 10; // Milestones needed per level
      }
    }
    return total;
  }

  Future<void> _purchasePlot(
    BuildContext context,
    WidgetRef ref,
    LandPlot plot,
    UserProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Expand to ${plot.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plot.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const Gap(16),
            Text(
              'Cost: ${plot.cost} World Points',
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Expand'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update world state with new plot
      final updatedPlots = [...profile.worldState.unlockedLandPlots, plot.id];
      final updatedWorld = profile.worldState.copyWith(
        unlockedLandPlots: updatedPlots,
      );

      await ref
          .read(userStatsControllerProvider)
          .updateWorldState(updatedWorld);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${plot.name} unlocked!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }
}

/// Card displaying a land plot
class _LandPlotCard extends StatelessWidget {
  final LandPlot plot;
  final bool isUnlocked;
  final bool canAfford;
  final bool isLocked;
  final VoidCallback? onTap;

  const _LandPlotCard({
    required this.plot,
    required this.isUnlocked,
    required this.canAfford,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.teal.withValues(alpha: 0.2)
              : isLocked
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? Colors.teal.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.teal.withValues(alpha: 0.3)
                    : isLocked
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUnlocked
                    ? Icons.terrain
                    : isLocked
                    ? Icons.lock
                    : Icons.add_location_alt,
                color: isUnlocked
                    ? Colors.teal
                    : isLocked
                    ? Colors.white24
                    : Colors.white54,
                size: 28,
              ),
            ),

            const Gap(16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.name,
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    plot.description,
                    style: TextStyle(
                      color: isLocked ? Colors.white24 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  if (!isUnlocked) ...[
                    const Gap(8),
                    Row(
                      children: [
                        if (isLocked)
                          Text(
                            'Requires Level ${plot.requiredWorldLevel}',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? Colors.teal.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${plot.cost} Points',
                              style: TextStyle(
                                color: canAfford ? Colors.teal : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status
            if (isUnlocked)
              const Icon(Icons.check_circle, color: Colors.teal)
            else if (!isLocked && canAfford)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
