import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatorOverviewTab extends ConsumerWidget {
  const CreatorOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creator Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, Creator!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _AnalyticsCard(
            icon: Icons.widgets_rounded,
            title: 'Blueprints',
            subtitle: 'Manage your habit blueprints',
            onTap: () => context.push('/creator/dashboard/blueprints'),
          ),
          const SizedBox(height: 12),
          _AnalyticsCard(
            icon: Icons.groups_rounded,
            title: 'Tribe',
            subtitle: 'Manage your community',
            onTap: () => context.push('/creator/dashboard/tribe'),
          ),
          const SizedBox(height: 12),
          _AnalyticsCard(
            icon: Icons.analytics_rounded,
            title: 'Analytics',
            subtitle: 'Adoptions, growth, engagement',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
