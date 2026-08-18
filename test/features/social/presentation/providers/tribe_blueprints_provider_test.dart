import 'dart:async';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribe_blueprints_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Blueprint _blueprint({
  required String id,
  String category = 'General',
  String creatorArchetype = 'Emerge',
  List<String> recommendedArchetypes = const [],
  String? creatorTribeId,
}) {
  return Blueprint(
    id: id,
    creatorUserId: 'system',
    creatorName: 'Emerge Official',
    creatorArchetype: creatorArchetype,
    title: id,
    description: '',
    habits: const [],
    createdAt: DateTime(2024, 1, 1),
    category: category,
    recommendedArchetypes: recommendedArchetypes,
    creatorTribeId: creatorTribeId,
  );
}

Future<void> _seedBlueprints(
  FakeFirebaseFirestore firestore,
  List<Blueprint> blueprints,
) async {
  for (final bp in blueprints) {
    await firestore.collection('blueprints').doc(bp.id).set(bp.toMap());
  }
}

ProviderContainer _makeContainer(BlueprintRepository repo) {
  return ProviderContainer(
    overrides: [blueprintRepositoryProvider.overrideWithValue(repo)],
  );
}

/// Reads the first emitted value of an autoDispose stream provider, keeping
/// it alive via a listen subscription (the repo's established harness pattern).
Future<List<Blueprint>> _firstEmission(
  ProviderContainer container,
  StreamProvider<List<Blueprint>> provider,
) async {
  final subscription = container.listen(provider, (_, _) {});
  final result = await container.read(provider.future);
  subscription.close();
  return result;
}

