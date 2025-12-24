import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:emerge_app/features/gamification/domain/models/world_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Bottom sheet showing zone details and available upgrades
class ZoneDetailSheet extends StatelessWidget {
  final String zoneId;
  final UserWorldState worldState;
  final Function(String buildingId)? onBuildingTap;

  const ZoneDetailSheet({
    super.key,
    required this.zoneId,
    required this.worldState,
    this.onBuildingTap,
  });

  @override
  Widget build(BuildContext context) {
    final zone = WorldZone.predefinedZones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => WorldZone.predefinedZones.first,
    );

    final zoneData =
        worldState.zones[zoneId] ?? {'level': 1, 'health': 1.0, 'milestone': 0};

    final level = zoneData['level'] as int? ?? 1;
    final health = (zoneData['health'] as num?)?.toDouble() ?? 1.0;
    final milestone = zoneData['milestone'] as int? ?? 0;
    final milestonesNeeded = level * 10;
    final progress = (milestone / milestonesNeeded).clamp(0.0, 1.0);

    final availableBuildings = WorldBuildingCatalog.getUnlockableBuildings(
      zoneId,
      level,
    );
    final unlockedBuildings = worldState.unlockedBuildings;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: _getZoneColor(zoneId).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Zone Header
              _buildZoneHeader(zone, level, health),

              const Gap(16),

              // Progress Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProgressSection(
                  milestone,
                  milestonesNeeded,
                  progress,
                ),
              ),

              const Gap(20),

              // Available Buildings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Blueprints',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Gap(12),

              // Building Grid
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: availableBuildings.length,
                  itemBuilder: (context, index) {
                    final building = availableBuildings[index];
                    final isUnlocked = unlockedBuildings.contains(building.id);

                    return _BuildingCard(
                          building: building,
                          isUnlocked: isUnlocked,
                          onTap: onBuildingTap != null
                              ? () => onBuildingTap!(building.id)
                              : null,
                        )
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneHeader(WorldZone zone, int level, double health) {
    final color = _getZoneColor(zone.id);
    final visualState = _getHealthText(health);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Zone Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(_getZoneIcon(zone.id), color: color, size: 28),
          ),

          const Gap(16),

          // Zone Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level $level',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      visualState,
                      style: TextStyle(
                        color: _getHealthColor(health),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Health Circle
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: health,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getHealthColor(health),
                  ),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '${(health * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
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
    );
  }

  Widget _buildProgressSection(int current, int needed, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress to Next Level',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$current / $needed',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
          const Gap(8),
          Text(
            progress >= 1.0
                ? '🎉 Ready to level up!'
                : 'Complete habits to grow this zone',
            style: TextStyle(
              color: progress >= 1.0 ? AppTheme.primary : Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthText(double health) {
    if (health >= 0.8) return '✨ Thriving';
    if (health >= 0.6) return '💚 Healthy';
    if (health >= 0.4) return '⚡ Stable';
    if (health >= 0.2) return '⚠️ Decaying';
    return '💀 Withered';
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.lightGreen;
    if (health >= 0.4) return Colors.amber;
    if (health >= 0.2) return Colors.orange;
    return Colors.red;
  }

  Color _getZoneColor(String zoneId) {
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

  IconData _getZoneIcon(String zoneId) {
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
}

/// Card showing a building that can be unlocked
class _BuildingCard extends StatelessWidget {
  final WorldBuilding building;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _BuildingCard({
    required this.building,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Building Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRarityColor(building.rarity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getBuildingIcon(building.type),
                color: _getRarityColor(building.rarity),
              ),
            ),

            const Gap(12),

            // Building Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      _RarityBadge(rarity: building.rarity),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    building.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status Icon
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock_outline,
              color: isUnlocked ? Colors.green : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(BuildingRarity rarity) {
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
        return Icons.park;
      case WorldElementType.decoration:
        return Icons.star;
      case WorldElementType.landmark:
        return Icons.emoji_events;
    }
  }
}

/// Small badge showing building rarity
class _RarityBadge extends StatelessWidget {
  final BuildingRarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: TextStyle(
          color: _getColor(),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
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
}
