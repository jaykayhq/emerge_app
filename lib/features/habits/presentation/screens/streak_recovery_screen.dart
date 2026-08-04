import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';

/// A dedicated flow for when a user misses a habit to maintain their identity momentum.
/// Frames the return positively ("You're human. Never miss twice.")
/// Visually restores momentum.
class StreakRecoveryScreen extends ConsumerStatefulWidget {
  final Habit habit;
  final int xpEarned;

  const StreakRecoveryScreen({
    super.key,
    required this.habit,
    required this.xpEarned,
  });

  @override
  ConsumerState<StreakRecoveryScreen> createState() =>
      _StreakRecoveryScreenState();
}

class _StreakRecoveryScreenState extends ConsumerState<StreakRecoveryScreen> {
  bool _showMessage = false;
  final GlobalKey _momentumKey = GlobalKey();
  final GlobalKey _restartCtaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNarrator();
    });
  }

  Future<void> _showNarrator() async {
    // Wait a brief moment for the screen to settle.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // The first-visit guide covers the first visit — only show the
    // streak-break message once the guide has been seen.
    final guideDue = await ref
        .read(narratorGuideControllerProvider)
        .shouldShow('streak_recovery');
    if (guideDue || !mounted) return;

    setState(() => _showMessage = true);
  }

  @override
  Widget build(BuildContext context) {
    // NarratorGuideCard uses IconButton/InkWell, which need a Material
    // ancestor. The guide card sits beside the Scaffold in the host's Stack
    // (the Scaffold's own Material only covers its body), so provide a
    // transparent one here.
    return Material(
      type: MaterialType.transparency,
      child: NarratorGuideHost(
        nodeId: 'streak_recovery',
        targets: {
          'momentum_visual': _momentumKey,
          'restart_cta': _restartCtaKey,
        },
        child: Scaffold(
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
                          'You missed a day on "${widget.habit.title}", but you came back. '
                          'Identity isn\'t about perfection, it\'s about resilience.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 48),
                        KeyedSubtree(
                          key: _momentumKey,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.vitalityGreen.withValues(
                                  alpha: 0.3,
                                ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
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
                                      '${widget.xpEarned}',
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
                        ),
                        const SizedBox(height: 64),
                        KeyedSubtree(
                          key: _restartCtaKey,
                          child: SizedBox(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showMessage)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                  child: NarratorMilestoneCard(
                    line: const GenericLine(
                      'You missed a step. But you did not stop. That is what separates the dedicated from the dreamers.',
                    ),
                    trigger: NarratorTrigger.streakBreakFirstMiss,
                    onDismissed: () => setState(() => _showMessage = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
