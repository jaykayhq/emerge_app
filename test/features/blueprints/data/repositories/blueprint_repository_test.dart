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

    test('seedBlueprintsIfEmpty skips seeding when v6 data already exists',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v6 document: sentinel doc exists AND carries the
      // bundled-artwork imageUrl (v4 marker), seeded habit slots
      // (timeOfDay — v5), and recommended durations (v6) — the backfill
      // must not re-run.
      await firestore.collection('blueprints').doc('morning_1').set({
        'title': 'Existing',
        'imageUrl': 'assets/images/blueprints/morning_1.webp',
        'habits': [
          {
            'title': 'Wake Up at 6 AM',
            'timeOfDay': 'Morning',
            'attribute': 'vitality',
            'timerDurationMinutes': 1,
          },
        ],
      });

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      // Only the pre-existing doc should be present.
      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['title'], 'Existing');
    });

    test(
        'seedBlueprintsIfEmpty backfills recommended durations onto v5 docs',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v5 document: bundled artwork + timeOfDay slots but NO
      // timerDurationMinutes — the v6 backfill must run and rewrite habits.
      await firestore.collection('blueprints').doc('morning_1').set({
        'title': 'Existing',
        'imageUrl': 'assets/images/blueprints/morning_1.webp',
        'habits': [
          {
            'title': 'Wake Up at 6 AM',
            'timeOfDay': 'Morning',
            'attribute': 'vitality',
          },
        ],
      });

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, greaterThan(1),
          reason: 'v5 docs must be backfilled to v6 with durations');
      final seeded = await firestore
          .collection('blueprints')
          .doc('morning_1')
          .get();
      final habits = (seeded.data()?['habits'] as List<dynamic>).cast<Map>();
      expect(habits, isNotEmpty);
      for (final habit in habits) {
        expect(habit['timerDurationMinutes'], greaterThan(0),
            reason: 'every backfilled habit needs a recommended duration');
      }
    });

    test(
        'seedBlueprintsIfEmpty backfills v3 docs with bundled artwork without clobbering live data',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v3 document: sentinel doc exists with the old remote
      // imageUrl (Unsplash) — must be backfilled to the bundled asset.
      await firestore.collection('blueprints').doc('morning_1').set({
        'title': 'Existing',
        'adoptionCount': 7,
        'recommendedArchetypes': ['athlete'],
        'imageUrl': 'https://images.unsplash.com/photo-1?w=800',
      });

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _seedBlueprintIds.length);
      final morning1 = snap.docs.firstWhere((d) => d.id == 'morning_1').data();
      expect(morning1['imageUrl'], 'assets/images/blueprints/morning_1.webp');
      // Live data survives the merge.
      expect(morning1['adoptionCount'], 7);
      expect(morning1['recommendedArchetypes'], isA<List>());
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
        'seedBlueprintsIfEmpty writes timeOfDay and attribute on every seeded habit',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _seedBlueprintIds.length);
      for (final doc in snap.docs) {
        final habits =
            (doc.data()['habits'] as List).cast<Map<String, dynamic>>();
        expect(
          habits,
          isNotEmpty,
          reason: '${doc.id} should carry habits',
        );
        for (final habit in habits) {
          expect(
            habit['timeOfDay'],
            isNotNull,
            reason: '${doc.id} habit "${habit['title']}" should carry a '
                'timeOfDay',
          );
          expect(
            habit['attribute'],
            isNotNull,
            reason: '${doc.id} habit "${habit['title']}" should carry an '
                'attribute',
          );
        }
      }
    });

    test('seedBlueprintsIfEmpty writes slot metadata on morning_1 habits',
        () async {
      final firestore = FakeFirebaseFirestore();
      final repo = BlueprintRepository(firestore);

      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').doc('morning_1').get();
      final habits =
          (snap.data()?['habits'] as List).cast<Map<String, dynamic>>();
      final first = habits.first;
      expect(first['title'], 'Wake Up at 6 AM');
      expect(first['timeOfDay'], 'Morning');
      expect(first['attribute'], 'vitality');
      // BlueprintHabit.toMap serializes the clock time unpadded ('6:0').
      expect(first['defaultTime'], '6:0');
    });

    test(
        'seedBlueprintsIfEmpty backfills habit timeOfDay onto v4 docs without duplicating',
        () async {
      final firestore = FakeFirebaseFirestore();
      // Pre-seed a v4 document: bundled-artwork marker present, but the
      // habit slots (timeOfDay) are missing — the v5 backfill must fill
      // them while preserving live data and without creating duplicate docs.
      await firestore.collection('blueprints').doc('morning_1').set({
        'title': 'Existing',
        'adoptionCount': 7,
        'imageUrl': 'assets/images/blueprints/morning_1.webp',
        'habits': [
          {'title': 'Wake Up at 6 AM', 'attribute': 'vitality'},
        ],
      });

      final repo = BlueprintRepository(firestore);
      await repo.seedBlueprintsIfEmpty();

      final snap = await firestore.collection('blueprints').get();
      expect(snap.docs.length, _seedBlueprintIds.length);
      final morning1 = snap.docs.firstWhere((d) => d.id == 'morning_1').data();
      expect(morning1['imageUrl'], 'assets/images/blueprints/morning_1.webp');
      // Live data survives the merge.
      expect(morning1['adoptionCount'], 7);
      // The backfilled habits carry the new slot metadata.
      final habits =
          (morning1['habits'] as List).cast<Map<String, dynamic>>();
      expect(habits.first['title'], 'Wake Up at 6 AM');
      expect(habits.first['timeOfDay'], 'Morning');
    });
  });
}
