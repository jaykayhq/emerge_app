import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_semantics.dart';
import 'package:emerge_app/core/theme/emerge_dimensions.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/node_map_canvas.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/node_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main World Map screen showing the archetype-specific progression map
/// Features vertical scrolling with biome transitions and node interactions
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: statsAsync.when(
        data: (profile) {
          final archetype = profile.archetype;
          final mapConfig = ArchetypeMapsCatalog.getMapForArchetype(archetype);
          final currentLevel = profile.avatarStats.level;
          final currentBiome = ArchetypeMapConfig.getBiomeForLevel(
            currentLevel,
          );

          return Stack(
            children: [
              // Background gradient based on biome
              _buildBackground(currentBiome, mapConfig),

              // Map content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with map info
                    _buildTopBar(
                      context,
                      mapConfig,
                      currentLevel,
                      currentBiome,
                    ),

                    // Node map
                    Expanded(
                      child: NodeMapCanvas(
                        nodes: mapConfig.nodes,
                        primaryColor: mapConfig.primaryColor,
                        accentColor: mapConfig.accentColor,
                        currentLevel: currentLevel,
                        scrollController: _scrollController,
                        onNodeTap: (node) =>
                            _showNodeDetail(context, node, mapConfig),
                      ),
                    ),

                    // Bottom stats bar
                    _buildBottomStatsBar(context, profile, mapConfig),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: EmergeColors.teal)),
        error: (e, s) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppTheme.textMainDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(BiomeType biome, ArchetypeMapConfig config) {
    final biomeColors = ArchetypeMapConfig.getBiomeColors(biome);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                biomeColors[0],
                biomeColors[1],
                config.backgroundGradient[0],
                config.backgroundGradient[1],
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Ambient particles effect
        Positioned.fill(
          child: _AmbientParticles(
            color: config.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ArchetypeMapConfig config,
    int level,
    BiomeType biome,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Map icon and name
          Icon(config.journeyIcon, color: config.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.mapName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ArchetypeMapConfig.getBiomeName(biome),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: config.primaryColor),
                ),
              ],
            ),
          ),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: config.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: config.primaryColor),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: config.primaryColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  'LVL $level',
                  style: TextStyle(
                    color: config.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsBar(
    BuildContext context,
    UserProfile profile,
    ArchetypeMapConfig config,
  ) {
    final stats = profile.avatarStats;
    final completedNodes = config.nodes
        .where(
          (n) =>
              n.state == NodeState.completed || n.state == NodeState.mastered,
        )
        .length;
    final totalNodes = config.nodes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // XP
          _StatItem(
            icon: Icons.bolt,
            label: 'XP',
            value: '${stats.totalXp}',
            color: EmergeColors.yellow,
          ),
          const SizedBox(width: 16),
          // Streak
          _StatItem(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${stats.streak}',
            color: EmergeColors.coral,
          ),
          const SizedBox(width: 16),
          // Nodes completed
          _StatItem(
            icon: Icons.check_circle,
            label: 'Nodes',
            value: '$completedNodes/$totalNodes',
            color: config.primaryColor,
          ),
          const Spacer(),
          // World Health
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'World Health',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: EmergeDimensions.minFontSize, // 12px minimum
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: profile.worldState.worldHealth,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(
                      profile.worldState.isThriving
                          ? Colors.green
                          : profile.worldState.isDecaying
                          ? Colors.orange
                          : Colors.amber,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNodeDetail(
    BuildContext context,
    WorldNode node,
    ArchetypeMapConfig config,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NodeDetailSheet(
        node: node,
        primaryColor: config.primaryColor,
        onFocusNode: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Now focusing on: ${node.name}'),
              backgroundColor: config.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EmergeSemantics(
      label: '$label: $value',
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: EmergeDimensions.minFontSize, // 12px minimum
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmbientParticles extends StatefulWidget {
  final Color color;
  const _AmbientParticles({required this.color});

  @override
  State<_AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<_AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize random particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle.random());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });

  factory _Particle.random() {
    return _Particle(
      x: (DateTime.now().microsecondsSinceEpoch % 100) / 100.0,
      y: (DateTime.now().microsecondsSinceEpoch % 100) / 100.0,
      speed: 0.05 + ((DateTime.now().microsecondsSinceEpoch % 50) / 1000.0),
      size: 2.0 + (DateTime.now().microsecondsSinceEpoch % 4),
      opacity: 0.2 + ((DateTime.now().microsecondsSinceEpoch % 50) / 100.0),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (var particle in particles) {
      // Move particle up slowly
      double y = particle.y - (progress * particle.speed);
      if (y < 0) y += 1.0;

      final position = Offset(particle.x * size.width, y * size.height);

      paint.color = color.withValues(alpha: particle.opacity);
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
