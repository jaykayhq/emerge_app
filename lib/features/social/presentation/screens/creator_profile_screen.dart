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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
