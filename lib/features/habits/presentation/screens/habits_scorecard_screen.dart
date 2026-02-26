import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

class HabitsScorecardScreen extends ConsumerWidget {
  const HabitsScorecardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits Scorecard')),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No habits yet. Add some!'));
          }
          // We need a local state for reordering if we want smooth UI,
          // but for now let's assume the provider updates fast enough or we just trigger an update.
          // Actually, ReorderableListView requires a list that can be mutated locally or we update the source.

          final sortedHabits = List<Habit>.from(habits)
            ..sort((a, b) => a.order.compareTo(b.order));

          return ReorderableListView.builder(
            itemCount: sortedHabits.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = sortedHabits.removeAt(oldIndex);
              sortedHabits.insert(newIndex, item);

              // Update order locally and save
              final repository = ref.read(habitRepositoryProvider);
              for (var i = 0; i < sortedHabits.length; i++) {
                final habit = sortedHabits[i].copyWith(order: i);
                repository.updateHabit(habit);
              }
            },
            itemBuilder: (context, index) {
              final habit = sortedHabits[index];
              return _ScorecardItem(key: ValueKey(habit.id), habit: habit);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ScorecardItem extends ConsumerWidget {
  final Habit habit;

  const _ScorecardItem({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color impactColor;
    IconData impactIcon;

    switch (habit.impact) {
      case HabitImpact.positive:
        impactColor = Colors.green;
        impactIcon = Icons.arrow_upward;
        break;
      case HabitImpact.negative:
        impactColor = Colors.red;
        impactIcon = Icons.arrow_downward;
        break;
      case HabitImpact.neutral:
        impactColor = Colors.grey;
        impactIcon = Icons.remove;
        break;
    }

    return ListTile(
      onTap: () => context.push('/timeline/detail/${habit.id}'),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: impactColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(impactIcon, color: impactColor),
      ),
      title: Text(
        habit.title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(habit.cue),
      trailing: PopupMenuButton<HabitImpact>(
        onSelected: (impact) {
          final updatedHabit = habit.copyWith(impact: impact);
          ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: HabitImpact.positive,
            child: Row(
              children: [
                Icon(Icons.arrow_upward, color: Colors.green),
                Gap(8),
                Text('Positive'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: HabitImpact.negative,
            child: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.red),
                Gap(8),
                Text('Negative'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: HabitImpact.neutral,
            child: Row(
              children: [
                Icon(Icons.remove, color: Colors.grey),
                Gap(8),
                Text('Neutral'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
