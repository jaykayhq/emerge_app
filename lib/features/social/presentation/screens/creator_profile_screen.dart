import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';

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
              // Display blueprints here
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
