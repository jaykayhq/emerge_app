import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CreatorTribeManagementTab extends ConsumerWidget {
  const CreatorTribeManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribesAsync = ref.watch(allArchetypeClubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tribe Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcements coming soon')),
              );
            },
            tooltip: 'Post announcement',
          ),
        ],
      ),
      body: tribesAsync.when(
        data: (tribes) {
          if (tribes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tribes to manage', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tribes.length,
            itemBuilder: (context, index) {
              final tribe = tribes[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(tribe.name.isNotEmpty ? tribe.name[0].toUpperCase() : '?')),
                  title: Text(tribe.name),
                  subtitle: Text('${tribe.memberCount} members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${tribe.name} management coming soon')),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading tribes: $e')),
      ),
    );
  }
}
