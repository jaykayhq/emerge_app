import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Screen for placing buildings in the world using drag-and-drop
class BuildingPlacementScreen extends ConsumerStatefulWidget {
  const BuildingPlacementScreen({super.key});

  @override
  ConsumerState<BuildingPlacementScreen> createState() =>
      _BuildingPlacementScreenState();
}

class _BuildingPlacementScreenState
    extends ConsumerState<BuildingPlacementScreen> {
  String? _selectedBuildingId;
  Offset? _placementPosition;
  bool _isPlacing = false;
  final Map<String, Offset> _tempPlacements = {};

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Build Mode'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          if (_tempPlacements.isNotEmpty)
            TextButton.icon(
              onPressed: _savePlacements,
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Save', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      body: statsAsync.when(
        data: (profile) {
          final world = profile.worldState;
          final unlockedBuildings = world.unlockedBuildings;

          // Get available buildings user can place
          final availableBuildings = WorldBuildingCatalog.allBuildings
              .where((b) => unlockedBuildings.contains(b.id))
              .toList();

          return Stack(
            children: [
              // World Background
              _buildWorldView(world),

              // Placed Buildings
              ..._buildPlacedBuildings(world),

              // Currently Dragging Building
              if (_isPlacing && _placementPosition != null)
                _buildDraggingBuilding(),

              // Bottom Building Palette
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BuildingPalette(
                  buildings: availableBuildings,
                  selectedId: _selectedBuildingId,
                  existingPlacements: world.unlockedBuildings,
                  onBuildingSelected: (id) {
                    setState(() {
                      _selectedBuildingId = id;
                      _isPlacing = true;
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
              ),

              // Instructions Overlay
              if (_selectedBuildingId != null && _isPlacing)
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: _buildInstructionBanner(),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWorldView(UserWorldState world) {
    return GestureDetector(
      onTapUp: _isPlacing
          ? (details) {
              setState(() {
                _placementPosition = details.localPosition;
              });
            }
          : null,
      onPanUpdate: _isPlacing
          ? (details) {
              setState(() {
                _placementPosition = details.localPosition;
              });
            }
          : null,
      onPanEnd: _isPlacing
          ? (details) {
              if (_placementPosition != null && _selectedBuildingId != null) {
                _confirmPlacement();
              }
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a472a),
              const Color(0xFF2d5a27),
              const Color(0xFF3d7a2a),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Grid overlay for placement guidance
            CustomPaint(size: Size.infinite, painter: _GridPainter()),

            // World image
            Positioned.fill(
              child: Image.asset(
                'assets/images/world_sanctuary_base.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.7),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlacedBuildings(UserWorldState world) {
    final placements = <Widget>[];

    // Existing placements from world state
    for (final placement in world.buildingPlacements) {
      final buildingId = placement['buildingId'] as String?;
      final x = (placement['x'] as num?)?.toDouble() ?? 0.5;
      final y = (placement['y'] as num?)?.toDouble() ?? 0.5;

      if (buildingId != null) {
        placements.add(
          _PlacedBuilding(
            buildingId: buildingId,
            x: x,
            y: y,
            onTap: () => _showBuildingOptions(buildingId),
          ),
        );
      }
    }

    // Temporary placements (not yet saved)
    for (final entry in _tempPlacements.entries) {
      placements.add(
        _PlacedBuilding(
          buildingId: entry.key,
          x: entry.value.dx,
          y: entry.value.dy,
          isTemporary: true,
          onTap: () => _removeTempPlacement(entry.key),
        ),
      );
    }

    return placements;
  }

  Widget _buildDraggingBuilding() {
    final building = WorldBuildingCatalog.getBuildingById(_selectedBuildingId!);
    if (building == null) return const SizedBox.shrink();

    return Positioned(
      left: _placementPosition!.dx - 30,
      top: _placementPosition!.dy - 30,
      child: IgnorePointer(
        child:
            Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getRarityColor(
                      building.rarity,
                    ).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getRarityColor(building.rarity),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getBuildingIcon(building),
                    color: Colors.white,
                    size: 28,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app, color: Colors.black),
          const Gap(12),
          Expanded(
            child: Text(
              'Tap or drag to place your building',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.black54),
            onPressed: () {
              setState(() {
                _selectedBuildingId = null;
                _isPlacing = false;
                _placementPosition = null;
              });
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.5);
  }

  void _confirmPlacement() {
    if (_selectedBuildingId == null || _placementPosition == null) return;

    final screenSize = MediaQuery.of(context).size;
    final relativeX = _placementPosition!.dx / screenSize.width;
    final relativeY = _placementPosition!.dy / screenSize.height;

    setState(() {
      _tempPlacements[_selectedBuildingId!] = Offset(
        relativeX.clamp(0.1, 0.9),
        relativeY.clamp(0.15, 0.7),
      );
      _selectedBuildingId = null;
      _isPlacing = false;
      _placementPosition = null;
    });

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Building placed! Tap Save to confirm.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeTempPlacement(String buildingId) {
    setState(() {
      _tempPlacements.remove(buildingId);
    });
    HapticFeedback.lightImpact();
  }

  void _showBuildingOptions(String buildingId) {
    final building = WorldBuildingCatalog.getBuildingById(buildingId);
    if (building == null) return;

    // Get the placement data for this building from world state
    final currentProfile = ref.read(userStatsStreamProvider).valueOrNull;
    final placement = currentProfile?.worldState.buildingPlacements.firstWhere(
      (p) => p['buildingId'] == buildingId,
      orElse: () => <String, dynamic>{},
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              building.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              building.description,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: placement != null && placement.isNotEmpty
                      ? () {
                          Navigator.pop(context);
                          _startMoveBuilding(buildingId, placement);
                        }
                      : null,
                  icon: const Icon(Icons.open_with),
                  label: const Text('Move'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showBuildingDetailSheet(context, building);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startMoveBuilding(String buildingId, Map<String, dynamic> placement) {
    setState(() {
      _selectedBuildingId = buildingId;
      _isPlacing = true;
      _placementPosition = Offset(
        (placement['x'] as num).toDouble(),
        (placement['y'] as num).toDouble(),
      );
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap the new location for this building'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showBuildingDetailSheet(BuildContext context, WorldBuilding building) {
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getRarityColor(
                      building.rarity,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getBuildingIcon(building),
                    color: _getRarityColor(building.rarity),
                    size: 30,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRarityColor(
                            building.rarity,
                          ).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          building.rarity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getRarityColor(building.rarity),
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
            const Gap(20),
            Text(
              building.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Gap(16),
            _buildDetailRow('Zone', _getZoneName(building.zoneId)),
            _buildDetailRow('Type', building.type.name),
            _buildDetailRow(
              'Required Level',
              'Zone Level ${building.requiredZoneLevel}',
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(c),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  String _getZoneName(String zoneId) {
    final names = {
      'garden': 'Growth Garden',
      'library': 'Knowledge Library',
      'forge': 'Discipline Forge',
      'studio': 'Creative Studio',
      'shrine': 'Mindfulness Shrine',
    };
    return names[zoneId] ?? zoneId;
  }

  Future<void> _savePlacements() async {
    if (_tempPlacements.isEmpty) return;

    final userStatsController = ref.read(userStatsControllerProvider);
    final gamificationService = GamificationService();

    // Get current world state
    final currentProfile = ref.read(userStatsStreamProvider).valueOrNull;
    if (currentProfile == null) return;

    var updatedWorld = currentProfile.worldState;

    // Apply each placement
    for (final entry in _tempPlacements.entries) {
      updatedWorld = gamificationService.placeBuilding(
        updatedWorld,
        entry.key,
        entry.value.dx,
        entry.value.dy,
      );
    }

    // Save to Firestore
    await userStatsController.updateWorldState(updatedWorld);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_tempPlacements.length} building(s) placed!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _tempPlacements.clear();
      });
    }
  }

  void _showExitConfirmation(BuildContext context) {
    if (_tempPlacements.isEmpty) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Unsaved Changes',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved building placements. Do you want to save before leaving?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.pop();
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await _savePlacements();
              if (!context.mounted) return;
              context.pop();
            },
            child: const Text('Save'),
          ),
        ],
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

  IconData _getBuildingIcon(WorldBuilding building) {
    switch (building.type) {
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

/// Bottom palette showing available buildings
class _BuildingPalette extends StatelessWidget {
  final List<WorldBuilding> buildings;
  final String? selectedId;
  final List<String> existingPlacements;
  final Function(String) onBuildingSelected;

  const _BuildingPalette({
    required this.buildings,
    required this.selectedId,
    required this.existingPlacements,
    required this.onBuildingSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (buildings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: Text(
            'No buildings unlocked yet.\nComplete habits to unlock buildings!',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),

          Row(
            children: [
              const Icon(Icons.construction, color: AppTheme.primary, size: 20),
              const Gap(8),
              const Text(
                'Your Buildings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${buildings.length} unlocked',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const Gap(12),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: buildings.length,
              itemBuilder: (context, index) {
                final building = buildings[index];
                final isSelected = selectedId == building.id;

                return _BuildingPaletteItem(
                  building: building,
                  isSelected: isSelected,
                  onTap: () => onBuildingSelected(building.id),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0);
  }
}

/// Individual building item in the palette
class _BuildingPaletteItem extends StatelessWidget {
  final WorldBuilding building;
  final bool isSelected;
  final VoidCallback onTap;

  const _BuildingPaletteItem({
    required this.building,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(building.rarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(), color: color, size: 28),
            const Gap(4),
            Text(
              building.name,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  IconData _getIcon() {
    switch (building.type) {
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

/// A placed building on the world map
class _PlacedBuilding extends StatelessWidget {
  final String buildingId;
  final double x;
  final double y;
  final bool isTemporary;
  final VoidCallback? onTap;

  const _PlacedBuilding({
    required this.buildingId,
    required this.x,
    required this.y,
    this.isTemporary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final building = WorldBuildingCatalog.getBuildingById(buildingId);
    if (building == null) return const SizedBox.shrink();

    final color = _getRarityColor(building.rarity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final left = constraints.maxWidth * x - 25;
        final top = constraints.maxHeight * y - 25;

        return Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onTap: onTap,
            child:
                Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTemporary ? Colors.white : color,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              _getIcon(building),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (isTemporary)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                    .animate(
                      onPlay: isTemporary
                          ? (c) => c.repeat(reverse: true)
                          : null,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: Offset(isTemporary ? 1.1 : 1, isTemporary ? 1.1 : 1),
                      duration: 800.ms,
                    ),
          ),
        );
      },
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

  IconData _getIcon(WorldBuilding building) {
    switch (building.type) {
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

/// Grid overlay painter for placement guidance
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
