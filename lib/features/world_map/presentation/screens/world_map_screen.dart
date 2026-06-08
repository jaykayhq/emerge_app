import 'dart:ui';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/world_entropy_provider.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/node_quest_dialog.dart';
import 'package:emerge_app/features/world_map/presentation/screens/level_immersive_screen.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/curved_map_layout.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Main World Map screen showing the archetype-specific progression map
/// Features vertical scrolling with biome transitions and node interactions
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _topBarKey = GlobalKey();
  final GlobalKey _statsBarKey = GlobalKey();
  final GlobalKey _firstNodeKey = GlobalKey();

  /// Whether the first-visit coach-mark overlay is visible.
  /// Set to true on first visit, dismissed by tapping anywhere.
  bool _showFirstVisitGuide = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/world-map')) {
        repo.markVisited('/world-map');
        ref.read(companionEngineProvider.notifier).triggerEvent(
          eventType: CompanionEventType.firstFeatureVisit,
          userContext: {'route': '/world-map'},
        );
        // Show the first-visit coach-mark to explain the World Map
        setState(() => _showFirstVisitGuide = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return WorldBackground(
      child: statsAsync.when(
        data: (profile) {
          final archetype = profile.archetype;
          final mapConfig = ArchetypeMapsCatalog.getMapForArchetype(archetype);
          final currentLevel = profile.effectiveLevel;
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
              // Layer 2: Map content (Curved Layout)
              SafeArea(
                bottom: false,
                child: CurvedMapLayout(
                  nodes: hydratedNodes,
                  primaryColor: mapConfig.primaryColor,
                  scrollController: _scrollController,
                  firstNodeKey: _firstNodeKey,
                  onNodeTap: (node) =>
                      _showNodeDetail(context, node, mapConfig),
                ),
              ),

              // Layer 2.5: Dynamic World Entropy Effects
              Consumer(
                builder: (context, ref, _) {
                  // Import the worldEntropyProvider at the top of the file
                  final effects = ref.watch(worldEntropyProvider);
                  if (effects.isEmpty) return const SizedBox.shrink();

                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          if (effects.contains('dark_sky'))
                            Container(
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          if (effects.contains('fog'))
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                          if (effects.contains('weeds'))
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.brown.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Layer 3: Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _GlassmorphismTopBar(
                    key: _topBarKey,
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
                  key: _statsBarKey,
                  profile: profile,
                  config: mapConfig,
                  hydratedNodes: hydratedNodes,
                ),
              ),

              // Layer 5: First-Visit Coach-Mark Overlay
              if (_showFirstVisitGuide)
                _WorldMapCoachMark(
                  primaryColor: mapConfig.primaryColor,
                  onDismiss: () => setState(() => _showFirstVisitGuide = false),
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
      if ((sectionNodes[section]?.length ?? 0) >= 5) continue;
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
    final filteredNodes = sectionNodes.values.expand((e) => e).toList();
    return filteredNodes.map((node) {
      if (profile.worldState.claimedNodes.contains(node.id)) {
        return node.copyWith(state: NodeState.completed);
      }

      // Check if mission is in progress
      if (profile.worldState.activeNodes.contains(node.id)) {
        return node.copyWith(state: NodeState.inProgress);
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

      // Rule 2: User effective level must be sufficient
      if (profile.effectiveLevel >= node.requiredLevel) {
        return node.copyWith(state: NodeState.available);
      }

      return node.copyWith(state: NodeState.locked);
    }).toList();
  }

  void _showNodeDetail(
    BuildContext context,
    WorldNode node,
    ArchetypeMapConfig config,
  ) {
    if (node.state == NodeState.locked) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (dialogContext) => NodeQuestDialog(
          node: node,
          primaryColor: config.primaryColor,
          userLevel: ref.read(userStatsStreamProvider).value?.effectiveLevel ?? 1,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LevelImmersiveScreen(node: node, config: config),
        ),
      );
    }
  }
}

/// Glassmorphism top bar with journey info
class _GlassmorphismTopBar extends StatelessWidget {
  final ArchetypeMapConfig config;
  final int level;
  final BiomeType biome;

  const _GlassmorphismTopBar({
    super.key,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                          Row(
                            children: [
                              Text(
                                'Valley of New Beginnings',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: config.primaryColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Consumer(
                                builder: (context, ref, _) {
                                  final isPremium =
                                      ref.watch(isPremiumProvider).value ??
                                      false;
                                  if (!isPremium) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: config.primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: config.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: config.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final statsAsync = ref.watch(userStatsStreamProvider);
                    final stats = statsAsync.value?.avatarStats;
                    if (stats == null) return const SizedBox.shrink();
                    final progress = (stats.totalXp % 500) / 500.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: config.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        config.primaryColor,
                      ),
                      minHeight: 2,
                      borderRadius: BorderRadius.circular(99),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism bottom stats bar - Stitch World Map design
class _GlassmorphismStatsBar extends StatelessWidget {
  final UserProfile profile;
  final ArchetypeMapConfig config;
  final List<WorldNode> hydratedNodes;

  const _GlassmorphismStatsBar({
    super.key,
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32, // Extra bottom padding for safe area
          ),
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
              // Stats Row - Stitch style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Streak',
                    value: '${stats.streak}',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF7F50), // Coral
                  ),
                  // When no nodes are completed yet, show a contextual nudge
                  // instead of the raw '0/X' number so new users know what to do.
                  completedNodes == 0
                      ? _NudgeStatItem(
                          label: 'Tap any node',
                          nudge: 'to begin',
                          icon: Icons.touch_app_rounded,
                          color: config.primaryColor,
                        )
                      : _StatItem(
                          label: 'Nodes',
                          value: '$completedNodes/$totalNodes',
                          icon: Icons.check_circle_outline,
                          color: config.primaryColor,
                        ),
                  _StatItem(
                    label: 'Challenges',
                    value: '${stats.challengeXp}',
                    icon: Icons.emoji_events,
                    color: const Color(0xFFFFD700), // Gold
                  ),
                  _WorldOrb(profile: profile),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Column(
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
      ),
    );
  }
}

class _WorldOrb extends ConsumerWidget {
  final UserProfile profile;
  const _WorldOrb({required this.profile});

  Color get _orbColor {
    final score = profile.momentumScore;
    if (score >= 0.75) return const Color(0xFF00FF9C);
    if (score >= 0.4) return const Color(0xFF4FC3F7);
    return const Color(0xFFFF7043);
  }

  String get _stateLabel {
    final score = profile.momentumScore;
    if (score >= 0.75) return 'Thriving';
    if (score >= 0.4) return 'Neutral';
    return 'Decaying';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showWorldStateSheet(context, ref),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _orbColor.withValues(alpha: 0.15),
              border: Border.all(
                color: _orbColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _orbColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.public, color: _orbColor, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _stateLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorldStateSheet(BuildContext context, WidgetRef ref) {
    final score = (profile.momentumScore * 100).round();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WorldStateSheet(
        score: score,
        stateLabel: _stateLabel,
        orbColor: _orbColor,
      ),
    );
  }
}

class _WorldStateSheet extends StatelessWidget {
  final int score;
  final String stateLabel;
  final Color orbColor;
  const _WorldStateSheet({
    required this.score,
    required this.stateLabel,
    required this.orbColor,
  });

  @override
  Widget build(BuildContext context) {
    String advice;
    if (score >= 75) {
      advice =
          'Your world is flourishing. Keep your habits alive to maintain this.';
    } else if (score >= 40) {
      advice =
          'Your world is stable. Complete more habits today to make it thrive.';
    } else {
      advice =
          'Your world is decaying. Complete any habit now to start recovery.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'World State',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: orbColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(orbColor),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: orbColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: orbColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: orbColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              stateLabel,
              style: TextStyle(color: orbColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            advice,
            style: const TextStyle(color: Colors.white60, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/recap-hub');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EmergeColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'WEEKLY RECAP & INSIGHTS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                foregroundColor: Colors.white60,
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nudge variant of _StatItem — shown when completedNodes == 0
class _NudgeStatItem extends StatelessWidget {
  final String label;
  final String nudge;
  final IconData icon;
  final Color color;

  const _NudgeStatItem({
    required this.label,
    required this.nudge,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        Text(
          nudge,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Dismissable coach-mark shown on the user's first visit to the World Map.
/// Explains the three key concepts (Journey, Nodes, Path) in plain language.
class _WorldMapCoachMark extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback onDismiss;

  const _WorldMapCoachMark({
    required this.primaryColor,
    required this.onDismiss,
  });

  @override
  State<_WorldMapCoachMark> createState() => _WorldMapCoachMarkState();
}

class _WorldMapCoachMarkState extends State<_WorldMapCoachMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                // Prevent taps on the card itself from dismissing
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12122A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.map_outlined,
                              color: widget.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Journey Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          // Dismiss hint
                          Text(
                            'Tap anywhere to close',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // The three plain-language explanations
                      _CoachItem(
                        icon: Icons.route_outlined,
                        color: widget.primaryColor,
                        title: 'This is your Journey',
                        body:
                            'A progression map built around your identity archetype. The path grows as you level up.',
                      ),
                      const SizedBox(height: 12),
                      _CoachItem(
                        icon: Icons.radio_button_unchecked,
                        color: widget.primaryColor,
                        title: 'Nodes are habit missions',
                        body:
                            'Each circle on the path is a Node — a mission tied to your archetype. Tap one to start it and earn XP.',
                      ),
                      const SizedBox(height: 12),
                      _CoachItem(
                        icon: Icons.lock_open_outlined,
                        color: widget.primaryColor,
                        title: 'Complete to unlock more',
                        body:
                            'Finish the Nodes in each section to unlock the next area. Complete habits daily to keep levelling up.',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "GOT IT \u2014 LET'S GO",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single explanatory row inside the coach-mark card
class _CoachItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _CoachItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
