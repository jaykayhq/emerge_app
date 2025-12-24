import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_zone.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/animated_world_background.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/environment_effects.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_inhabitants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Interactive world visualization with zones that respond to health state
class WorldVisualization extends StatefulWidget {
  final UserWorldState worldState;
  final Function(String zoneId)? onZoneTap;
  final bool editMode;

  const WorldVisualization({
    super.key,
    required this.worldState,
    this.onZoneTap,
    this.editMode = false,
  });

  @override
  State<WorldVisualization> createState() => _WorldVisualizationState();
}

class _WorldVisualizationState extends State<WorldVisualization>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getThemeString() {
    switch (widget.worldState.worldTheme) {
      case WorldTheme.sanctuary:
        return 'city';
      case WorldTheme.island:
        return 'forest';
      case WorldTheme.settlement:
        return 'city';
      case WorldTheme.floatingRealm:
        return 'city';
    }
  }

  String _getSeasonString() {
    switch (widget.worldState.seasonalState) {
      case WorldSeason.spring:
        return 'spring';
      case WorldSeason.summer:
        return 'summer';
      case WorldSeason.autumn:
        return 'autumn';
      case WorldSeason.winter:
        return 'winter';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeString();
    final season = _getSeasonString();
    final isNight = DateTime.now().hour < 6 || DateTime.now().hour > 20;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _scrollOffset += details.delta.dx * 0.5;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated parallax background
          AnimatedWorldBackground(
            theme: theme,
            scrollOffset: _scrollOffset,
            isNightMode: isNight,
          ),

          // World inhabitants (NPCs)
          WorldInhabitants(
            theme: theme,
            populationCount: widget.worldState.isThriving ? 12 : 6,
            isNightMode: isNight,
          ),

          // Environment effects (weather/particles)
          EnvironmentEffects(
            theme: theme,
            season: season,
            isNightMode: isNight,
            intensity: widget.worldState.isDecaying ? 0.3 : 0.5,
          ),

          // Decay overlay (fog effect)
          if (widget.worldState.isDecaying) _buildDecayOverlay(),

          // Zone hotspots
          ..._buildZoneHotspots(),

          // Particle effects for thriving world
          if (widget.worldState.isThriving) _buildThriveParticles(),

          // Season indicator
          Positioned(top: 80, right: 16, child: _buildSeasonBadge()),
        ],
      ),
    );
  }

  // Note: _buildBaseLandscape removed - now using AnimatedWorldBackground widget

  Widget _buildDecayOverlay() {
    // Enhanced decay effect based on entropy level
    final entropy = widget.worldState.entropy;
    final fogOpacity = (entropy * 0.5).clamp(0.0, 0.4);
    final desaturation = (entropy * 0.8).clamp(0.0, 0.6);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Desaturation color filter
            if (entropy > 0.2)
              ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  _createDesaturationMatrix(
                    desaturation * _pulseController.value,
                  ),
                ),
                child: Container(color: Colors.transparent),
              ),

            // Fog/mist overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade900.withValues(
                      alpha: fogOpacity * (0.5 + _pulseController.value * 0.5),
                    ),
                  ],
                ),
              ),
            ),

            // Edge vignette for severe decay
            if (entropy > 0.5)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: (entropy - 0.5) * 0.6),
                    ],
                  ),
                ),
              ),

            // Warning particles for decaying world
            if (entropy > 0.4)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DecayParticlePainter(
                      progress: _pulseController.value,
                      intensity: entropy,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Create a desaturation matrix for color filtering
  List<double> _createDesaturationMatrix(double amount) {
    final inv = 1 - amount;
    final lumR = 0.2126 * amount;
    final lumG = 0.7152 * amount;
    final lumB = 0.0722 * amount;

    return [
      lumR + inv,
      lumG,
      lumB,
      0,
      0,
      lumR,
      lumG + inv,
      lumB,
      0,
      0,
      lumR,
      lumG,
      lumB + inv,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  List<Widget> _buildZoneHotspots() {
    // Position zones around the center in a circle pattern
    final zonePositions = {
      'garden': const Offset(0.5, 0.2), // Top center
      'library': const Offset(0.8, 0.35), // Right
      'forge': const Offset(0.75, 0.7), // Bottom right
      'studio': const Offset(0.25, 0.7), // Bottom left
      'shrine': const Offset(0.2, 0.35), // Left
    };

    return WorldZone.predefinedZones.map((zone) {
      final position = zonePositions[zone.id] ?? const Offset(0.5, 0.5);
      final zoneData = widget.worldState.zones[zone.id];
      final health = (zoneData?['health'] as num?)?.toDouble() ?? 1.0;
      final level = zoneData?['level'] as int? ?? 1;

      return Positioned(
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final x = constraints.maxWidth * position.dx;
            final y = constraints.maxHeight * position.dy;

            return Stack(
              children: [
                Positioned(
                  left: x - 40,
                  top: y - 40,
                  child: _ZoneHotspot(
                    zone: zone,
                    health: health,
                    level: level,
                    onTap: widget.onZoneTap != null
                        ? () => widget.onZoneTap!(zone.id)
                        : null,
                    isEditMode: widget.editMode,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildThriveParticles() {
    // Floating particle effect for thriving world
    return IgnorePointer(
      child: Container()
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 3.seconds,
            color: Colors.amber.withValues(alpha: 0.3),
          ),
    );
  }

  Widget _buildSeasonBadge() {
    final seasonData = _getSeasonData(widget.worldState.seasonalState);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: seasonData.color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: seasonData.color.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(seasonData.icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            seasonData.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.3);
  }

  _SeasonData _getSeasonData(WorldSeason season) {
    switch (season) {
      case WorldSeason.spring:
        return _SeasonData('Spring', Icons.local_florist, Colors.pink.shade300);
      case WorldSeason.summer:
        return _SeasonData('Summer', Icons.wb_sunny, Colors.orange);
      case WorldSeason.autumn:
        return _SeasonData('Autumn', Icons.eco, Colors.amber.shade700);
      case WorldSeason.winter:
        return _SeasonData('Winter', Icons.ac_unit, Colors.blue.shade300);
    }
  }
}

class _SeasonData {
  final String name;
  final IconData icon;
  final Color color;

  _SeasonData(this.name, this.icon, this.color);
}

/// Individual zone hotspot that can be tapped
class _ZoneHotspot extends StatelessWidget {
  final WorldZone zone;
  final double health;
  final int level;
  final VoidCallback? onTap;
  final bool isEditMode;

  const _ZoneHotspot({
    required this.zone,
    required this.health,
    required this.level,
    this.onTap,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visual state based on health
    final visualState = _getVisualState(health);
    final baseColor = _getZoneColor(zone.id);
    final adjustedColor = _adjustColorForHealth(baseColor, health);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child:
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: adjustedColor.withValues(alpha: 0.3),
                  border: Border.all(color: adjustedColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: adjustedColor.withValues(alpha: 0.5),
                      blurRadius: health > 0.7 ? 15 : 5,
                      spreadRadius: health > 0.7 ? 2 : 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getZoneIcon(zone.id), color: Colors.white, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      'Lv.$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Health bar
                    SizedBox(
                      width: 40,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: health,
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            visualState == ZoneVisualState.thriving
                                ? Colors.green
                                : visualState == ZoneVisualState.withered
                                ? Colors.red
                                : Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate(
                onPlay: health > 0.8 ? (c) => c.repeat(reverse: true) : null,
              )
              .scale(
                begin: const Offset(1, 1),
                end: Offset(health > 0.8 ? 1.05 : 1, health > 0.8 ? 1.05 : 1),
                duration: 1500.ms,
              ),
    );
  }

  ZoneVisualState _getVisualState(double health) {
    if (health >= 0.8) return ZoneVisualState.thriving;
    if (health >= 0.6) return ZoneVisualState.healthy;
    if (health >= 0.4) return ZoneVisualState.neutral;
    if (health >= 0.2) return ZoneVisualState.decaying;
    return ZoneVisualState.withered;
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

  Color _adjustColorForHealth(Color baseColor, double health) {
    if (health >= 0.7) return baseColor;
    if (health >= 0.4) {
      // Desaturate slightly
      return Color.lerp(baseColor, Colors.grey, 0.3)!;
    }
    // Very desaturated for low health
    return Color.lerp(baseColor, Colors.grey, 0.6)!;
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

/// Custom painter for decay particles
class _DecayParticlePainter extends CustomPainter {
  final double progress;
  final double intensity;

  _DecayParticlePainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: intensity * 0.3)
      ..style = PaintingStyle.fill;

    // Draw floating particles based on intensity
    final particleCount = (intensity * 20).toInt();
    final random = _SeededRandom(42); // Consistent seed for stable positions

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      // Particles drift upward
      final y = (baseY - progress * 50) % size.height;
      final radius = 2.0 + random.nextDouble() * 3;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DecayParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}

/// Simple seeded random for consistent particle positions
class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
