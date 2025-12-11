import 'package:emerge_app/core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingAttributesScreen extends ConsumerStatefulWidget {
  const OnboardingAttributesScreen({super.key});

  @override
  ConsumerState<OnboardingAttributesScreen> createState() =>
      _OnboardingAttributesScreenState();
}

class _OnboardingAttributesScreenState
    extends ConsumerState<OnboardingAttributesScreen> {
  // Initial points distribution
  final Map<String, int> _attributes = {
    'Vitality': 3,
    'Focus': 3,
    'Creativity': 2,
    'Strength': 2,
  };

  final int _maxPoints = 10;

  int get _currentTotal => _attributes.values.fold(0, (sum, val) => sum + val);
  int get _remainingPoints => _maxPoints - _currentTotal;

  void _updatePoints(String attribute, int delta) {
    final currentVal = _attributes[attribute]!;
    final newVal = currentVal + delta;

    if (newVal < 0) return; // Cannot be negative
    if (delta > 0 && _remainingPoints <= 0) return; // Cannot exceed max points

    setState(() {
      _attributes[attribute] = newVal;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Shape Your Identity',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Allocate your starting points to shape the hero you aspire to become.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.splineSans(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  const Gap(24),

                  // Visual Orb
                  Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.auto_awesome,
                            size: 80,
                            color: AppTheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 3.seconds, color: Colors.white24),

                  const Gap(24),

                  // Points Counter
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Points to Allocate',
                          style: GoogleFonts.splineSans(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_remainingPoints',
                          style: GoogleFonts.splineSans(
                            fontSize: 32,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(16),

                  // Attribute List
                  _buildAttributeRow(
                    'Vitality',
                    'For a life of energy and boundless health.',
                    Icons.favorite,
                    Colors.redAccent,
                  ),
                  const Gap(8),
                  _buildAttributeRow(
                    'Focus',
                    'For a mind that is clear, present, and sharp.',
                    Icons.psychology,
                    Colors.cyanAccent,
                  ),
                  const Gap(8),
                  _buildAttributeRow(
                    'Creativity',
                    'For a spark of imagination and endless ideas.',
                    Icons.brush,
                    Colors.purpleAccent,
                  ),
                  const Gap(8),
                  _buildAttributeRow(
                    'Strength',
                    'For a body that is resilient and powerful.',
                    Icons.fitness_center,
                    Colors.amberAccent,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.backgroundDark,
                  AppTheme.backgroundDark.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _remainingPoints == 0
                    ? () {
                        // Save attributes and proceed
                        // ref.read(onboardingControllerProvider.notifier).updateAttributes(_attributes);
                        context.push('/onboarding/anchors');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.backgroundDark,
                  shape: const StadiumBorder(),
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.3,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Forge My Path',
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(
    String label,
    String description,
    IconData icon,
    Color color,
  ) {
    final value = _attributes[label]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.splineSans(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildIconButton(Icons.remove, () => _updatePoints(label, -1)),
              SizedBox(
                width: 32,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildIconButton(Icons.add, () => _updatePoints(label, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
