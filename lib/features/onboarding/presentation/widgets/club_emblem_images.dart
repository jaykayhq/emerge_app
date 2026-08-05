/// Curated, bundled emblem images for club cards (Plan 5).
///
/// The Firestore `Tribe.imageUrl` is frequently empty for seeded/archetype
/// clubs, which left the club cards showing only a fallback icon. This helper
/// provides a themed bundled asset per archetype, plus a deterministic
/// generic pool for creator/custom clubs (keyed by club id so a given club
/// always shows the same image).
///
/// Assets were generated for the Emerge brand (cosmic purple + neon green,
/// stylized 2D game art) and live in `assets/images/clubs/`.
library;

/// True when [imageUrl] points at a bundled asset (render with `Image.asset`)
/// rather than a remote URL (render with `Image.network`).
bool isBundledEmblem(String? imageUrl) {
  return imageUrl?.startsWith('assets/') ?? false;
}

/// Themed emblem per archetype id (matches `UserArchetype` enum names).
const Map<String, String> _archetypeEmblems = {
  // Athlete — strength / movement
  'athlete': 'assets/images/clubs/emblem_athlete.webp',
  // Creator — art / making
  'creator': 'assets/images/clubs/emblem_creator.webp',
  // Scholar — books / study
  'scholar': 'assets/images/clubs/emblem_scholar.webp',
  // Stoic — calm mountains
  'stoic': 'assets/images/clubs/emblem_stoic.webp',
  // Zealot — forest / devotion
  'zealot': 'assets/images/clubs/emblem_zealot.webp',
};

/// Deterministic generic pool for clubs without a themed archetype
/// (e.g. creator clubs). Bundled assets, one distinct badge each.
const List<String> _genericEmblems = [
  'assets/images/clubs/emblem_generic_0.webp', // community/team
  'assets/images/clubs/emblem_generic_1.webp', // trophy / achievement
  'assets/images/clubs/emblem_generic_2.webp', // writing / creative
  'assets/images/clubs/emblem_generic_3.webp', // library / study
  'assets/images/clubs/emblem_generic_4.webp', // calm nature
  'assets/images/clubs/emblem_generic_5.webp', // meditation / lantern
];

/// Resolves an emblem image URL for a club card.
///
/// Preference order:
///   1. The club's own [existingImageUrl] (Firestore), when non-empty —
///      except legacy Unsplash stock links from earlier seeds, which are
///      replaced by the curated bundled emblems.
///   2. A themed emblem for [archetypeId], when it matches a known archetype.
///   3. A deterministic generic emblem chosen by [clubId] (stable per club).
String clubEmblemImageUrl({
  String? existingImageUrl,
  String? archetypeId,
  required String clubId,
}) {
  final existing = existingImageUrl?.trim() ?? '';
  if (existing.isNotEmpty &&
      !existing.startsWith('https://images.unsplash.com/')) {
    return existing;
  }

  final key = archetypeId?.trim().toLowerCase();
  final themed = key == null ? null : _archetypeEmblems[key];
  if (themed != null) return themed;

  // Deterministic pick from the generic pool so a club always looks the same.
  final hash = clubId.isEmpty ? 0 : clubId.codeUnits.fold<int>(0, (a, b) => a + b);
  return _genericEmblems[hash % _genericEmblems.length];
}
