import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/utils/app_toast.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/blueprints_repository.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:uuid/uuid.dart';

class CreatorBlueprintsScreen extends ConsumerStatefulWidget {
  const CreatorBlueprintsScreen({super.key});

  @override
  ConsumerState<CreatorBlueprintsScreen> createState() =>
      _CreatorBlueprintsScreenState();
}

class _CreatorBlueprintsScreenState
    extends ConsumerState<CreatorBlueprintsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(blueprintCategoriesProvider);
    final blueprintsAsync = ref.watch(blueprintsProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Creator Blueprints'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          Column(
            children: [
              // Categories
              SizedBox(
                height: 60,
                child: categoriesAsync.when(
                  data: (categories) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const Gap(8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category == _selectedCategory;
                        return Center(
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = category);
                              }
                            },
                            backgroundColor: AppTheme.surfaceDark,
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppTheme.textSecondaryDark.withValues(
                                        alpha: 0.2,
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ),
              const Gap(8),
              // Blueprints Grid
              Expanded(
                child: blueprintsAsync.when(
                  data: (blueprints) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                2, // Responsive logic could be added here
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: blueprints.length,
                      itemBuilder: (context, index) {
                        final blueprint = blueprints[index];
                        return _BlueprintCard(blueprint: blueprint)
                            .animate()
                            .fadeIn(delay: (100 * index).ms)
                            .scale(begin: const Offset(0.9, 0.9));
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlueprintCard extends ConsumerWidget {
  final Blueprint blueprint;

  const _BlueprintCard({required this.blueprint});

  Future<void> _useBlueprint(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) {
      AppToast.show(
        context,
        'You must be logged in to use a blueprint.',
        type: ToastType.error,
      );
      return;
    }

    // Close the dialog first
    Navigator.of(context).pop();

    try {
      final habits = blueprint.habits.map((blueprintHabit) {
        // Map frequency
        HabitFrequency frequency;
        List<int> specificDays = [];
        if (blueprintHabit.frequency == 'Daily') {
          frequency = HabitFrequency.daily;
        } else if (blueprintHabit.frequency == 'Weekdays') {
          frequency = HabitFrequency.specificDays;
          specificDays = [1, 2, 3, 4, 5];
        } else if (blueprintHabit.frequency == 'Weekly') {
          frequency = HabitFrequency.weekly;
        } else {
          frequency = HabitFrequency.daily; // Default
        }

        // Map TimeOfDay
        TimeOfDayPreference timePreference;
        switch (blueprintHabit.timeOfDay) {
          case 'Morning':
            timePreference = TimeOfDayPreference.morning;
            break;
          case 'Afternoon':
            timePreference = TimeOfDayPreference.afternoon;
            break;
          case 'Evening':
            timePreference = TimeOfDayPreference.evening;
            break;
          default:
            timePreference = TimeOfDayPreference.anytime;
        }

        return Habit(
          id: const Uuid().v4(),
          userId: user.id,
          title: blueprintHabit.title,
          frequency: frequency,
          specificDays: specificDays,
          timeOfDayPreference: timePreference,
          createdAt: DateTime.now(),
          imageUrl: blueprint.imageUrl, // Use blueprint image for habit or null
          identityTags: [blueprint.category],
          difficulty: _mapDifficulty(blueprint.difficulty),
        );
      }).toList();

      final repo = ref.read(habitRepositoryProvider);

      // Add all habits with error handling
      for (final habit in habits) {
        final result = await repo.createHabit(habit);
        result.fold(
          (failure) {
            if (context.mounted) {
              AppToast.show(
                context,
                'Failed to create habit: ${failure.message}',
                type: ToastType.error,
              );
            }
          },
          (_) {}, // Successfully created
        );
      }

      if (context.mounted) {
        AppToast.show(
          context,
          'Blueprint applied! ${habits.length} habits added.',
          type: ToastType.success,
        );
        context.go('/');
      }
    } catch (e, s) {
      if (context.mounted) {
        AppToast.show(
          context,
          'Failed to apply blueprint: $e',
          type: ToastType.error,
        );
        // Log the full error with stack trace
        AppLogger.e('Blueprint application error', e, s);
      }
    }
  }

  HabitDifficulty _mapDifficulty(BlueprintDifficulty difficulty) {
    switch (difficulty) {
      case BlueprintDifficulty.beginner:
        return HabitDifficulty.easy;
      case BlueprintDifficulty.intermediate:
        return HabitDifficulty.medium;
      case BlueprintDifficulty.advanced:
        return HabitDifficulty.hard;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondaryDark.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          SizedBox(
            height: 100, // Reduced from 120
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  blueprint.imageUrl.isNotEmpty
                      ? blueprint.imageUrl
                      : Blueprint.getDefaultImageForCategory(
                          blueprint.category,
                        ),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.surfaceDark,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          Blueprint.getDefaultImageForCategory(
                            blueprint.category,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: EmergeColors.teal.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.category_outlined,
                                  color: EmergeColors.teal,
                                ),
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppTheme.surfaceDark,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation(EmergeColors.teal),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${blueprint.habits.length} Habits',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blueprint.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Text(
                        blueprint.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 12,
                        ),
                        maxLines: 2, // Reduced from 3
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 36, // Fixed height for button
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceDark,
                            title: Text(
                              blueprint.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  blueprint.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  'Habits included:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: EmergeColors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(8),
                                ...blueprint.habits.map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const Gap(8),
                                        Expanded(
                                          child: Text(
                                            h.title,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () => _useBlueprint(context, ref),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EmergeColors.teal,
                                  foregroundColor: EmergeColors.background,
                                ),
                                child: const Text('Use Blueprint'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EmergeColors.teal.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: EmergeColors.teal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: EmergeColors.teal),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
