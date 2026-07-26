/// Curated, verified emblem images for club cards (Plan 5).
///
/// The Firestore `Tribe.imageUrl` is frequently empty for seeded/archetype
/// clubs, which left the club cards showing only a fallback icon. This helper
/// provides a themed Unsplash image per archetype, plus a deterministic
/// generic pool for creator/custom clubs (keyed by club id so a given club
/// always shows the same image).
///
/// All URLs were verified (HTTP 200, `image/jpeg`, valid JPEG magic bytes)
/// on 2026-07-26. They use Unsplash's images CDN with fixed photo IDs and a
/// width/quality/crop transform, so they are stable direct-image links
/// (not the unsplash.com/random redirect, which can change or rate-limit).
library;

/// Themed emblem per archetype id (matches `UserArchetype` enum names).
const Map<String, String> _archetypeEmblems = {
  // Athlete — strength / movement
  'athlete':
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80&fit=crop',
  // Creator — art / making
  'creator':
      'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400&q=80&fit=crop',
  // Scholar — books / study
  'scholar':
      'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=400&q=80&fit=crop',
  // Stoic — calm mountains
  'stoic':
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80&fit=crop',
  // Zealot — forest / devotion
  'zealot':
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&q=80&fit=crop',
};

/// Deterministic generic pool for clubs without a themed archetype
/// (e.g. creator clubs). Verified Unsplash direct-image links.
const List<String> _genericEmblems = [
  'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&q=80&fit=crop', // community/team
  'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=400&q=80&fit=crop', // sport
  'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=400&q=80&fit=crop', // writing/creative
  'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&q=80&fit=crop', // library
  'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400&q=80&fit=crop', // calm nature
  'https://images.unsplash.com/photo-1494972308805-463bc619d34e?w=400&q=80&fit=crop', // meditation
];

/// Resolves an emblem image URL for a club card.
///
/// Preference order:
///   1. The club's own [existingImageUrl] (Firestore), when non-empty.
///   2. A themed emblem for [archetypeId], when it matches a known archetype.
///   3. A deterministic generic emblem chosen by [clubId] (stable per club).
String clubEmblemImageUrl({
  String? existingImageUrl,
  String? archetypeId,
  required String clubId,
}) {
  if (existingImageUrl != null && existingImageUrl.trim().isNotEmpty) {
    return existingImageUrl.trim();
  }

  final key = archetypeId?.trim().toLowerCase();
  final themed = key == null ? null : _archetypeEmblems[key];
  if (themed != null) return themed;

  // Deterministic pick from the generic pool so a club always looks the same.
  final hash = clubId.isEmpty ? 0 : clubId.codeUnits.fold<int>(0, (a, b) => a + b);
  return _genericEmblems[hash % _genericEmblems.length];
}
