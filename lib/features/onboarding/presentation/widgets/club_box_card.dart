import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact box card for the onboarding club grid (Plan 5, Task 6).
///
/// Top ~60% is an emblem/gradient area; the bottom is a padded info area
/// with title, micro-info (member count + activity status) and a type-tag
/// pill ("ARCHETYPE" cyan / "CREATOR" purple).
class ClubBoxCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final int memberCount;
  final String activityStatus; // "🔥 Active" or "🌙 Quiet"
  final String typeTag; // "ARCHETYPE" or "CREATOR"
  final VoidCallback onTap;

  const ClubBoxCard({
    super.key,
    required this.title,
    required this.memberCount,
    required this.activityStatus,
    required this.typeTag,
    required this.onTap,
    this.imageUrl,
  });

  bool get _isArchetype => typeTag == 'ARCHETYPE';

  @override
  Widget build(BuildContext context) {
    final accent = _isArchetype ? Colors.cyanAccent : Colors.purpleAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emblem/image area (top ~60%).
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (imageUrl == null || imageUrl!.isEmpty)
                    ? Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 36,
                          color: accent,
                        ),
                      )
                    : null,
              ),
            ),
            // Info area.
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.splineSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$memberCount',
                          style: GoogleFonts.splineSans(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activityStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.splineSans(
                              color: activityStatus.contains('Active')
                                  ? Colors.greenAccent
                                  : Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isArchetype
                            ? Colors.cyanAccent.withValues(alpha: 0.2)
                            : Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeTag,
                        style: GoogleFonts.splineSans(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
