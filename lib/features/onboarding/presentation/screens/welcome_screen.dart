import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

/// Welcome screen matching the Stitch design with cosmic silhouette background.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background components...
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/welcome_cosmic_silhouette.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'E M E R G E',
                  style: GoogleFonts.splineSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Who do you wish to become?',
                    style: GoogleFonts.splineSans(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Forge Your Identity. Build Your Habits.',
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Expanded(child: SizedBox()),

                // Primary CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.push('/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Begin Your Journey',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google Continue
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await ref
                              .read(authRepositoryProvider)
                              .signInWithGoogle();
                          result.fold(
                            (error) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                ),
                            (_) => context.go('/'),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        icon: const FaIcon(
                          FontAwesomeIcons.google,
                          color: EmergeColors.teal,
                          size: 20,
                        ),
                        label: const Text('Continue with Google'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
