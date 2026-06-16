import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';

class CreatorProfileScreen extends ConsumerWidget {
  final String creatorId;

  const CreatorProfileScreen({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(creatorProfileProvider(creatorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Creator Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              const SizedBox(height: 16),
              Text(profile.bio, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              const Text('Blueprints', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);
                  return blueprintsAsync.when(
                    data: (blueprints) {
                      final creatorBlueprints = blueprints.where((b) => b.creatorUserId == creatorId).toList();
                      if (creatorBlueprints.isEmpty) {
                        return const Text('No blueprints yet', style: TextStyle(color: Colors.grey));
                      }
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: creatorBlueprints.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final blueprint = creatorBlueprints[index];
                            return SizedBox(
                              width: 160,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.widgets_rounded, size: 32, color: Theme.of(context).colorScheme.primary),
                                      const Spacer(),
                                      Text(blueprint.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('${blueprint.habits.length} habits', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Text('Could not load blueprints', style: TextStyle(color: Colors.grey)),
                  );
                },
              ),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(child: CircleAvatar(radius: 50, backgroundColor: Colors.grey)),
            const SizedBox(height: 16),
            Container(height: 20, width: 200, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Container(height: 20, width: double.infinity, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Container(height: 24, width: 100, color: Colors.grey.withValues(alpha: 0.3)),
          ],
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(e.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(creatorProfileProvider(creatorId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
