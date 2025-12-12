import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/habit_contract_repository.dart';
import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class HabitContractScreen extends ConsumerStatefulWidget {
  const HabitContractScreen({super.key});

  @override
  ConsumerState<HabitContractScreen> createState() =>
      _HabitContractScreenState();
}

class _HabitContractScreenState extends ConsumerState<HabitContractScreen> {
  String? _selectedHabitId;
  final _partnerEmailController = TextEditingController();
  final _penaltyController = TextEditingController();

  @override
  void dispose() {
    _partnerEmailController.dispose();
    _penaltyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the AsyncValue from subscription_provider.dart
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final habitsAsync = ref.watch(habitsProvider);

    // Default to false while loading or if null
    final isPremium = isPremiumAsync.valueOrNull ?? false;

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit Contract')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.amber),
              const Gap(16),
              Text(
                'Premium Feature',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Gap(8),
              const Text('Upgrade to create accountability contracts.'),
              const Gap(24),
              FilledButton(
                onPressed: () {
                  context.push('/paywall');
                },
                child: const Text('Upgrade Now'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Habit Contract')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make it Costly',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(8),
            const Text(
              'Add a social cost to missing your habit. Invite an accountability partner.',
            ),
            const Gap(32),
            habitsAsync.when(
              data: (habits) {
                return InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Habit',
                    border: OutlineInputBorder(),
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
              error: (err, _) => Text('Error: $err'),
            ),
            const Gap(16),
            TextField(
              controller: _partnerEmailController,
              decoration: const InputDecoration(
                labelText: 'Partner\'s Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const Gap(16),
            TextField(
              controller: _penaltyController,
              decoration: const InputDecoration(
                labelText: 'Penalty (if you miss)',
                hintText: 'e.g., I will pay you \$5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money_off),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selectedHabitId != null &&
                        _partnerEmailController.text.isNotEmpty &&
                        _penaltyController.text.isNotEmpty
                    ? () {
                        // Create contract logic
                        final user = ref.read(authStateChangesProvider).value;
                        final contract = HabitContract(
                          id: DateTime.now().millisecondsSinceEpoch
                              .toString(), // Simple ID generation
                          userId: user?.id ?? '',
                          habitId: _selectedHabitId!,
                          partnerEmail: _partnerEmailController.text,
                          penaltyAmount:
                              double.tryParse(
                                _penaltyController.text.replaceAll(
                                  RegExp(r'[^0-9.]'),
                                  '',
                                ),
                              ) ??
                              0.0,
                        );

                        ref
                            .read(habitContractRepositoryProvider)
                            .createContract(contract);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contract Sent!')),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Create Contract'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
