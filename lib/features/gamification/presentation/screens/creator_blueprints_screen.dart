import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/data/repositories/blueprints_repository.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

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
      body: Column(
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
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Responsive logic could be added here
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final Blueprint blueprint;

  const _BlueprintCard({required this.blueprint});

  @override
  Widget build(BuildContext context) {
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
                  blueprint.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.image, color: AppTheme.primary),
                  ),
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
                                    color: AppTheme.primary,
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
                                onPressed: () {
                                  // Implement "Use Blueprint" logic
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Blueprint applied! Habits added to your routine.',
                                      ),
                                      backgroundColor: AppTheme.primary,
                                    ),
                                  );
                                  // In a real app, this would call a provider to add habits
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.backgroundDark,
                                ),
                                child: const Text('Use Blueprint'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
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
