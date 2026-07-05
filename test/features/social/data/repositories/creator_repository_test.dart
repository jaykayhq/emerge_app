import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

void main() {
  group('CreatorProfile model', () {
    test('fromMap parses all fields correctly', () {
      final map = {
        'userId': 'test_uid_1',
        'bio': 'Fitness coach & nutrition expert',
        'specialityTags': ['fitness', 'nutrition'],
        'isVerifiedCreator': true,
        'blueprintId': 'bp_1',
        'tribeId': 'tribe_1',
      };

      final profile = CreatorProfile.fromMap(map);

      expect(profile.userId, 'test_uid_1');
      expect(profile.bio, 'Fitness coach & nutrition expert');
      expect(profile.specialityTags, ['fitness', 'nutrition']);
      expect(profile.isVerifiedCreator, true);
      expect(profile.blueprintId, 'bp_1');
      expect(profile.tribeId, 'tribe_1');
    });

    test('toMap and fromMap are symmetric', () {
      final profile = CreatorProfile(
        userId: 'test_uid_2',
        bio: 'Mindfulness teacher',
        specialityTags: ['meditation', 'mindfulness'],
        isVerifiedCreator: false,
      );

      final map = profile.toMap();
      final restored = CreatorProfile.fromMap(map);

      expect(restored.userId, profile.userId);
      expect(restored.bio, profile.bio);
      expect(restored.specialityTags, profile.specialityTags);
      expect(restored.isVerifiedCreator, profile.isVerifiedCreator);
    });
  });
}
