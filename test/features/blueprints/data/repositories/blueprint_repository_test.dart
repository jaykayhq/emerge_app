import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// All 25 category-seed ids, verbatim from the design spec §4.1 table.
const _seedBlueprintIds = [
  'morning_1',
  'morning_2',
  'morning_3',
  'morning_4',
  'morning_5',
  'productivity_1',
  'productivity_2',
  'productivity_3',
  'productivity_4',
  'productivity_5',
  'fitness_1',
  'fitness_2',
  'fitness_3',
  'fitness_4',
  'fitness_5',
  'mindfulness_1',
  'mindfulness_2',
  'mindfulness_3',
  'mindfulness_4',
  'mindfulness_5',
  'learning_1',
  'learning_2',
  'learning_3',
  'learning_4',
  'learning_5',
];

/// All 6 creator-seed ids, verbatim from the design spec §4.2 table.
const _creatorSeedIds = [
  'cb_aria_deep_work',
  'cb_marcus_morning',
  'cb_sora_creative',
  'cb_julian_calm',
  'cb_naia_devotion',
  'cb_elias_studio',
];

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

    test('seedBlueprintsIfEmpty skips seeding when v3 data already exists',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v3 document: sentinel doc exists AND carries the field.
      await firestore
          .collection('blueprints')
          .doc('morning_1')
          .set({'title': 'Existing', 'recommendedArchetypes': ['athlete']});

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      // Only the pre-existing doc should be present.
      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['title'], 'Existing');
    });

    test(
        'seedBlueprintsIfEmpty backfills recommendedArchetypes without clobbering live data',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v2 document: sentinel doc exists WITHOUT the field.
      await firestore
          .collection('blueprints')
          .doc('morning_1')
          .set({'title': 'Existing', 'adoptionCount': 7});

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _seedBlueprintIds.length);
      final morning1 = snap.docs.firstWhere((d) => d.id == 'morning_1').data();
      expect(morning1['recommendedArchetypes'], isA<List>());
      expect(morning1['recommendedArchetypes'], isNotEmpty);
      expect(morning1['adoptionCount'], 7);
    });

    test(
        'seedBlueprintsIfEmpty writes non-empty recommendedArchetypes on every seed doc',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _seedBlueprintIds.length);
      for (final doc in snap.docs) {
        expect(
          doc.data()['recommendedArchetypes'],
          isA<List>(),
          reason: '${doc.id} should carry a recommendedArchetypes list',
        );
        expect(
          doc.data()['recommendedArchetypes'],
          isNotEmpty,
          reason: '${doc.id} should have a non-empty recommendedArchetypes '
              'list',
        );
      }
    });

    test(
        'seedCreatorBlueprintsIfEmpty writes recommendedArchetypes on all creator seeds',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      await repo.seedCreatorBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _creatorSeedIds.length);
      for (final doc in snap.docs) {
        expect(
          doc.data()['recommendedArchetypes'],
          isA<List>(),
          reason: '${doc.id} should carry a recommendedArchetypes list',
        );
        expect(
          doc.data()['recommendedArchetypes'],
          isNotEmpty,
          reason: '${doc.id} should have a non-empty recommendedArchetypes '
              'list',
        );
      }
    });
  });
}
