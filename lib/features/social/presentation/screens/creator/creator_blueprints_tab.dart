import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';

class CreatorBlueprintsTab extends ConsumerWidget {
  const CreatorBlueprintsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprints Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Blueprint editor coming soon')),
              );
            },
            tooltip: 'Create new blueprint',
          ),
        ],
      ),
      body: blueprintsAsync.when(
        data: (blueprints) {
          if (blueprints.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.widgets, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No blueprints yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: blueprints.length,
            itemBuilder: (context, index) {
              final blueprint = blueprints[index];
              return BlueprintCard(blueprint: blueprint);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading blueprints: $e')),
      ),
    );
  }
}
