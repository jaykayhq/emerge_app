import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';

class CompanionOverlay extends StatelessWidget {
  final CompanionMessage message;
  final PersonaConfig persona;
  final GlobalKey? targetKey;
  final VoidCallback onDismiss;
  final VoidCallback onSkip;

  const CompanionOverlay({
    super.key,
    required this.message,
    required this.persona,
    this.targetKey,
    required this.onDismiss,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: persona.accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: persona.accentColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    persona.name[0],
                                    style: TextStyle(
                                      color: persona.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Text(
                                persona.name,
                                style: GoogleFonts.splineSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          Text(
                            message.message,
                            style: GoogleFonts.splineSans(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          if (message.suggestions != null && message.suggestions!.isNotEmpty) ...[
                            const Gap(12),
                            ...message.suggestions!.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 14, color: persona.accentColor),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(s, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                  ),
                                ],
                              ),
                            )),
                          ],
                          const Gap(24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                                child: Text(
                                  'SKIP',
                                  style: GoogleFonts.splineSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: onDismiss,
                                style: TextButton.styleFrom(
                                  backgroundColor: persona.accentColor,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'GOT IT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
