import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('toMap writes ownerId matching userId', () {
      const profile = CreatorProfile(
        userId: 'abc',
        role: 'creator',
        displayName: 'A',
      );
      final map = profile.toMap();
      expect(map['ownerId'], 'abc');
    });
  });

  group('CreatorRepository', () {
    test('updateCreatorProfileFields writes only the provided fields',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a full verified profile, exactly as redeemCreatorInvite does.
      await firestore.collection('creator_profiles').doc('uid_1').set({
        'userId': 'uid_1',
        'ownerId': 'uid_1',
        'role': 'creator',
        'displayName': 'Old Name',
        'isVerifiedCreator': true,
        'bio': 'old bio',
        'specialityTags': ['fitness'],
        'blueprintCount': 2,
        'creatorOnboardingProgress': 3,
      });

      final repo = CreatorRepository(firestore: firestore);
      await repo.updateCreatorProfileFields(
        'uid_1',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final snap = await firestore
          .collection('creator_profiles')
          .doc('uid_1')
          .get();
      final data = snap.data()!;
      expect(data['avatarUrl'], 'https://example.com/avatar.jpg');
      // Untouched fields — including privileged ones — survive the merge.
      expect(data['displayName'], 'Old Name');
      expect(data['ownerId'], 'uid_1');
      expect(data['role'], 'creator');
      expect(data['isVerifiedCreator'], true);
      expect(data['blueprintCount'], 2);
      expect(data['creatorOnboardingProgress'], 3);
    });

    test('updateCreatorProfileFields writes bio and tags', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('creator_profiles').doc('uid_1').set({
        'userId': 'uid_1',
        'ownerId': 'uid_1',
      });

      final repo = CreatorRepository(firestore: firestore);
      await repo.updateCreatorProfileFields(
        'uid_1',
        bio: 'New bio',
        specialityTags: ['meditation', 'calm'],
      );

      final snap = await firestore
          .collection('creator_profiles')
          .doc('uid_1')
          .get();
      expect(snap.data()?['bio'], 'New bio');
      expect(snap.data()?['specialityTags'], ['meditation', 'calm']);
      expect(snap.data()?['userId'], 'uid_1');
    });

    test('updateCreatorName updates all mirrors (creator_profiles, users, '
        'user_stats)', () async {
      final firestore = FakeFirebaseFirestore();
      // Creator signup only writes creator_profiles — users/user_stats may
      // not exist yet; the merge must create rather than fail.
      await firestore.collection('creator_profiles').doc('uid_1').set({
        'userId': 'uid_1',
        'ownerId': 'uid_1',
        'displayName': 'Old Name',
      });

      final repo = CreatorRepository(firestore: firestore);
      await repo.updateCreatorName('uid_1', 'New Name');

      final profile = await firestore
          .collection('creator_profiles')
          .doc('uid_1')
          .get();
      expect(profile.data()?['displayName'], 'New Name');

      final users = await firestore.collection('users').doc('uid_1').get();
      expect(users.exists, isTrue);
      expect(users.data()?['displayName'], 'New Name');

      final stats = await firestore
          .collection('user_stats')
          .doc('uid_1')
          .get();
      expect(stats.exists, isTrue);
      expect(stats.data()?['displayName'], 'New Name');
    });

    test('updateCreatorName preserves existing user_stats fields', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('creator_profiles').doc('uid_1').set({
        'userId': 'uid_1',
        'ownerId': 'uid_1',
      });
      await firestore.collection('user_stats').doc('uid_1').set({
        'userId': 'uid_1',
        'displayName': 'Old',
        'avatarStats': {'level': 7, 'streak': 3},
      });

      final repo = CreatorRepository(firestore: firestore);
      await repo.updateCreatorName('uid_1', 'Renamed');

      final stats = await firestore
          .collection('user_stats')
          .doc('uid_1')
          .get();
      expect(stats.data()?['displayName'], 'Renamed');
      expect(stats.data()?['avatarStats'], {'level': 7, 'streak': 3});
    });
  });
}
