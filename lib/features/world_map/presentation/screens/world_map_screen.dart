import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_map_focus_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  Timer? _navTimer;

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(mapFocusEventProvider, (previous, next) {
      if (next != null) {
        _navTimer?.cancel();
        _navTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            context.go('/world-map/attribute/$next');
            ref.read(mapFocusEventProvider.notifier).setFocus(null);
          }
        });
      }
    });

    final focusAttribute = ref.watch(mapFocusEventProvider);

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
          return Stack(
            fit: StackFit.expand,
            children: [
              NebulaBackground(
                healthState: WorldHealthState.fromHealth(health),
                entropy: entropy,
                primaryColor: Theme.of(context).colorScheme.primary,
                accentColor: Theme.of(context).colorScheme.secondary,
              ),
              Center(
                child: WorldRingLayout(
                  radius: 140,
                  focusAttribute: focusAttribute,
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
      ),
    );
  }
}
