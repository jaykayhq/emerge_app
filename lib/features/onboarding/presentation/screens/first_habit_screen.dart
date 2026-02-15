import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstHabitScreen extends ConsumerStatefulWidget {
  const FirstHabitScreen({super.key});

  @override
  ConsumerState<FirstHabitScreen> createState() => _FirstHabitScreenState();
}

class _FirstHabitScreenState extends ConsumerState<FirstHabitScreen> {
  ArchetypeHabitSuggestion? _selectedHabit;
  String? _selectedAnchor;

  // Custom Habit Logic
  final TextEditingController _customHabitTitleController =
      TextEditingController();
  bool _isCustomHabit = false;

  void _completeFirstHabit() {
    final habitTitle = _isCustomHabit
        ? _customHabitTitleController.text.trim()
        : _selectedHabit?.title;

    if ((habitTitle == null || habitTitle.isEmpty) || _selectedAnchor == null) {
      return;
    }

    // Store habit info in onboarding state
    final state = ref.read(onboardingStateProvider);
    ref.read(onboardingStateProvider.notifier).state = state.copyWith(
      habitStacks: [
        HabitStack(
          anchorId: 'onboarding_anchor', // Pseudo anchor ID for onboarding
          habitId: habitTitle, // Using title as ID for now/placeholder
          // In a real app, we'd create a proper HabitActivity object or ID here
        ),
      ],
      anchors: [_selectedAnchor!],
    );

    // Navigate to world reveal
    context.push('/onboarding/world-reveal');
  }

  @override
  void dispose() {
    _customHabitTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);
    final archetype = state.selectedArchetype ?? UserArchetype.athlete;
    final theme = ArchetypeTheme.forArchetype(archetype);

    return Scaffold(
      backgroundColor: const Color(0xFF102217),
      body: SafeArea(
        child: Column(
          children: [
            // Header Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'STEP 3 OF 3',
                      style: GoogleFonts.splineSans(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(12),
                    Text(
                      'Your First Identity Vote',
                      style: GoogleFonts.splineSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn().moveY(begin: 10, end: 0),

                    const Gap(8),
                    Text(
                      'Prove to yourself you are becoming ${theme.archetypeName}.',
                      style: GoogleFonts.splineSans(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const Gap(32),

                    // HABIT LIST
                    ...theme.suggestedHabits.map((habit) {
                      final isSelected =
                          _selectedHabit == habit && !_isCustomHabit;
                      return _buildHabitCard(
                        title: habit.title,
                        subtitle: habit.description,
                        icon: habit.icon,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedHabit = habit;
                            // Auto-select anchor if not set, or keep existing?
                            // Let's keep anchor separate to force a conscious choice
                            _isCustomHabit = false;
                            _customHabitTitleController.clear();
                          });
                          HapticFeedback.lightImpact();
                        },
                      );
                    }),

                    // CUSTOM HABIT CARD
                    AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _isCustomHabit
                            ? const Color(0xFF1A2C24)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCustomHabit
                              ? const Color(0xFF2BEE79)
                              : Colors.white10,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF2BEE79),
                                  size: 20,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: TextField(
                                  controller: _customHabitTitleController,
                                  style: GoogleFonts.splineSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: _isCustomHabit
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Create my own habit...',
                                    hintStyle: GoogleFonts.splineSans(
                                      color: Colors.white30,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _isCustomHabit = true;
                                      _selectedHabit = null;
                                    });
                                  },
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              if (_isCustomHabit)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2BEE79),
                                  size: 20,
                                ),
                            ],
                          ),
                          if (_isCustomHabit) ...[
                            const Gap(8),
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Text(
                                'What simple action will you take?',
                                style: GoogleFonts.splineSans(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const Gap(32),

                    // WHEN SECTION
                    if (_selectedHabit != null ||
                        (_isCustomHabit &&
                            _customHabitTitleController.text.isNotEmpty))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'When will you do this?',
                            style: GoogleFonts.splineSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(),
                          const Gap(16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildAnchorChip('After waking up'),
                              _buildAnchorChip('Before bed'),
                              _buildAnchorChip('After lunch'),
                              _buildAnchorChip('After work'),
                            ],
                          ).animate().fadeIn(delay: 100.ms),
                        ],
                      ),

                    const Gap(100), // Bottom padding
                  ],
                ),
              ),
            ),

            // Sticky Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF102217),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      ((_selectedHabit != null ||
                              (_isCustomHabit &&
                                  _customHabitTitleController
                                      .text
                                      .isNotEmpty)) &&
                          _selectedAnchor != null)
                      ? _completeFirstHabit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2BEE79),
                    foregroundColor: const Color(0xFF05100B),
                    disabledBackgroundColor: Colors.white10,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CREATE MY FIRST HABIT',
                    style: GoogleFonts.splineSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ).animate().moveY(begin: 100, end: 0, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A2C24)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF2BEE79) : Colors.white10,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2BEE79).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF2BEE79) : Colors.white70,
                  size: 20,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.splineSans(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: GoogleFonts.splineSans(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2BEE79),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).moveX(begin: 10, end: 0);
  }

  Widget _buildAnchorChip(String label) {
    final isSelected = _selectedAnchor == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAnchor = label);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2BEE79) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF2BEE79) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.splineSans(
            color: isSelected ? const Color(0xFF05100B) : Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
