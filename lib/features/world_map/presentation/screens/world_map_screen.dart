import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_header.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/attribute_colors.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_completion_result.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/presentation/providers/archetype_node_states_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/next_identity_vote_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_spark_burst.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_state_hud.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_status_panel.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_stoking_dock.dart';
import 'package:emerge_app/features/world_map/utils/ring_layout_geometry.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  final String? focusAttribute;

  const WorldMapScreen({super.key, this.focusAttribute});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  Timer? _navTimer;
  Timer? _flareTimer;
  bool _showStatus = false;
  bool _isFlaring = false;
  ({Offset start, Offset target, Color color})? _sparkBurst;

  // Narrator guide targets: the world body (ring layout) and the header HUD.
  final GlobalKey _mapBodyKey = GlobalKey();
  final GlobalKey _mapHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _handleFocus();
  }

  @override
  void didUpdateWidget(covariant WorldMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusAttribute != widget.focusAttribute) {
      _handleFocus();
    }
  }

  void _handleFocus() {
    if (widget.focusAttribute != null) {
      _navTimer?.cancel();
      _navTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          context.go('/world-map/attribute/${widget.focusAttribute}');
        }
      });
    }
  }

  void _handleCastVote(NextIdentityVote vote, Size size) {
    final habit = vote.habit;
    if (habit == null) return;

    final startOffset = Offset(size.width * 0.75, size.height - 45);
    final targetOffset = Offset(size.width / 2, size.height / 2);
    final color = vote.isRecovery
        ? const Color(0xFFA855F7)
        : (vote.attribute != null
            ? attributeColor(vote.attribute!)
            : EmergeColors.neonTeal);

    setState(() {
      _sparkBurst = (
        start: startOffset,
        target: targetOffset,
        color: color,
      );
    });

    try {
      ref.read(completeHabitProvider(habit.id).future).catchError((e, s) {
        AppLogger.e('Failed to complete habit from WorldMapScreen', e, s);
        return HabitCompletionResult.empty();
      });
    } catch (e, s) {
      AppLogger.e('Failed to trigger completeHabitProvider', e, s);
    }
  }

  void _onSparkBurstComplete() {
    _flareTimer?.cancel();
    setState(() {
      _sparkBurst = null;
      _isFlaring = true;
    });
    _flareTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isFlaring = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _flareTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final entropyAsync = ref.watch(worldEntropyStreamProvider);
    final nextVote = ref.watch(nextIdentityVoteProvider);
    final nodeStates = ref.watch(archetypeNodeStatesProvider);
    final displayName =
        ref.watch(userStatsStreamProvider).value?.displayName ?? '';

    return NarratorGuideHost(
      nodeId: 'world_map',
      targets: {'map_body': _mapBodyKey, 'map_header': _mapHeaderKey},
      child: Scaffold(
        body: healthAsync.when(
          loading: () =>
              const EmergeLoadingSkeleton(itemCount: 1, itemHeight: 300),
          error: (error, stack) => AppErrorWidget(
            message:
                "Couldn't load world state. Check your connection and try again.",
            onRetry: () => ref.invalidate(worldHealthStreamProvider),
          ),
          data: (health) {
            final entropy = entropyAsync.value ?? 0.0;
            return KeyedSubtree(
              key: _mapBodyKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final center = Offset(size.width / 2, size.height / 2);
                  final attributes = HabitAttribute.values;
                  final nodeCount = attributes.length;
                  const radius = 140.0;
                  final nodePositions = calculateRingNodePositions(
                    size: size,
                    radius: radius,
                    nodeCount: nodeCount,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      NebulaBackground(
                        healthState: WorldHealthState.fromHealth(health),
                        entropy: entropy,
                        primaryColor: Theme.of(context).colorScheme.primary,
                        accentColor: Theme.of(context).colorScheme.secondary,
                      ),
                      const AmbientParticles(particleCount: 50),
                      ConstellationLines(
                        center: center,
                        nodePositions: nodePositions,
                      ),
                      Center(
                        child: AnimatedScale(
                          scale: _isFlaring ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: WorldBonfire(
                            health: health,
                            isStatusVisible: _showStatus,
                            onTap: () =>
                                setState(() => _showStatus = !_showStatus),
                          ),
                        ),
                      ),
                      Center(
                        child: WorldRingLayout(
                          radius: radius,
                          focusAttribute: widget.focusAttribute,
                          nodeStates: nodeStates,
                          onNodeTap: (attr) =>
                              context.go('/world-map/attribute/${attr.name}'),
                        ),
                      ),
                      if (_showStatus)
                        const Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment(0, 0.34),
                            child: WorldStatusPanel(),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        // SafeArea here consumes the top inset, so the nested
                        // SafeArea inside EmergeHeader becomes a no-op (no
                        // double insets) and the HUD stays inside SafeArea.
                        child: KeyedSubtree(
                          key: _mapHeaderKey,
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmergeHeader(
                                  displayName: displayName,
                                  onAvatarTap: () => context.push('/profile'),
                                  onUpgradeTap: () => context.push('/paywall'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _showStatus = !_showStatus,
                                      ),
                                      child: const WorldStateHUD(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: SafeArea(
                          top: false,
                          child: WorldStokingDock(
                            vote: nextVote,
                            onCastVote: nextVote.habit != null
                                ? () => _handleCastVote(nextVote, size)
                                : null,
                            onOpenRecap: () => context.push('/recap-hub'),
                            onNewHabit: () => context.push('/habits/new'),
                            onOpenHabit: () {
                              if (nextVote.attribute != null) {
                                context.go(
                                  '/world-map/attribute/${nextVote.attribute!.name}',
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      if (_sparkBurst != null)
                        WorldSparkBurst(
                          startOffset: _sparkBurst!.start,
                          targetOffset: _sparkBurst!.target,
                          sparkColor: _sparkBurst!.color,
                          onComplete: _onSparkBurstComplete,
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
