import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Overlay notification for building unlocks
class BuildingUnlockNotification extends StatelessWidget {
  final WorldBuilding building;
  final VoidCallback onDismiss;
  final VoidCallback? onPlaceNow;

  const BuildingUnlockNotification({
    super.key,
    required this.building,
    required this.onDismiss,
    this.onPlaceNow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child:
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRarityColor(building.rarity).withValues(alpha: 0.9),
                      _getRarityColor(building.rarity).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColor(
                        building.rarity,
                      ).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getBuildingIcon(building.type),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const Gap(4),
                                  const Text(
                                    'NEW BLUEPRINT UNLOCKED!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(2),
                              Text(
                                building.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _RarityBadge(rarity: building.rarity),
                      ],
                    ),

                    const Gap(12),

                    // Description
                    Text(
                      building.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Gap(16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: onDismiss,
                          child: const Text(
                            'Later',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: onPlaceNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getRarityColor(building.rarity),
                          ),
                          icon: const Icon(Icons.place),
                          label: const Text('Place Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(
                begin: -0.3,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .then()
              .shimmer(duration: 1000.ms, color: Colors.white24),
    );
  }

  Color _getRarityColor(BuildingRarity rarity) {
    switch (rarity) {
      case BuildingRarity.common:
        return Colors.grey.shade600;
      case BuildingRarity.uncommon:
        return Colors.green.shade600;
      case BuildingRarity.rare:
        return Colors.blue.shade600;
      case BuildingRarity.epic:
        return Colors.purple.shade600;
      case BuildingRarity.legendary:
        return Colors.amber.shade700;
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

/// Small rarity badge
class _RarityBadge extends StatelessWidget {
  final BuildingRarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Service to show building unlock notifications
class BuildingUnlockService {
  static OverlayEntry? _currentOverlay;

  static void showUnlock(
    BuildContext context,
    WorldBuilding building, {
    VoidCallback? onPlaceNow,
  }) {
    // Dismiss existing overlay if any
    _currentOverlay?.remove();

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: BuildingUnlockNotification(
          building: building,
          onDismiss: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
          },
          onPlaceNow: () {
            _currentOverlay?.remove();
            _currentOverlay = null;
            onPlaceNow?.call();
          },
        ),
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
}
