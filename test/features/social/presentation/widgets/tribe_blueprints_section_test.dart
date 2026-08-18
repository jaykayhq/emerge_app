import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_blueprints_section.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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

Tribe _tribe({String id = 'tribe_1', String? archetypeId}) {
  return Tribe(
    id: id,
    name: 'Test Tribe',
    description: '',
    imageUrl: '',
    ownerId: '',
    tags: const [],
    levelRequirement: 0,
    rank: 0,
    totalXp: 0,
    memberCount: 0,
    archetypeId: archetypeId,
  );
}

Widget _harness(Tribe tribe, BlueprintRepository repo) {
  return ProviderScope(
    overrides: [blueprintRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Scaffold(body: TribeBlueprintsSection(tribe: tribe)),
    ),
  );
}

/// Pumps until the firestore-backed stream has emitted its first value.
Future<void> _pumpStream(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('archetype tribe renders its curated blueprints', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _seedBlueprints(firestore, [
      _blueprint(
        id: 'bp_scholar',
        category: 'Productivity',
        recommendedArchetypes: const ['scholar', 'zealot'],
      ),
      _blueprint(id: 'bp_fitness', category: 'Fitness'),
    ]);

    await tester.pumpWidget(
      _harness(_tribe(archetypeId: 'scholar'), BlueprintRepository(firestore)),
    );
    await _pumpStream(tester);

    expect(find.byType(BlueprintCard), findsOneWidget);
    expect(find.text('bp_scholar'), findsOneWidget);
    expect(find.text('bp_fitness'), findsNothing);
  });

  testWidgets('header has no Discover link', (tester) async {
    final firestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      _harness(_tribe(archetypeId: 'scholar'), BlueprintRepository(firestore)),
    );
    await _pumpStream(tester);

    expect(find.text('Discover →'), findsNothing);
    expect(find.text('BLUEPRINTS'), findsOneWidget);
  });

  testWidgets('creator tribe renders its own published blueprints', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await _seedBlueprints(firestore, [
      _blueprint(id: 'tribe_x_bp', creatorTribeId: 'tribe_x'),
      _blueprint(id: 'tribe_y_bp', creatorTribeId: 'tribe_y'),
    ]);

    await tester.pumpWidget(
      _harness(
        _tribe(id: 'tribe_x', archetypeId: null),
        BlueprintRepository(firestore),
      ),
    );
    await _pumpStream(tester);

    expect(find.byType(BlueprintCard), findsOneWidget);
    expect(find.text('tribe_x_bp'), findsOneWidget);
    expect(find.text('tribe_y_bp'), findsNothing);
  });

  testWidgets('creator tribe with no pinned blueprints shows empty state', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await _seedBlueprints(firestore, [
      _blueprint(id: 'other_tribe_bp', creatorTribeId: 'tribe_y'),
    ]);

    await tester.pumpWidget(
      _harness(
        _tribe(id: 'tribe_x', archetypeId: null),
        BlueprintRepository(firestore),
      ),
    );
    await _pumpStream(tester);

    expect(find.text('No blueprints for this tribe yet.'), findsOneWidget);
  });

  testWidgets('empty curated list keeps the empty state text', (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _seedBlueprints(firestore, [
      _blueprint(id: 'morning_1', category: 'Morning'),
    ]);

    await tester.pumpWidget(
      _harness(_tribe(archetypeId: 'stoic'), BlueprintRepository(firestore)),
    );
    await _pumpStream(tester);

    expect(find.text('No blueprints for this tribe yet.'), findsOneWidget);
  });
}
