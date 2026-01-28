import 'dart:async';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cinematic world reveal screen - the dramatic transition from onboarding to world
class WorldRevealScreen extends ConsumerStatefulWidget {
  const WorldRevealScreen({super.key});

  @override
  ConsumerState<WorldRevealScreen> createState() => _WorldRevealScreenState();
}

class _WorldRevealScreenState extends ConsumerState<WorldRevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  int _textPhase = 0;
  bool _showButton = false;
  bool _isCreatingHabits = false;

  final List<String> _messages = [
    'Your world is being created...',
    'Planting the seeds of your identity...',
    'Every habit is a vote for who you\'re becoming.',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _startSequence();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingStateProvider);
    final archetype = onboardingState.selectedArchetype ?? UserArchetype.none;
    final theme = ArchetypeTheme.forArchetype(archetype);
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5 * _fadeAnimation.value,
                    colors: [
                      theme.primaryColor.withValues(
                        alpha: 0.3 * _fadeAnimation.value,
                      ),
                      theme.backgroundGradient.first.withValues(
                        alpha: _fadeAnimation.value * 0.8,
                      ),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Particle field / hex mesh
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.5,
                child: const HexMeshBackground(),
              );
            },
          ),

          // Central icon with pulse
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _textPhase >= 1 ? _pulseAnimation.value : 1.0,
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor.withValues(
                                alpha: 0.2 * _fadeAnimation.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.4 * _fadeAnimation.value,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              theme.journeyIcon,
                              size: 60,
                              color: theme.primaryColor.withValues(
                                alpha: _fadeAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Animated text
                AnimatedBuilder(
                  animation: _textFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _messages[_textPhase.clamp(0, _messages.length - 1)],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Journey name reveal
                AnimatedOpacity(
                  opacity: _textPhase >= 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [theme.primaryColor, theme.accentColor],
                        ).createShader(bounds),
                        child: Text(
                          theme.journeyName,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (user != null && user.displayName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            user.displayName!,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: theme.primaryColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
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
            child: AnimatedOpacity(
              opacity: _showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showButton && !_isCreatingHabits
                          ? _enterWorld
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isCreatingHabits
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Enter Your World',
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
          ),
        ],
      ),
    );
  }

  void _enterWorld() async {
    setState(() => _isCreatingHabits = true);

    try {
      // Create onboarding habits
      await ref
          .read(onboardingControllerProvider.notifier)
          .createOnboardingHabits();

      // Complete onboarding
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();

      // Navigate to world
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() => _isCreatingHabits = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
