import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';
import 'package:emerge_app/features/world_map/utils/ring_layout_geometry.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'dart:math' as math;

class WorldMapScreen extends ConsumerStatefulWidget {
  final String? focusAttribute;

  const WorldMapScreen({super.key, this.focusAttribute});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  Timer? _navTimer;

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

    return Scaffold(
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text('Failed to load world state.', style: TextStyle(color: Colors.white70)),
            ],
          ),
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
                      onNodeTap: (attr) => context.go('/world-map/attribute/${attr.name}'),
                    ),
                  ),
                  Center(
                    child: CentralHealthOrb(
                      currentHealth: health * 100,
                      maxHealth: 100,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
