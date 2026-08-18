import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';

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
                    colors: [accent.withValues(alpha: 0.3), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? (isBundledEmblem(imageUrl)
                          ? Image.asset(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              // Bundled emblems never fail; fall back anyway.
                              errorBuilder: (context, error, stackTrace) =>
                                  _EmblemFallback(accent: accent),
                            )
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              // Graceful loading: show a subtle spinner over the
                              // gradient until the image is ready.
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        accent,
                                      ),
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              // Never show a broken image: fall back to the emblem
                              // icon on the gradient if the network image fails.
                              errorBuilder: (context, error, stackTrace) =>
                                  _EmblemFallback(accent: accent),
                            ))
                    : _EmblemFallback(accent: accent),
              ),
            ),
            // Info area.
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
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
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                          // Inside a FittedBox the child is measured with
                          // unbounded width, so no flex widgets are allowed
                          // here — FittedBox scales the row down as a whole.
                          Text(
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Emblem shown over the gradient when there is no image, the image is still
/// loading has failed, or the club has no picture — a trophy icon so the card
/// always looks intentional rather than broken.
class _EmblemFallback extends StatelessWidget {
  final Color accent;

  const _EmblemFallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(Icons.emoji_events, size: 36, color: accent));
  }
}
