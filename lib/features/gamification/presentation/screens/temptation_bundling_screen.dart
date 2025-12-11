import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

class TemptationBundlingScreen extends ConsumerStatefulWidget {
  const TemptationBundlingScreen({super.key});

  @override
  ConsumerState<TemptationBundlingScreen> createState() =>
      _TemptationBundlingScreenState();
}

class _TemptationBundlingScreenState
    extends ConsumerState<TemptationBundlingScreen> {
  final _urlController = TextEditingController();
  String? _selectedHabitId;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    if (_urlController.text.isEmpty) return;
    final Uri url = Uri.parse(_urlController.text);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Temptation Bundling')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link a "Want" to a "Need"',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(8),
            Text(
              'Lock your reward (e.g., YouTube, Netflix) behind a habit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(32),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Reward URL',
                hintText: 'https://youtube.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const Gap(24),
            habitsAsync.when(
              data: (habits) {
                return InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Required Habit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHabitId,
                      isDense: true,
                      items: habits.map((habit) {
                        return DropdownMenuItem(
                          value: habit.id,
                          child: Text(habit.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedHabitId = value;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error loading habits: $err'),
            ),
            const Spacer(),
            Center(
              child: habitsAsync.when(
                data: (habits) {
                  final selectedHabit = habits.firstWhere(
                    (h) => h.id == _selectedHabitId,
                    orElse: () => Habit.empty(),
                  );

                  // Check if habit is completed today
                  final isCompleted =
                      selectedHabit.lastCompletedDate != null &&
                      DateUtils.isSameDay(
                        selectedHabit.lastCompletedDate,
                        DateTime.now(),
                      );

                  return FilledButton.icon(
                    onPressed: isCompleted ? _launchUrl : null,
                    icon: Icon(isCompleted ? Icons.lock_open : Icons.lock),
                    label: Text(
                      isCompleted ? 'Open Reward' : 'Complete Habit to Unlock',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: isCompleted ? Colors.green : Colors.grey,
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
