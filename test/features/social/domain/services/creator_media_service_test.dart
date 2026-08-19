import 'package:emerge_app/features/social/domain/services/creator_media_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('creatorMediaStoragePath', () {
    test('avatar paths are namespaced under creator_media/{userId}/avatar', () {
      expect(
        creatorMediaStoragePath(
          'uid_1',
          CreatorMediaType.avatar,
          'avatar_123.jpg',
        ),
        'creator_media/uid_1/avatar/avatar_123.jpg',
      );
    });

    test('hero paths are namespaced under creator_media/{userId}/hero', () {
      expect(
        creatorMediaStoragePath(
          'uid_1',
          CreatorMediaType.hero,
          'hero_456.png',
        ),
        'creator_media/uid_1/hero/hero_456.png',
      );
    });

    test(
      'blueprint paths are namespaced under creator_media/{userId}/blueprints/{blueprintId}',
      () {
        expect(
          creatorMediaStoragePath(
            'uid_1',
            CreatorMediaType.blueprint,
            'cover_789.webp',
            blueprintId: 'bp_42',
          ),
          'creator_media/uid_1/blueprints/bp_42/cover_789.webp',
        );
      },
    );

    test('a null filename falls back to image.jpg', () {
      expect(
        creatorMediaStoragePath('uid_1', CreatorMediaType.avatar, null),
        'creator_media/uid_1/avatar/image.jpg',
      );
    });

    test('user ids are never interpolated into each other', () {
      // uid_1 must not be able to target uid_12's folder via path tricks.
      expect(
        creatorMediaStoragePath('uid_1', CreatorMediaType.avatar, 'x.jpg'),
        isNot(contains('uid_12')),
      );
    });
  });
}
