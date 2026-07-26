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

    test('falls back to a themed archetype emblem when image is empty', () {
      final url = clubEmblemImageUrl(
        existingImageUrl: '',
        archetypeId: 'scholar',
        clubId: 'c1',
      );
      expect(url, contains('images.unsplash.com'));
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
      expect(a, contains('images.unsplash.com'));
    });

    test('never returns an empty string', () {
      final url = clubEmblemImageUrl(clubId: '');
      expect(url, isNotEmpty);
      expect(url, contains('images.unsplash.com'));
    });

    test('all emblem URLs are https direct-image links', () {
      for (final id in ['athlete', 'creator', 'scholar', 'stoic', 'zealot']) {
        final url = clubEmblemImageUrl(archetypeId: id, clubId: 'x');
        expect(url.startsWith('https://images.unsplash.com/'), isTrue,
            reason: '$id emblem should be an unsplash direct link');
      }
    });
  });
}
