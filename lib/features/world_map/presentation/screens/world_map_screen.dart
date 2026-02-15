import 'dart:ui';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/node_detail_sheet.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/pyramid_map_layout.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: statsAsync.when(
        data: (profile) {
          final archetype = profile.archetype;
          final mapConfig = ArchetypeMapsCatalog.getMapForArchetype(archetype);
          final currentLevel = profile.avatarStats.level;
          final currentBiome = ArchetypeMapConfig.getBiomeForLevel(
            currentLevel,
          );

          // Logic: Group nodes into sections of 5 levels
          // Section 1: Levels 1-5
          // Section 2: Levels 6-10
          // ...
          // A section is UNLOCKED only if the previous section is FULLY COMPLETED.
          // AND the user meets the level requirement for the specific node.

          final hydratedNodes = _hydrateNodesWithSectionLogic(
            mapConfig.nodes,
            profile,
          );

          return Stack(
            children: [
              // Layer 1: Parallax            // Background
              NebulaBackground(
                biome: currentBiome,
                primaryColor: mapConfig.primaryColor,
                accentColor: mapConfig.accentColor,
              ),

              // Layer 2: Map content (Pyramid Layout)
              SafeArea(
                bottom: false,
                child: PyramidMapLayout(
                  nodes: hydratedNodes,
                  primaryColor: mapConfig.primaryColor,
                  scrollController: _scrollController,
                  onNodeTap: (node) =>
                      _showNodeDetail(context, node, mapConfig),
                ),
              ),

              // Layer 3: Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _GlassmorphismTopBar(
                    config: mapConfig,
                    level: currentLevel,
                    biome: currentBiome,
                  ),
                ),
              ),

              // Layer 4: Bottom Stats Bar (Extended Full Width)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _GlassmorphismStatsBar(
                  profile: profile,
                  config: mapConfig,
                  hydratedNodes: hydratedNodes,
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

  List<WorldNode> _hydrateNodesWithSectionLogic(
    List<WorldNode> nodes,
    UserProfile profile,
  ) {
    // 1. Sort nodes by level
    final sortedNodes = List<WorldNode>.from(nodes)
      ..sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));

    // 2. Identify Sections (every 5 levels is a new section)
    // Section 1: Lv 1-5. Section 2: Lv 6-10.
    int getSection(int level) => ((level - 1) / 5).floor() + 1;

    // 3. Determine Completion of Sections
    final Map<int, bool> sectionCompletion = {};

    // Group by section
    final sectionNodes = <int, List<WorldNode>>{};
    for (var node in sortedNodes) {
      final section = getSection(node.requiredLevel);
      sectionNodes.putIfAbsent(section, () => []).add(node);
    }

    // Check completion for each section
    // A section is complete if ALL nodes in it are claimed
    int maxSection = 0;
    if (sectionNodes.isNotEmpty) {
      maxSection = sectionNodes.keys.reduce((a, b) => a > b ? a : b);
    }

    for (int i = 1; i <= maxSection; i++) {
      final nodesInSection = sectionNodes[i] ?? [];
      if (nodesInSection.isEmpty) {
        sectionCompletion[i] = true; // No nodes = complete
        continue;
      }

      final allClaimed = nodesInSection.every(
        (node) => profile.worldState.claimedNodes.contains(node.id),
      );
      sectionCompletion[i] = allClaimed;
    }

    // 4. Hydrate Nodes based on Rules
    return sortedNodes.map((node) {
      if (profile.worldState.claimedNodes.contains(node.id)) {
        return node.copyWith(state: NodeState.completed);
      }

      final section = getSection(node.requiredLevel);
      final previousSection = section - 1;

      // Rule 1: Previous section must be complete (if it exists)
      bool previousSectionComplete = true;
      if (previousSection >= 1) {
        previousSectionComplete = sectionCompletion[previousSection] ?? false;
      }

      if (!previousSectionComplete) {
        // Locked because previous section not done
        return node.copyWith(state: NodeState.locked);
      }

      // Rule 2: User Level must be sufficient
      // if (profile.avatarStats.level >= node.requiredLevel) {
      //   return node.copyWith(state: NodeState.available);
      // }
      // Actually, standard logic implies if previous section is done,
      // AND we are at the level, it's available.

      if (profile.avatarStats.level >= node.requiredLevel) {
        return node.copyWith(state: NodeState.available);
      }

      return node.copyWith(state: NodeState.locked);
    }).toList();
  }

  Future<void> _claimNode(WorldNode node, Color primaryColor) async {
    try {
      Navigator.pop(context);
      await ref.read(userStatsControllerProvider).claimNode(node.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claimed ${node.name}!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim node: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        userStats: ref.read(userStatsStreamProvider).value!.avatarStats,
        onAction: () {
          if (node.state == NodeState.available) {
            _claimNode(node, config.primaryColor);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

/// Glassmorphism top bar with journey info
class _GlassmorphismTopBar extends StatelessWidget {
  final ArchetypeMapConfig config;
  final int level;
  final BiomeType biome;

  const _GlassmorphismTopBar({
    required this.config,
    required this.level,
    required this.biome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: config.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Journey icon with glow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: config.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: config.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    config.journeyIcon,
                    color: config.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Map name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.mapName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                      Text(
                        'Valley of New Beginnings', // Hardcoded for this redesign
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: config.primaryColor.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: config.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: config.primaryColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'LVL $level',
                    style: TextStyle(
                      color: config.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism bottom stats bar - Extended Left to Right
class _GlassmorphismStatsBar extends StatelessWidget {
  final UserProfile profile;
  final ArchetypeMapConfig config;
  final List<WorldNode> hydratedNodes;

  const _GlassmorphismStatsBar({
    required this.profile,
    required this.config,
    required this.hydratedNodes,
  });

  @override
  Widget build(BuildContext context) {
    final stats = profile.avatarStats;
    final completedNodes = hydratedNodes
        .where(
          (n) =>
              n.state == NodeState.completed || n.state == NodeState.mastered,
        )
        .length;
    final totalNodes = config.nodes.length;

    // Calculate progress for XP bar
    // Simple logic: current XP / (level * 1000) or similar
    // Assuming 500 XP per level for viz
    final xpProgress = (stats.totalXp % 500) / 500.0;

    return ClipRRect(
      // No borders, full width at bottom (or just above nav bar if any, but Scaffold body covers it)
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            32,
          ), // Extra bottom padding for safe area
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: config.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // XP Progress Bar (Extended Left to Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP ${stats.totalXp}',
                    style: TextStyle(
                      color: EmergeColors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${(xpProgress * 100).toInt()}%',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(EmergeColors.yellow),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround, // Even spacing
                children: [
                  _StatItem(
                    label: 'Streak',
                    value: '${stats.streak}',
                    icon: Icons.local_fire_department,
                    color: EmergeColors.coral,
                  ),
                  _StatItem(
                    label: 'Nodes',
                    value: '$completedNodes/$totalNodes',
                    icon: Icons.check_circle_outline,
                    color: config.primaryColor,
                  ),
                  _StatItem(
                    label: 'World',
                    value: profile.worldState.isThriving
                        ? 'Thriving'
                        : 'Stable',
                    icon: Icons.public,
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
