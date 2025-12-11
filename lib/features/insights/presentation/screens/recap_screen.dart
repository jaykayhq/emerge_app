import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapAsync = ref.watch(latestRecapProvider);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Weekly Recap'),
        backgroundColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: recapAsync.when(
          data: (recap) => Column(
            children: [
              _buildSummaryCard(context, recap),
              const Gap(24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _StatBox(
                      label: 'Habits Completed',
                      value: '${recap.habitsCompleted}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatBox(
                      label: 'Perfect Days',
                      value: '${recap.perfectDays}',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                    _StatBox(
                      label: 'XP Gained',
                      value: '${recap.xpGained}',
                      icon: Icons.bolt,
                      color: Colors.blue,
                    ),
                    _StatBox(
                      label: 'Focus Time',
                      value: recap.focusTime,
                      icon: Icons.timer,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Recap recap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              recap.summary,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'This week you were ${(recap.consistencyChange * 100).toInt()}% more consistent than last week. Keep it up!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const Gap(8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
