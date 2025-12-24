import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/growing_world_visualization.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/zone_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// The main Growing World screen showing the user's evolving world
class GrowingWorldScreen extends ConsumerStatefulWidget {
  const GrowingWorldScreen({super.key});

  @override
  ConsumerState<GrowingWorldScreen> createState() => _GrowingWorldScreenState();
}

class _GrowingWorldScreenState extends ConsumerState<GrowingWorldScreen> {
  late ConfettiController _confettiController;
  String? _selectedZoneId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for Level Changes
    ref.listen<AsyncValue<UserProfile>>(userStatsStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((currentProfile) {
        previous?.whenData((prevProfile) {
          if (currentProfile.avatarStats.level >
              prevProfile.avatarStats.level) {
            _confettiController.play();
            _showLevelUpDialog(context, currentProfile.avatarStats.level);
          }
        });
      });
    });

    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Your World'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.movie_filter),
            onPressed: () => context.push('/world/recap'),
            tooltip: 'Cinematic Recap',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showWorldSettings(context),
            tooltip: 'World Settings',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (profile) {
          final world = profile.worldState;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Screen World Visualization
              WorldVisualization(
                worldState: world,
                onZoneTap: (zoneId) => _showZoneDetails(context, zoneId, world),
              ),

              // Confetti Overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),

              // 2. Gradient Overlays
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.backgroundDark.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.backgroundDark.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Stats Bar (Top)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(50), // Space for AppBar
                      _buildWorldStatsBar(world, profile.avatarStats),
                      const Spacer(),
                      // Bottom Action Buttons
                      _buildBottomActions(context, world),
                    ],
                  ),
                ),
              ),

              // Zone Detail Sheet (if a zone is selected)
              if (_selectedZoneId != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedZoneId = null),
                    child: Container(color: Colors.black54),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              Gap(16),
              Text(
                'Loading your world...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const Gap(16),
              Text('Error: $e', style: const TextStyle(color: Colors.white)),
              const Gap(16),
              ElevatedButton(
                onPressed: () => ref.refresh(userStatsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorldStatsBar(UserWorldState world, UserAvatarStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Level Badge
          _StatBadge(
            icon: Icons.star,
            label: 'Level',
            value: '${stats.level}',
            color: Colors.amber,
          ),
          const Gap(12),
          // World Health
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'World Health',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(world.worldHealth * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: world.worldHealth,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      world.isThriving
                          ? Colors.green
                          : world.isDecaying
                          ? Colors.orange
                          : Colors.amber,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          // Streak
          _StatBadge(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${stats.streak}',
            color: Colors.orange,
            isHighlight: stats.streak >= 7,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildBottomActions(BuildContext context, UserWorldState world) {
    final hasUnlockedBuildings = world.unlockedBuildings.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Info Button
            FloatingActionButton.extended(
              heroTag: 'zone_info',
              onPressed: () => _showZoneOverview(context, world),
              backgroundColor: AppTheme.surfaceDark,
              icon: const Icon(Icons.grid_view, color: AppTheme.primary),
              label: const Text('Zones', style: TextStyle(color: Colors.white)),
            ),
            const Gap(8),
            // Build Mode Button
            FloatingActionButton.extended(
              heroTag: 'build_mode',
              onPressed: hasUnlockedBuildings
                  ? () => context.push('/world/build')
                  : () => _showNoBuildsMessage(context),
              backgroundColor: hasUnlockedBuildings
                  ? Colors.teal.shade700
                  : AppTheme.surfaceDark.withValues(alpha: 0.5),
              icon: Icon(
                Icons.construction,
                color: hasUnlockedBuildings ? Colors.white : Colors.white54,
              ),
              label: Text(
                'Build',
                style: TextStyle(
                  color: hasUnlockedBuildings ? Colors.white : Colors.white54,
                ),
              ),
            ),
            const Gap(8),
            // Expand Button
            FloatingActionButton.extended(
              heroTag: 'expand_land',
              onPressed: () => context.push('/world/expand'),
              backgroundColor: Colors.deepPurple.shade700,
              icon: const Icon(Icons.terrain, color: Colors.white),
              label: const Text(
                'Expand',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Daily Report FAB
            FloatingActionButton.extended(
              heroTag: 'daily_report',
              onPressed: () => context.push('/world/daily-report'),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.today, color: Colors.black),
              label: const Text(
                'Daily Report',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(12),
            // Recap Button
            FloatingActionButton.small(
              heroTag: 'recap',
              onPressed: () => context.push('/world/recap'),
              backgroundColor: AppTheme.surfaceDark,
              child: const Icon(Icons.movie_filter, color: AppTheme.primary),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
      ],
    );
  }

  void _showNoBuildsMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete habits to unlock buildings for your world!'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showZoneDetails(
    BuildContext context,
    String zoneId,
    UserWorldState worldState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ZoneDetailSheet(
        zoneId: zoneId,
        worldState: worldState,
        onBuildingTap: (buildingId) {
          Navigator.pop(context);
          _showBuildingDetail(context, buildingId);
        },
      ),
    );
  }

  void _showZoneOverview(BuildContext context, UserWorldState world) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your Zones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            for (final zoneId in [
              'garden',
              'library',
              'forge',
              'studio',
              'shrine',
            ])
              _ZoneOverviewRow(
                zoneId: zoneId,
                zoneData: world.zones[zoneId],
                onTap: () {
                  Navigator.pop(context);
                  _showZoneDetails(context, zoneId, world);
                },
              ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  void _showBuildingDetail(BuildContext context, String buildingId) {
    final building = WorldBuildingCatalog.getBuildingById(buildingId);
    if (building == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Building: $buildingId'),
          backgroundColor: AppTheme.surfaceDark,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getBuildingRarityColor(
                      building.rarity,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getBuildingIcon(building.type),
                    color: _getBuildingRarityColor(building.rarity),
                    size: 28,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getBuildingRarityColor(
                            building.rarity,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          building.rarity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getBuildingRarityColor(building.rarity),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              building.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const Gap(16),
            _buildBuildingInfoRow('Zone', building.zoneId),
            _buildBuildingInfoRow('Type', building.type.name),
            _buildBuildingInfoRow(
              'Required Level',
              'Lv. ${building.requiredZoneLevel}',
            ),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(c),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Color _getBuildingRarityColor(BuildingRarity rarity) {
    switch (rarity) {
      case BuildingRarity.common:
        return Colors.grey;
      case BuildingRarity.uncommon:
        return Colors.green;
      case BuildingRarity.rare:
        return Colors.blue;
      case BuildingRarity.epic:
        return Colors.purple;
      case BuildingRarity.legendary:
        return Colors.amber;
    }
  }

  IconData _getBuildingIcon(WorldElementType type) {
    switch (type) {
      case WorldElementType.building:
        return Icons.home;
      case WorldElementType.vegetation:
        return Icons.eco;
      case WorldElementType.decoration:
        return Icons.local_florist;
      case WorldElementType.landmark:
        return Icons.flag;
    }
  }

  void _showWorldSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'World Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.teal),
              title: const Text(
                'Change Theme',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Customize world appearance',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.pop(c);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain, color: Colors.green),
              title: const Text(
                'Expand Land',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Unlock new territories',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.pop(c);
                context.push('/world/expand');
              },
            ),
            ListTile(
              leading: const Icon(Icons.construction, color: Colors.orange),
              title: const Text(
                'Build Mode',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Place and arrange buildings',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.pop(c);
                context.push('/world/build');
              },
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'LEVEL UP!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 64,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const Gap(16),
            Text(
              'You reached Level $newLevel',
              style: const TextStyle(color: Colors.white),
            ),
            const Text(
              'Your world is evolving!',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }
}

/// Small stat badge for the stats bar
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isHighlight;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? color : Colors.transparent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const Gap(2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row showing a zone in the overview
class _ZoneOverviewRow extends StatelessWidget {
  final String zoneId;
  final Map<String, dynamic>? zoneData;
  final VoidCallback onTap;

  const _ZoneOverviewRow({
    required this.zoneId,
    required this.zoneData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = zoneData?['level'] as int? ?? 1;
    final health = (zoneData?['health'] as num?)?.toDouble() ?? 1.0;

    return ListTile(
      onTap: onTap,
      leading: Icon(_getZoneIcon(), color: _getZoneColor()),
      title: Text(_getZoneName(), style: const TextStyle(color: Colors.white)),
      subtitle: Row(
        children: [
          Text(
            'Level $level',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Gap(8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: health,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  health >= 0.7 ? Colors.green : Colors.orange,
                ),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  String _getZoneName() {
    switch (zoneId) {
      case 'garden':
        return 'The Garden';
      case 'library':
        return 'The Library';
      case 'forge':
        return 'The Forge';
      case 'studio':
        return 'The Studio';
      case 'shrine':
        return 'The Shrine';
      default:
        return zoneId;
    }
  }

  IconData _getZoneIcon() {
    switch (zoneId) {
      case 'garden':
        return Icons.local_florist;
      case 'library':
        return Icons.menu_book;
      case 'forge':
        return Icons.fitness_center;
      case 'studio':
        return Icons.palette;
      case 'shrine':
        return Icons.self_improvement;
      default:
        return Icons.place;
    }
  }

  Color _getZoneColor() {
    switch (zoneId) {
      case 'garden':
        return Colors.green;
      case 'library':
        return Colors.blue;
      case 'forge':
        return Colors.orange;
      case 'studio':
        return Colors.purple;
      case 'shrine':
        return Colors.teal;
      default:
        return AppTheme.primary;
    }
  }
}
