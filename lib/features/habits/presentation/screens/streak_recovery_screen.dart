import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/core/theme/app_theme.dart';

/// A dedicated flow for when a user misses a habit to maintain their identity momentum.
/// Frames the return positively ("You're human. Never miss twice.")
/// Visually restores momentum.
class StreakRecoveryScreen extends ConsumerWidget {
  final Habit habit;
  final int xpEarned;

  const StreakRecoveryScreen({
    super.key,
    required this.habit,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background blur/particles
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.vitalityGreen.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    radius: 1.5,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 80,
                      color: AppTheme.vitalityGreen,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'You\'re human.\nNever miss twice.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You missed a day on "${habit.title}", but you came back. '
                      'Identity isn\'t about perfection, it\'s about resilience.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.vitalityGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'MOMENTUM RESTORED',
                            style: TextStyle(
                              color: AppTheme.vitalityGreen,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                '+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                '$xpEarned',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'XP',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.vitalityGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
