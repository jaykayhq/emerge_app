import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/central_health_orb.dart';

class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final entropyAsync = ref.watch(worldEntropyStreamProvider);

    return Scaffold(
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
                  onNodeTap: (attr) => context.go('/attribute/${attr.name}'),
                ),
              ),
              Center(
                child: CentralHealthOrb(
                  currentHealth: health * 100,
                  maxHealth: 100,
                  onTap: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
