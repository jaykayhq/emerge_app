import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlueprintRepository', () {
    test('incrementAdoptionCount increments field on an existing doc', () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a document so update() has something to act on.
      await firestore
          .collection('blueprints')
          .doc('test_blueprint_id')
          .set({'adoptionCount': 5});

      final repo = BlueprintRepository(firestore);
      await repo.incrementAdoptionCount('test_blueprint_id');

      final snap = await firestore
          .collection('blueprints')
          .doc('test_blueprint_id')
          .get();
      // FakeFirebaseFirestore resolves FieldValue.increment — value should be 6.
      expect(snap.data()?['adoptionCount'], 6);
    });

    test('createBlueprint writes document and returns its id', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      final blueprint = Blueprint(
        id: '',
        title: 'Test Blueprint',
        description: 'Description',
        category: 'Morning',
        creatorName: 'Tester',
        creatorUserId: 'user_1',
        creatorArchetype: 'Scholar',
        createdAt: DateTime.now(),
        habits: [const BlueprintHabit(title: 'Wake Up')],
      );

      final id = await repo.createBlueprint(blueprint);

      expect(id, isNotEmpty);
      final snap = await firestore.collection('blueprints').doc(id).get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['title'], 'Test Blueprint');
    });

    test('seedBlueprintsIfEmpty seeds default blueprints when collection is empty',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs, isNotEmpty);
    });

    test('seedBlueprintsIfEmpty skips seeding when collection already has data',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a document under the expected sentinel key.
      await firestore
          .collection('blueprints')
          .doc('morning_1')
          .set({'title': 'Existing'});

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      // Only the pre-existing doc should be present.
      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['title'], 'Existing');
    });
  });
}
