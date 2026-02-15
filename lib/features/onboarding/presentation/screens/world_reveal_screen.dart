import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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
    _textController.forward();
    _fadeController.forward();

    // Phase 2: Second message
    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() => _textPhase = 1);
    _textController.reset();
    _textController.forward();

    // Phase 3: Third message
    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() => _textPhase = 2);
    _textController.reset();
    _textController.forward();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Phase 4: Show button
    await Future.delayed(const Duration(milliseconds: 2000));
    setState(() => _showButton = true);
  }

  void _enterWorld() async {
    setState(() => _isCreatingHabits = true);
    HapticFeedback.heavyImpact();

    try {
      // Create onboarding habits
      await ref
          .read(onboardingControllerProvider.notifier)
          .createOnboardingHabits();

      // Complete onboarding
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();

      // Navigate to world with a fade transition (handled by router or page transition)
      if (mounted) {
        context.go('/');
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
    // Deepest black-green background #05100B
    return Scaffold(
      backgroundColor: const Color(0xFF05100B),
      body: Stack(
        children: [
          // Radial Gradient Background (Glow)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF102217), // Slightly lighter center
                    const Color(0xFF05100B), // Deepest dark edges
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
                    final scale = 1.0 + (_pulseController.value * 0.1);
                    final glowOpacity = 0.2 + (_pulseController.value * 0.3);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF2BEE79,
                          ).withValues(alpha: 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2BEE79,
                              ).withValues(alpha: glowOpacity),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFF2BEE79,
                              ).withValues(alpha: glowOpacity * 0.5),
                              blurRadius: 100,
                              spreadRadius: 30,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(
                              0xFF2BEE79,
                            ).withValues(alpha: glowOpacity),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2BEE79),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2BEE79,
                                  ).withValues(alpha: 0.8),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
    );
  }
}
