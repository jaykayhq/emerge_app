import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/domain/services/blueprint_curation.dart';

Blueprint _blueprint({
  String category = 'General',
  String creatorArchetype = 'General',
  List<String> recommended = const [],
}) {
  return Blueprint(
    id: 'bp_1',
    creatorUserId: 'system',
    creatorName: 'Emerge Official',
    creatorArchetype: creatorArchetype,
    title: 'Test Blueprint',
    description: '',
    habits: const [],
    createdAt: DateTime(2025, 6, 1),
    category: category,
    recommendedArchetypes: recommended,
  );
}

void main() {
  group('categoryToArchetype', () {
    test('maps tribe categories to archetype ids', () {
      expect(categoryToArchetype['Fitness'], 'athlete');
      expect(categoryToArchetype['Mindfulness'], 'stoic');
      expect(categoryToArchetype['Learning'], 'scholar');
      expect(categoryToArchetype['Productivity'], 'zealot');
      expect(categoryToArchetype['Creativity'], 'creator');
      expect(categoryToArchetype['Faith'], 'zealot');
    });

    test('has no entry for unlisted categories', () {
      expect(categoryToArchetype['Morning'], isNull);
    });
  });

  group('archetypesFor', () {
    test('returns recommendedArchetypes when non-empty', () {
      final blueprint = _blueprint(
        category: 'Fitness',
        recommended: ['scholar', 'zealot'],
      );

      expect(archetypesFor(blueprint), ['scholar', 'zealot']);
    });

    test('falls back to the category mapping when empty', () {
      expect(archetypesFor(_blueprint(category: 'Fitness')), ['athlete']);
      expect(archetypesFor(_blueprint(category: 'Faith')), ['zealot']);
    });

    test('returns an empty list for unmapped categories', () {
      expect(archetypesFor(_blueprint(category: 'Morning')), isEmpty);
    });
  });

  group('matchesTribe', () {
    test('true when a curated archetype id matches', () {
      final blueprint = _blueprint(
        category: 'Morning',
        recommended: ['scholar', 'zealot'],
      );

      expect(matchesTribe(blueprint, 'scholar'), isTrue);
    });

    test('true when creatorArchetype matches the archetype id', () {
      expect(
        matchesTribe(_blueprint(creatorArchetype: 'Athlete'), 'athlete'),
        isTrue,
      );
    });

    test('false when neither curated nor creator archetype matches', () {
      expect(matchesTribe(_blueprint(category: 'Morning'), 'scholar'), isFalse);
    });

    test('false for an empty archetype id', () {
      expect(matchesTribe(_blueprint(recommended: ['scholar']), ''), isFalse);
    });
  });
}