void main() {
  group('tribeBlueprintsProvider', () {
    test('emits curated matches plus creatorArchetype matches', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedBlueprints(firestore, [
        _blueprint(
          id: 'productivity_1',
          category: 'Productivity',
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _blueprint(id: 'cb_scholar', creatorArchetype: 'Scholar'),
        _blueprint(id: 'legacy_fitness_1', category: 'Fitness'),
      ]);

      final container = _makeContainer(BlueprintRepository(firestore));
      addTearDown(container.dispose);

      final blueprints = await _firstEmission(
        container,
        tribeBlueprintsProvider('scholar'),
      );

      final ids = blueprints.map((bp) => bp.id).toList();
      expect(ids, containsAll(['productivity_1', 'cb_scholar']));
      expect(ids, isNot(contains('legacy_fitness_1')));
    });

    test('legacy doc without the field matches via category', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedBlueprints(firestore, [
        _blueprint(id: 'legacy_fitness_1', category: 'Fitness'),
        _blueprint(
          id: 'productivity_1',
          category: 'Productivity',
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
      ]);

      final container = _makeContainer(BlueprintRepository(firestore));
      addTearDown(container.dispose);

      final blueprints = await _firstEmission(
        container,
        tribeBlueprintsProvider('athlete'),
      );

      final ids = blueprints.map((bp) => bp.id).toList();
      expect(ids, ['legacy_fitness_1']);
    });

    test('Morning-category doc without the field matches nothing', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedBlueprints(firestore, [
        _blueprint(id: 'morning_1', category: 'Morning'),
      ]);

      final container = _makeContainer(BlueprintRepository(firestore));
      addTearDown(container.dispose);

      final blueprints = await _firstEmission(
        container,
        tribeBlueprintsProvider('stoic'),
      );

      expect(blueprints, isEmpty);
    });
  });

  group('tribeCreatorBlueprintsProvider', () {
    test('emits only blueprints for the given creator tribe', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedBlueprints(firestore, [
        _blueprint(id: 'tribe_x_bp', creatorTribeId: 'tribe_x'),
        _blueprint(id: 'tribe_y_bp', creatorTribeId: 'tribe_y'),
        _blueprint(
          id: 'productivity_1',
          category: 'Productivity',
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
      ]);

      final container = _makeContainer(BlueprintRepository(firestore));
      addTearDown(container.dispose);

      final blueprints = await _firstEmission(
        container,
        tribeCreatorBlueprintsProvider('tribe_x'),
      );

      final ids = blueprints.map((bp) => bp.id).toList();
      expect(ids, ['tribe_x_bp']);
    });
  });

  group('tribeBlueprintsForActiveTribeProvider', () {
    test('curates by the resolved tribe archetype', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedBlueprints(firestore, [
        _blueprint(
          id: 'productivity_1',
          category: 'Productivity',
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _blueprint(id: 'cb_scholar', creatorArchetype: 'Scholar'),
        _blueprint(id: 'legacy_fitness_1', category: 'Fitness'),
      ]);

      final container = ProviderContainer(
        overrides: [
          blueprintRepositoryProvider.overrideWithValue(
            BlueprintRepository(firestore),
          ),
          activeMembershipProvider.overrideWith(
            (ref) => Stream.value(
              UserTribeTableData(
                userId: 'user_1',
                tribeId: 'tribe_arch',
                membershipType: 'official',
                joinedAt: '2024-01-01T00:00:00.000',
                isActive: true,
              ),
            ),
          ),
          allArchetypeClubsProvider.overrideWith(
            (ref) => Stream.value([
              Tribe(
                id: 'tribe_arch',
                name: 'Scholars',
                description: '',
                imageUrl: '',
                ownerId: '',
                tags: const [],
                levelRequirement: 0,
                rank: 0,
                totalXp: 0,
                memberCount: 0,
                archetypeId: 'scholar',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Pre-resolve the inner stream providers so their state is cached
      // before the outer provider first builds. Listen first: a bare
      // `container.read(x.future)` does not build an unbuilt provider.
      final membershipSub = container.listen(
        activeMembershipProvider,
        (_, _) {},
      );
      final clubsSub = container.listen(allArchetypeClubsProvider, (_, _) {});
      await container.read(activeMembershipProvider.future);
      await container.read(allArchetypeClubsProvider.future);

      final subscription = container.listen(
        tribeBlueprintsForActiveTribeProvider,
        (_, _) {},
      );
      final blueprints = await container.read(
        tribeBlueprintsForActiveTribeProvider.future,
      );
      subscription.close();
      membershipSub.close();
      clubsSub.close();

      final ids = blueprints.map((bp) => bp.id).toList();
      expect(ids, containsAll(['productivity_1', 'cb_scholar']));
      expect(ids, isNot(contains('legacy_fitness_1')));
    });

    test(
      'falls back to creator tribe blueprints when archetype is null',
      () async {
        final firestore = FakeFirebaseFirestore();
        await _seedBlueprints(firestore, [
          _blueprint(id: 'tribe_null_bp', creatorTribeId: 'tribe_null'),
          _blueprint(id: 'other_tribe_bp', creatorTribeId: 'tribe_other'),
          _blueprint(
            id: 'productivity_1',
            category: 'Productivity',
            recommendedArchetypes: const ['scholar', 'zealot'],
          ),
        ]);

        final container = ProviderContainer(
          overrides: [
            blueprintRepositoryProvider.overrideWithValue(
              BlueprintRepository(firestore),
            ),
            activeMembershipProvider.overrideWith(
              (ref) => Stream.value(
                UserTribeTableData(
                  userId: 'user_1',
                  tribeId: 'tribe_null',
                  membershipType: 'userPublic',
                  joinedAt: '2024-01-01T00:00:00.000',
                  isActive: true,
                ),
              ),
            ),
            allArchetypeClubsProvider.overrideWith(
              (ref) => Stream.value([
                Tribe(
                  id: 'tribe_null',
                  name: 'Creator Tribe',
                  description: '',
                  imageUrl: '',
                  ownerId: 'creator_1',
                  tags: const [],
                  levelRequirement: 0,
                  rank: 0,
                  totalXp: 0,
                  memberCount: 0,
                ),
              ]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final membershipSub = container.listen(
          activeMembershipProvider,
          (_, _) {},
        );
        final clubsSub = container.listen(allArchetypeClubsProvider, (_, _) {});
        await container.read(activeMembershipProvider.future);
        await container.read(allArchetypeClubsProvider.future);

        final subscription = container.listen(
          tribeBlueprintsForActiveTribeProvider,
          (_, _) {},
        );
        final blueprints = await container.read(
          tribeBlueprintsForActiveTribeProvider.future,
        );
        subscription.close();
        membershipSub.close();
        clubsSub.close();

        final ids = blueprints.map((bp) => bp.id).toList();
        expect(ids, ['tribe_null_bp']);
      },
    );
  });
}
