import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class HabitStackingSheet extends ConsumerStatefulWidget {
  const HabitStackingSheet({super.key});

  @override
  ConsumerState<HabitStackingSheet> createState() => _HabitStackingSheetState();
}

class _HabitStackingSheetState extends ConsumerState<HabitStackingSheet> {
  String? _selectedAnchorId;
  final _newHabitController = TextEditingController();

  @override
  void dispose() {
    _newHabitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Build a Habit Stack',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          Text(
            'Link a new habit to an existing one to make it stick.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(32),
          Text(
            'After I...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          habitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return const Text('No habits available to use as anchors.');
              }
              return InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select an Anchor Habit',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAnchorId,
                    isDense: true,
                    hint: const Text('Select an Anchor Habit'),
                    items: habits.map((habit) {
                      return DropdownMenuItem(
                        value: habit.id,
                        child: Text(habit.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnchorId = value;
                      });
                    },
                  ),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text('Error: $err'),
          ),
          const Gap(24),
          Text(
            'I will...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          TextField(
            controller: _newHabitController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter new habit (e.g., Meditate for 1 min)',
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedAnchorId != null &&
                      _newHabitController.text.isNotEmpty
                  ? () {
                      // Create the new habit linked to the anchor
                      final newHabit = Habit.empty().copyWith(
                        title: _newHabitController.text,
                        stackParentId: _selectedAnchorId,
                        createdAt: DateTime.now(),
                        // Default to daily for now
                        frequency: HabitFrequency.daily,
                      );

                      ref.read(createHabitProvider(newHabit));
                      context.pop();
                    }
                  : null,
              child: const Text('Create Stack'),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
