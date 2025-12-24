import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitStackingScreen extends ConsumerStatefulWidget {
  const HabitStackingScreen({super.key});

  @override
  ConsumerState<HabitStackingScreen> createState() =>
      _HabitStackingScreenState();
}

class _HabitStackingScreenState extends ConsumerState<HabitStackingScreen> {
  // Temporary state for the drag and drop UI
  // Map<AnchorId, NewHabitString>
  final Map<String, String> _stacks = {};

  // Get archetype-specific habit suggestions
  List<String> _getArchetypeHabits(UserArchetype? archetype) {
    if (archetype == null) return _getGenericHabits();

    switch (archetype) {
      case UserArchetype.athlete:
        return [
          'Stretch for 10 min',
          'Drink protein shake',
          'Track workout',
          'Foam roll',
          'Prep gym bag',
        ];
      case UserArchetype.creator:
        return [
          'Write 100 words',
          'Sketch one idea',
          'Review inspiration',
          'Organize workspace',
          'Practice 15 min',
        ];
      case UserArchetype.scholar:
        return [
          'Read 5 pages',
          'Review notes',
          'Learn new word',
          'Summarize learning',
          'Deep focus 25 min',
        ];
      case UserArchetype.stoic:
        return [
          'Meditate 5 min',
          'Practice gratitude',
          'Evening reflection',
          'Breathwork',
          'Journal emotions',
        ];
      default:
        return _getGenericHabits();
    }
  }

  List<String> _getGenericHabits() {
    return [
      "Read 5 pages",
      "Meditate 1 min",
      "Drink water",
      "Stretch",
      "Journal",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider).getOnboardingConfig();
    final suggestions = config.habitSuggestions;
    final selectedAnchors = ref.watch(onboardingStateProvider).anchors;
    final selectedArchetype = ref
        .watch(onboardingStateProvider)
        .selectedArchetype;

    // Get archetype-specific habits
    final newHabits = _getArchetypeHabits(selectedArchetype);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Step 5 of 5: Build Your Habit Chains',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 5 / 5, // Step 5 of 5 (complete)
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.vitalityGreen,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Save stacks to provider
              final habitStacks = _stacks.entries
                  .map((e) => HabitStack(anchorId: e.key, habitId: e.value))
                  .toList();

              ref
                  .read(onboardingStateProvider.notifier)
                  .update((state) => state.copyWith(habitStacks: habitStacks));

              // Create actual habits from the defined stacks
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .createOnboardingHabits();

              // Complete milestone 5 and save onboarding data
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .completeMilestone(4);

              // Mark onboarding as complete (so router allows dashboard access)
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .completeOnboarding();

              if (context.mounted) {
                context.go('/'); // Go to dashboard
              }
            },
            child: Text(
              'Done',
              style: GoogleFonts.splineSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: selectedAnchors.length,
              itemBuilder: (context, index) {
                final anchorId = selectedAnchors[index];
                final suggestion = suggestions.firstWhere(
                  (s) => s.id == anchorId,
                  orElse: () => suggestions.first,
                );
                final stackedHabit = _stacks[anchorId];

                return Column(
                  children: [
                    // Anchor Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getIconData(suggestion.icon),
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'After I ${suggestion.title}...',
                            style: GoogleFonts.splineSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Connector
                    Container(
                      height: 20,
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    // Drop Target
                    DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _stacks[anchorId] = details.data;
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: stackedHabit != null
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: stackedHabit != null
                                  ? AppTheme.primary
                                  : Colors.grey.withValues(alpha: 0.5),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: stackedHabit != null
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'I will $stackedHabit',
                                      style: GoogleFonts.splineSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _stacks.remove(anchorId);
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    'Drag a new habit here',
                                    style: GoogleFonts.splineSans(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
          // Draggable Habits Palette
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Quests',
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: newHabits.map((habit) {
                    return Draggable<String>(
                      data: habit,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            habit,
                            style: GoogleFonts.splineSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: Chip(
                          label: Text(habit),
                          backgroundColor: AppTheme.backgroundDark,
                          labelStyle: GoogleFonts.splineSans(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      child: Chip(
                        label: Text(habit),
                        backgroundColor: AppTheme.backgroundDark,
                        labelStyle: GoogleFonts.splineSans(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'oral_disease':
        return Icons.clean_hands;
      case 'shower':
        return Icons.shower;
      case 'checkroom':
        return Icons.checkroom;
      case 'pets':
        return Icons.pets;
      case 'mail':
        return Icons.mail;
      case 'coffee':
        return Icons.coffee;
      default:
        return Icons.circle;
    }
  }
}
