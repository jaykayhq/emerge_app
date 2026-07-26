import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom-sheet content shown when a [ClubBoxCard] is tapped during
/// onboarding (Plan 5, Task 6): grabber, title, description, a benefits
/// checklist and a full-width "JOIN CLUB" button.
class ClubPreviewSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<String> benefits;
  final VoidCallback onJoin;

  const ClubPreviewSheet({
    super.key,
    required this.title,
    required this.description,
    required this.benefits,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(20),
          Text(
            title,
            style: GoogleFonts.splineSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(12),
          if (description.isNotEmpty)
            Text(
              description,
              style: GoogleFonts.splineSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          const Gap(16),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.splineSans(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                onJoin();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'JOIN CLUB',
                style: GoogleFonts.splineSans(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
