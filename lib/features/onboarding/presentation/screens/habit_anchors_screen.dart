import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitAnchorsScreen extends ConsumerStatefulWidget {
  const HabitAnchorsScreen({super.key});

  @override
  ConsumerState<HabitAnchorsScreen> createState() => _HabitAnchorsScreenState();
}

class _HabitAnchorsScreenState extends ConsumerState<HabitAnchorsScreen> {
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider).getOnboardingConfig();
    final suggestions = config.habitSuggestions;
    final selectedAnchors = ref.watch(onboardingStateProvider).anchors;

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
          'Step 4 of 5: Map Your Day\'s Anchors',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              // Skip this milestone and go to next
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .skipMilestone(3);
              if (context.mounted) {
                context.go('/'); // Return to timeline
              }
            },
            child: Text(
              'Skip for now',
              style: GoogleFonts.splineSans(
                color: AppTheme.slateBlue,
                fontSize: 14,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 4 / 5, // Step 4 of 5
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.vitalityGreen,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Timeline / Selected Anchors Area
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: selectedAnchors.isEmpty
                  ? Center(
                      child: Text(
                        'Select habits below to build your timeline.',
                        style: GoogleFonts.splineSans(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: selectedAnchors.length,
                      itemBuilder: (context, index) {
                        final anchorId = selectedAnchors[index];
                        final suggestion = suggestions.firstWhere(
                          (s) => s.id == anchorId,
                          orElse: () => suggestions.first, // Fallback
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: index == 0
                                        ? Colors.transparent
                                        : AppTheme.primary,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconData(suggestion.icon),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: index == selectedAnchors.length - 1
                                        ? Colors.transparent
                                        : AppTheme.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        suggestion.title,
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
                                          final newAnchors = List<String>.from(
                                            selectedAnchors,
                                          );
                                          newAnchors.removeAt(index);
                                          ref
                                              .read(
                                                onboardingStateProvider
                                                    .notifier,
                                              )
                                              .update(
                                                (state) => state.copyWith(
                                                  anchors: newAnchors,
                                                ),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Suggestions Bottom Sheet
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
                  'Suggested Anchors',
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
                  children: suggestions.map((suggestion) {
                    final isSelected = selectedAnchors.contains(suggestion.id);
                    return FilterChip(
                      label: Text(suggestion.title),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newAnchors = List<String>.from(selectedAnchors);
                        if (selected) {
                          newAnchors.add(suggestion.id);
                        } else {
                          newAnchors.remove(suggestion.id);
                        }
                        ref
                            .read(onboardingStateProvider.notifier)
                            .update(
                              (state) => state.copyWith(anchors: newAnchors),
                            );
                      },
                      backgroundColor: AppTheme.backgroundDark,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: GoogleFonts.splineSans(
                        color: isSelected ? AppTheme.primary : Colors.white,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: selectedAnchors.isNotEmpty
                        ? AppTheme.primary
                        : Colors.grey[800],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: selectedAnchors.isNotEmpty
                          ? () async {
                              // Complete milestone and go to next step
                              await ref
                                  .read(onboardingControllerProvider.notifier)
                                  .completeMilestone(3);
                              if (context.mounted) {
                                context.push(
                                  '/onboarding/stacking',
                                ); // Go to next step
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Text(
                          'Set My Foundation',
                          style: GoogleFonts.splineSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedAnchors.isNotEmpty
                                ? AppTheme.backgroundDark
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
        return Icons.clean_hands; // Closest to toothbrush
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
