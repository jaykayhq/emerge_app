import 'package:emerge_app/core/presentation/providers/social_preload_provider.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_state_notifier.dart';
import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class WorldRevealScreen extends ConsumerStatefulWidget {
  const WorldRevealScreen({super.key});

  @override
  ConsumerState<WorldRevealScreen> createState() => _WorldRevealScreenState();
}

class _WorldRevealScreenState extends ConsumerState<WorldRevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  int _textPhase = 0;
  bool _showButton = false;
  bool _isCreatingHabits = false;
  bool _skipped = false;

  final List<String> _messages = [
    'Your identity is forming...',
    'The world is listening...',
    'Emerge.',
  ];

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _startSequence();
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startSequence() async {
    // Phase 1: Fade in first message
    await Future.delayed(const Duration(milliseconds: 500));
    if (_skipped) return;
    _textController.forward();
    _fadeController.forward();

    // Phase 2: Second message
    await Future.delayed(const Duration(milliseconds: 2500));
    if (_skipped) return;
    setState(() => _textPhase = 1);
    _textController.reset();
    _textController.forward();

    // Phase 3: Third message
    await Future.delayed(const Duration(milliseconds: 2500));
    if (_skipped) return;
    setState(() => _textPhase = 2);
    _textController.reset();
    _textController.forward();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Phase 4: Show button
    await Future.delayed(const Duration(milliseconds: 2000));
    if (_skipped) return;
    setState(() => _showButton = true);

    // Preload ALL social data in background while user watches animations
    ref.read(socialDataPreloadProvider);
  }

  void _skipToEnterWorld() {
    if (_skipped) return;
    // Jump straight to the final "Enter Your World" state,
    // skipping the reveal animation sequence.
    setState(() {
      _skipped = true;
      _textPhase = 2;
      _textController.value = 1.0;
      _showButton = true;
    });
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    // Preload ALL social data in background.
    ref.read(socialDataPreloadProvider);
  }

  void _enterWorld() async {
    setState(() => _isCreatingHabits = true);
    HapticFeedback.heavyImpact();

    try {
      // Complete the fourth milestone (World Reveal) - Index 3
      await ref.read(enhancedOnboardingProvider.notifier).completeMilestone(3);

      // Complete onboarding via enhanced provider - creates habits from stacks
      await ref.read(enhancedOnboardingProvider.notifier).completeOnboarding();

      // Ensure legacy bool provider is updated for router
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();

      // Enable companion for first-time users after onboarding
      AppLogger.i('Companion enabled after onboarding completion');

      // Navigate to world with a fade transition (handled by router or page transition)
      if (mounted) {
        context.go('/timeline');
      }
    } catch (e) {
      setState(() => _isCreatingHabits = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating your world: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cosmic purple background
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
              AnimatedOnboardingProgressBar(
                targetProgress: 1.0,
                label: onboardingLabelFor(1.0),
                accentColor: (() {
                  final a = ref.watch(selectedArchetypeProvider);
                  return a != null && a != UserArchetype.none
                      ? ArchetypeColors.all[a.name]?.accent
                      : null;
                })(),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Radial Gradient Background (Glow)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: [
                              const Color(
                                0xFF2A1A3A,
                              ).withValues(alpha: 0.5), // Purple glow
                              const Color(
                                0xFF0A0A1A,
                              ).withValues(alpha: 0.8), // Dark edges
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Center Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // The Abstract Core/Seed
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale =
                                  1.0 + (_pulseController.value * 0.1);

                              return Transform.scale(
                                scale: scale,
                                child: const AnimatedFlameLogo(size: 120),
                              );
                            },
                          ),

                          const Gap(80),

                          // Text Messages
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              // Fade in and out for first two, stay for last?
                              // Actually, let's just fade IN for simplicity based on phase
                              double fadeVal = 0.0;
                              if (_textPhase < 2) {
                                // Fade in then out
                                fadeVal = _textController.value < 0.5
                                    ? _textController.value * 2
                                    : (1.0 - _textController.value) * 2;
                              } else {
                                // Final phase: Fade in and stay
                                fadeVal = _textController.value;
                              }

                              return Opacity(
                                opacity: fadeVal.clamp(0.0, 1.0),
                                child: Text(
                                  _messages[_textPhase],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.splineSans(
                                    color: _textPhase == 2
                                        ? const Color(0xFF2BEE79)
                                        : Colors.white,
                                    fontSize: 24,
                                    fontWeight: _textPhase == 2
                                        ? FontWeight.bold
                                        : FontWeight.w300,
                                    letterSpacing: _textPhase == 2 ? 4.0 : 1.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Top controls: back arrow (left) + skip (right)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              onPressed: () {
                                if (context.canPop()) context.pop();
                              },
                            ),
                            TextButton(
                              onPressed: _skipToEnterWorld,
                              child: Text(
                                'Skip',
                                style: GoogleFonts.splineSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Button
                    if (_showButton)
                      Positioned(
                        bottom: 80,
                        left: 40,
                        right: 40,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 1000),
                          opacity: _showButton ? 1.0 : 0.0,
                          child: SizedBox(
                            height: 56,
                            child: _isCreatingHabits
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2BEE79),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: _enterWorld,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF2BEE79),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      foregroundColor: const Color(0xFF2BEE79),
                                    ),
                                    child: Text(
                                      'ENTER YOUR WORLD',
                                      style: GoogleFonts.splineSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.0,
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
        ),
      ),
    );
  }
}
