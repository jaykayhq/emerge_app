import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cueController = TextEditingController();
  final _routineController = TextEditingController();
  final _rewardController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  HabitDifficulty _difficulty = HabitDifficulty.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _cueController.dispose();
    _routineController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final userAsync = ref.read(authStateChangesProvider);
    final userId = userAsync.value?.id;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newHabit = Habit(
        id: const Uuid().v4(),
        userId: userId,
        title: _titleController.text.trim(),
        cue: _cueController.text.trim(),
        routine: _routineController.text.trim(),
        reward: _rewardController.text.trim(),
        frequency: _frequency,
        difficulty: _difficulty,
        createdAt: DateTime.now(),
      );

      await ref.read(createHabitProvider(newHabit).future);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving habit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useBlueprint(String title, String cue, String routine, String reward) {
    _titleController.text = title;
    _cueController.text = cue;
    _routineController.text = routine;
    _rewardController.text = reward;
    _tabController.animateTo(0); // Switch to Custom tab
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blueprint loaded! Review and save.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('New Quest'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveHabit,
            child: const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Custom'),
            Tab(text: 'Blueprints'),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondaryDark,
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          // Custom Tab
          ResponsiveLayout(
            mobile: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildFormContent(theme),
            ),
            tablet: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: _buildFormContent(theme),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Blueprints Tab
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BlueprintCard(
                title: 'Morning Meditation',
                description: 'Start your day with clarity.',
                icon: Icons.self_improvement,
                onTap: () => _useBlueprint(
                  'Morning Meditation',
                  'After I wake up',
                  'I will meditate for 10 minutes',
                  'I will enjoy my morning coffee',
                ),
              ),
              const Gap(16),
              _BlueprintCard(
                title: 'Read 10 Pages',
                description: 'Build a reading habit.',
                icon: Icons.menu_book,
                onTap: () => _useBlueprint(
                  'Read 10 Pages',
                  'After I eat dinner',
                  'I will read 10 pages',
                  'I will check social media',
                ),
              ),
              const Gap(16),
              _BlueprintCard(
                title: 'Workout',
                description: 'Get moving.',
                icon: Icons.fitness_center,
                onTap: () => _useBlueprint(
                  'Workout',
                  'After I finish work',
                  'I will exercise for 30 minutes',
                  'I will take a relaxing shower',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity / Title
          Text(
            'What habit do you want to build?',
            style: theme.textTheme.titleMedium,
          ),
          const Gap(8),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g., Read 10 pages, Meditate',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const Gap(24),

          // The 4 Laws
          Text(
            'The 4 Laws of Behavior Change',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.deepSunriseOrange,
            ),
          ),
          const Gap(16),

          // Cue
          TextFormField(
            controller: _cueController,
            decoration: const InputDecoration(
              labelText: '1. Make it Obvious (Cue)',
              hintText: 'When X happens...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.visibility_outlined),
            ),
          ),
          const Gap(16),

          // Routine (Craving/Response)
          TextFormField(
            controller: _routineController,
            decoration: const InputDecoration(
              labelText: '2. Make it Easy (Routine)',
              hintText: 'I will do Y...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_run),
            ),
          ),
          const Gap(16),

          // Reward
          TextFormField(
            controller: _rewardController,
            decoration: const InputDecoration(
              labelText: '3. Make it Satisfying (Reward)',
              hintText: 'Then I will get Z...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.emoji_events_outlined),
            ),
          ),
          const Gap(24),

          // Frequency
          Text('Frequency', style: theme.textTheme.titleMedium),
          const Gap(8),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<HabitFrequency>(
                  segments: const [
                    ButtonSegment(
                      value: HabitFrequency.daily,
                      label: Text('Daily'),
                    ),
                    ButtonSegment(
                      value: HabitFrequency.weekly,
                      label: Text('Weekly'),
                    ),
                    ButtonSegment(
                      value: HabitFrequency.specificDays,
                      label: Text('Specific'),
                    ),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (Set<HabitFrequency> newSelection) {
                    setState(() {
                      _frequency = newSelection.first;
                    });
                  },
                ),
              );
            },
          ),
          const Gap(24),

          // Difficulty
          Text('Difficulty', style: theme.textTheme.titleMedium),
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<HabitDifficulty>(
              segments: const [
                ButtonSegment(value: HabitDifficulty.easy, label: Text('Easy')),
                ButtonSegment(
                  value: HabitDifficulty.medium,
                  label: Text('Medium'),
                ),
                ButtonSegment(value: HabitDifficulty.hard, label: Text('Hard')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (Set<HabitDifficulty> newSelection) {
                setState(() {
                  _difficulty = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _BlueprintCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
