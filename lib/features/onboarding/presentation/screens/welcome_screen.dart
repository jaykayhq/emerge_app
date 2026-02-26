import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Welcome screen matching the Stitch design with cosmic silhouette background.
/// Features the downloaded welcome_silhouette.png image with the cosmic theme.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Cosmic void dark
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: The cosmic silhouette background (faded)
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/welcome_cosmic_silhouette.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found - show gradient
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0A0A1A),
                          Color(0xFF1A0A2A),
                          Color(0xFF0A0A1A),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Layer 2: Cosmic gradient overlay (matches app theme)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A1A).withValues(alpha: 0.3),
                    const Color(0xFF2A1A3A).withValues(alpha: 0.2),
                    const Color(0xFF0A0A1A).withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Layer 3: Content
          SafeArea(
            child: Column(
              children: [
                // Header with letter-spaced "E M E R G E"
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'E M E R G E',
                    style: GoogleFonts.splineSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: const Color(0xFFA9A9A9),
                    ),
                  ),
                ),

                // Main content area — centered vertically
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main Headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Who do you wish to become?',
                          style: GoogleFonts.splineSans(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF5F5F5),
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Forge Your Identity. Build Your Habits.',
                          style: GoogleFonts.splineSans(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFFA9A9A9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer with CTA Button (purple → blue gradient matches Stitch)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    bottom: 48.0,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E44AD).withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                      child: Text(
                        'Begin Your Journey',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
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
    );
  }
}
