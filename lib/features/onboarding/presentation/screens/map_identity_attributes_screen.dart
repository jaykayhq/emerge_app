import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MapIdentityAttributesScreen extends ConsumerStatefulWidget {
  const MapIdentityAttributesScreen({super.key});

  @override
  ConsumerState<MapIdentityAttributesScreen> createState() =>
      _MapIdentityAttributesScreenState();
}

class _MapIdentityAttributesScreenState
    extends ConsumerState<MapIdentityAttributesScreen> {
  void _incrementAttribute(String key) {
    final state = ref.read(onboardingStateProvider);
    if (state.remainingPoints > 0) {
      final currentPoints = state.attributes[key] ?? 0;
      ref.read(onboardingStateProvider.notifier).state = state.copyWith(
        attributes: {...state.attributes, key: currentPoints + 1},
        remainingPoints: state.remainingPoints - 1,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _decrementAttribute(String key) {
    final state = ref.read(onboardingStateProvider);
    final currentPoints = state.attributes[key] ?? 0;
    if (currentPoints > 0) {
      ref.read(onboardingStateProvider.notifier).state = state.copyWith(
        attributes: {...state.attributes, key: currentPoints - 1},
        remainingPoints: state.remainingPoints + 1,
      );
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A1A), // cosmicVoidDark
              Color(0xFF1A0A2A), // cosmicVoidCenter
              Color(0xFF2A1A3A), // cosmicMidPurple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Progress / Back Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        'STEP 3 OF 4',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(
                        'Shape Your Identity',
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const Gap(8),
                      Text(
                        'Allocate your starting points to shape the hero you aspire to become.',
                        style: GoogleFonts.splineSans(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms),

                      const Gap(24),

                      // Ethereal Orb Image
                      SizedBox(
                            height: 200,
                            width: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2BEE79,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 60,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/identity_orb.png',
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                          ),

                      const Gap(16),

                      // Points Remaining
                      Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Points to Allocate',
                                  style: GoogleFonts.splineSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  '${state.remainingPoints}',
                                  style: GoogleFonts.splineSans(
                                    color: const Color(0xFF2BEE79),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .moveY(begin: 10, end: 0),

                      const Gap(16),

                      // Attributes List
                      _buildAttributeRow(
                            'Vitality',
                            'For a life of energy and boundless health.',
                            Icons.favorite,
                            HabitAttribute.vitality,
                            state.attributes['Vitality'] ?? 0,
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .moveY(begin: 10, end: 0),

                      _buildAttributeRow(
                            'Focus',
                            'For a mind that is clear, present, and sharp.',
                            Icons.psychology,
                            HabitAttribute.focus,
                            state.attributes['Focus'] ?? 0,
                          )
                          .animate()
                          .fadeIn(delay: 450.ms)
                          .moveY(begin: 10, end: 0),

                      _buildAttributeRow(
                            'Creativity',
                            'For a spark of imagination and endless ideas.',
                            Icons.brush,
                            HabitAttribute.creativity,
                            state.attributes['Creativity'] ?? 0,
                          )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .moveY(begin: 10, end: 0),

                      _buildAttributeRow(
                            'Strength',
                            'For a body that is resilient and powerful.',
                            Icons.fitness_center,
                            HabitAttribute.strength,
                            state.attributes['Strength'] ?? 0,
                          )
                          .animate()
                          .fadeIn(delay: 550.ms)
                          .moveY(begin: 10, end: 0),

                      // ADDING SPIRITUALITY AS REQUESTED
                      _buildAttributeRow(
                        'Spirit',
                        'For a soul that is grounded, peaceful, and connected.',
                        Icons.spa,
                        HabitAttribute.spirit,
                        state.attributes['Spirit'] ?? 0,
                      ).animate().fadeIn(delay: 600.ms).moveY(begin: 10, end: 0),

                      _buildAttributeRow(
                        'Intellect',
                        'For a mind that seeks truth, logic, and deep wisdom.',
                        Icons.auto_stories,
                        HabitAttribute.intellect,
                        state.attributes['Intellect'] ?? 0,
                      ).animate().fadeIn(delay: 650.ms).moveY(begin: 10, end: 0),

                      const Gap(100), // Bottom padding
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.remainingPoints == 0
                        ? () {
                            // PERSIST PROGRESS: Complete the second milestone (Attributes)
                            ref
                                .read(onboardingControllerProvider.notifier)
                                .completeMilestone(1);

                            context.push('/onboarding/first-habit');
                          }
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'FORGE MY PATH',
                          style: GoogleFonts.splineSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ).animate().moveY(begin: 100, end: 0, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeRow(
    String title,
    String description,
    IconData icon,
    HabitAttribute attribute,
    int points,
  ) {
    final color = attributeColor(attribute);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.splineSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.splineSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          Row(
            children: [
              GestureDetector(
                onTap: () => _decrementAttribute(title),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$points',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.splineSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _incrementAttribute(title),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
