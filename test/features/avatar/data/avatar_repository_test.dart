import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:emerge_app/features/avatar/data/avatar_repository.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';

void main() {
  group('AvatarRepository', () {
    test('saveAndGetAvatar stores and retrieves avatar data', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = AvatarRepository(firestore: firestore);
      final avatar = AvatarData.defaultAvatar();

      await repo.saveAvatar('test_uid', avatar);

      final retrieved = await repo.getAvatar('test_uid');
      expect(retrieved, isNotNull);
      expect(retrieved!.archetype, 'hero');
      expect(retrieved.level, 1);
    });

    test('getAvatar returns null for missing user', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = AvatarRepository(firestore: firestore);

      final retrieved = await repo.getAvatar('nonexistent');
      expect(retrieved, isNull);
    });

    test('saveAndGetAvatar with custom data', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = AvatarRepository(firestore: firestore);
      final avatar = AvatarData.defaultAvatar().copyWith(level: 50);

      await repo.saveAvatar('test_uid', avatar);
      final retrieved = await repo.getAvatar('test_uid');
      expect(retrieved!.level, 50);
    });
  });
}
