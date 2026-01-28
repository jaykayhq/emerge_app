import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// First habit creation screen during onboarding
/// Shows archetype-specific habit suggestions with anchor selection
class FirstHabitScreen extends ConsumerStatefulWidget {
  const FirstHabitScreen({super.key});

  @override
  ConsumerState<FirstHabitScreen> createState() => _FirstHabitScreenState();
}

class _FirstHabitScreenState extends ConsumerState<FirstHabitScreen> {
  ArchetypeHabitSuggestion? _selectedHabit;
  String? _selectedAnchor;

  final List<String> _anchorOptions = [
    'After waking up',
    'After morning coffee',
    'After breakfast',
    'After lunch',
    'After work',
    'After dinner',
    'Before bed',
  ];

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingStateProvider);
    final archetype = onboardingState.selectedArchetype ?? UserArchetype.none;
    final theme = ArchetypeTheme.forArchetype(archetype);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.backgroundGradient,
              ),
            ),
          ),

          // Hex mesh
          const Positioned.fill(child: HexMeshBackground()),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              width: index == 2 ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: index <= 2
                                    ? theme.primaryColor
                                    : Colors.white24,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Archetype badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                theme.journeyIcon,
                                color: theme.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                theme.archetypeName,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Your first\nidentity vote',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start small. One tiny habit to prove you\'re becoming ${theme.archetypeName}.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Habit suggestions
                        Text(
                          'PICK ONE',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...theme.suggestedHabits.map((habit) {
                          final isSelected = _selectedHabit == habit;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedHabit = habit;
                                  _selectedAnchor = habit.anchor;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primaryColor
                                        : Colors.white24,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? theme.primaryColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      child: Icon(
                                        habit.icon,
                                        color: theme.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            habit.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            habit.description,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.primaryColor,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (_selectedHabit != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'WHEN WILL YOU DO THIS?',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _anchorOptions.map((anchor) {
                              final isSelected = _selectedAnchor == anchor;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedAnchor = anchor),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.primaryColor
                                          : Colors.white24,
                                    ),
                                    color: isSelected
                                        ? theme.primaryColor.withValues(
                                            alpha: 0.2,
                                          )
                                        : Colors.transparent,
                                  ),
                                  child: Text(
                                    anchor,
                                    style: TextStyle(
                                      color: isSelected
                                          ? theme.primaryColor
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Implementation intention preview
                        if (_selectedHabit != null &&
                            _selectedAnchor != null) ...[
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: theme.primaryColor.withValues(alpha: 0.15),
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR IMPLEMENTATION INTENTION',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _selectedAnchor,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                      const TextSpan(text: ', I will '),
                                      TextSpan(
                                        text: _selectedHabit!.title
                                            .toLowerCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.backgroundGradient.last.withValues(alpha: 0.95),
                    theme.backgroundGradient.last,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedHabit != null && _selectedAnchor != null
                        ? _completeFirstHabit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Create My First Habit',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeFirstHabit() {
    if (_selectedHabit == null || _selectedAnchor == null) return;

    // Store habit info in onboarding state for creation after world reveal
    final state = ref.read(onboardingStateProvider);
    ref.read(onboardingStateProvider.notifier).state = state.copyWith(
      habitStacks: [
        HabitStack(
          anchorId: 'onboarding_anchor',
          habitId: _selectedHabit!.title,
        ),
      ],
      anchors: [_selectedAnchor!],
    );

    // Navigate to world reveal
    context.push('/onboarding/world-reveal');
  }
}
