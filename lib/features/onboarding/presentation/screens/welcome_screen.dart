import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';

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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Text(
                        'Who do you wish to become?',
                        style: GoogleFonts.splineSans(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Forge Your Identity. Build Your Habits.',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Bottom Interaction Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary CTA
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8E44AD).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google Continue
                      OutlinedButton.icon(
                        onPressed: () async {
                          final navigator = GoRouter.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final result = await ref
                              .read(authRepositoryProvider)
                              .signInWithGoogle();
                          result.fold(
                            (error) => messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            ),
                            (_) => navigator.go('/'),
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
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Legal Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://docs.google.com/document/d/e/2PACX-1vQX-5ydyuD3ZYp_-8b_2rVyyuKW9zF2NaMm1CBxxwE5s1LXASy1P7Plxf8axNGc_TFJw-OnZrULmjgP/pub',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              'Terms of Service',
                              style: GoogleFonts.splineSans(
                                fontSize: 11,
                                color: Colors.white54,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white54,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://docs.google.com/document/d/e/2PACX-1vRt5cCpFS7PLmh_nwhxq3ec9YtRWQZk7mrOqbVN7aThrclpjgYL3q5r-nAqlftQJVkOSWzxnG_FDfjo/pub',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.splineSans(
                                fontSize: 11,
                                color: Colors.white54,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          'By signing up, you agree to our Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
