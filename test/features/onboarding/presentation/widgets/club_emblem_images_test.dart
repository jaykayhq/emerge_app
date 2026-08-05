import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clubEmblemImageUrl', () {
    test('prefers a non-empty existing image URL', () {
      final url = clubEmblemImageUrl(
        existingImageUrl: 'https://example.com/custom.jpg',
        archetypeId: 'athlete',
        clubId: 'c1',
      );
      expect(url, 'https://example.com/custom.jpg');
    });

    test('keeps real custom image URLs over the themed emblem', () {
      final url = clubEmblemImageUrl(
        existingImageUrl: 'https://cdn.example.com/upload.png',
        archetypeId: 'athlete',
        clubId: 'c1',
      );
      expect(url, 'https://cdn.example.com/upload.png');
    });

    test('replaces legacy unsplash images with the bundled themed emblem', () {
      final url = clubEmblemImageUrl(
        existingImageUrl: 'https://images.unsplash.com/photo-123?w=800',
        archetypeId: 'athlete',
        clubId: 'c1',
      );
      expect(url, 'assets/images/clubs/emblem_athlete.webp');
    });

    test('falls back to a themed archetype emblem when image is empty', () {
      final url = clubEmblemImageUrl(
        existingImageUrl: '',
        archetypeId: 'scholar',
        clubId: 'c1',
      );
      expect(url, startsWith('assets/images/clubs/'));
    });

    test('archetype match is case-insensitive', () {
      final lower = clubEmblemImageUrl(archetypeId: 'stoic', clubId: 'c1');
      final upper = clubEmblemImageUrl(archetypeId: 'STOIC', clubId: 'c1');
      expect(lower, upper);
    });

    test('uses a deterministic generic emblem for unknown archetype', () {
      final a = clubEmblemImageUrl(archetypeId: null, clubId: 'club-abc');
      final b = clubEmblemImageUrl(archetypeId: null, clubId: 'club-abc');
      expect(a, b); // same club id -> same image every time
      expect(a, startsWith('assets/images/clubs/'));
    });

    test('never returns an empty string', () {
      final url = clubEmblemImageUrl(clubId: '');
      expect(url, isNotEmpty);
      expect(url, startsWith('assets/images/clubs/'));
    });

    test('all archetype emblems resolve to bundled assets', () {
      for (final id in ['athlete', 'creator', 'scholar', 'stoic', 'zealot']) {
        final url = clubEmblemImageUrl(archetypeId: id, clubId: 'x');
        expect(url.startsWith('assets/images/clubs/'), isTrue,
            reason: '$id emblem should be a bundled asset');
      }
    });
  });
}
