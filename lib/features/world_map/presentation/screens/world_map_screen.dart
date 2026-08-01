import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_header.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';
import 'package:emerge_app/features/world_map/utils/ring_layout_geometry.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/tutorials/presentation/widgets/node_guide_host.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_state_hud.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_status_panel.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  final String? focusAttribute;

  const WorldMapScreen({super.key, this.focusAttribute});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  Timer? _navTimer;
  bool _showStatus = false;

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

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final entropyAsync = ref.watch(worldEntropyStreamProvider);
    final displayName =
        ref.watch(userStatsStreamProvider).value?.displayName ?? '';

    return NodeGuideHost(
      nodeId: 'world_map',
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
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
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
                      child: WorldRingLayout(
                        radius: radius,
                        focusAttribute: widget.focusAttribute,
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
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
