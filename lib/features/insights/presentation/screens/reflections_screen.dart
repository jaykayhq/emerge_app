import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ReflectionsScreen extends ConsumerWidget {
  const ReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflectionsAsync = ref.watch(reflectionsProvider);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Reflections'),
        backgroundColor: Colors.transparent,
      ),
      child: reflectionsAsync.when(
        data: (reflections) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reflections.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) {
            final reflection = reflections[index];
            return _ReflectionCard(
              date: reflection.date,
              title: reflection.title,
              content: reflection.content,
              icon: reflection.type == 'insight'
                  ? Icons.lightbulb
                  : Icons.analytics,
            ).animate().fadeIn(delay: (100 * index).ms).slideX();
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final String date;
  final String title;
  final String content;
  final IconData icon;

  const _ReflectionCard({
    required this.date,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const Gap(8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
