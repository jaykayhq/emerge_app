import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/onboarding/domain/models/interest.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StarterHabitBlueprint', () {
    test('constructor with all fields sets correctly', () {
      const blueprint = StarterHabitBlueprint(
        id: 'ath.warmup.10squats',
        title: '10 squats',
        shortCue: 'After breakfast',
        attribute: HabitAttribute.vitality,
        archetype: UserArchetype.athlete,
        interestCategories: [],
        clubTags: ['fitness'],
        sourceAttribution: 'Happytrainers 10-minute beginner',
      );

      expect(blueprint.id, 'ath.warmup.10squats');
      expect(blueprint.title, '10 squats');
      expect(blueprint.shortCue, 'After breakfast');
      expect(blueprint.attribute, HabitAttribute.vitality);
      expect(blueprint.archetype, UserArchetype.athlete);
      expect(blueprint.clubTags, ['fitness']);
    });
  });

  group('StarterHabitBlueprint catalog', () {
    test('has at least 4 blueprints per selectable archetype', () {
      const archetypesToCheck = [
        UserArchetype.athlete,
        UserArchetype.scholar,
        UserArchetype.creator,
        UserArchetype.stoic,
        UserArchetype.zealot,
      ];
      for (final archetype in archetypesToCheck) {
        final count = StarterHabitBlueprint.catalog
            .where((b) => b.archetype == archetype)
            .length;
        expect(count, greaterThanOrEqualTo(4),
            reason: '$archetype must have at least 4 starter blueprints');
      }
    });

    test('all blueprint ids are unique', () {
      final ids = StarterHabitBlueprint.catalog.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every blueprint has a non-empty title and shortCue', () {
      for (final b in StarterHabitBlueprint.catalog) {
        expect(b.title.trim().isNotEmpty, isTrue,
            reason: 'blueprint ${b.id} must have a title');
        expect(b.shortCue.trim().isNotEmpty, isTrue,
            reason: 'blueprint ${b.id} must have a shortCue');
      }
    });

    test('sourceAttribution is non-empty for every blueprint', () {
      for (final b in StarterHabitBlueprint.catalog) {
        expect(b.sourceAttribution.trim().isNotEmpty, isTrue,
            reason: 'blueprint ${b.id} must cite its source');
      }
    });

    test('every blueprint has at least one matching archetype in its id', () {
      for (final b in StarterHabitBlueprint.catalog) {
        final prefix = '${b.archetype.name}.';
        expect(b.id.startsWith(prefix), isTrue,
            reason: 'blueprint ${b.id} id must start with its archetype');
      }
    });
  });

  group('StarterHabitBlueprint.forPersonalization', () {
    test('returns empty only for UserArchetype.none', () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.none,
        interestIds: const [],
        clubTags: const [],
      );
      expect(result, isEmpty);
    });

    test('falls back to archetype-only blueprints when no signals supplied',
        () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.athlete,
        interestIds: const [],
        clubTags: const [],
        limit: 3,
      );
      expect(result, isNotEmpty);
      expect(result.every((b) => b.archetype == UserArchetype.athlete), isTrue);
    });

    test('returns at least one blueprint for a real archetype with signals',
        () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.athlete,
        interestIds: const ['movement.walking'],
        clubTags: const ['fitness'],
      );
      expect(result, isNotEmpty);
    });

    test('ranks interest-match blueprints before archetype-only blueprints',
        () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.scholar,
        interestIds: const ['learning.reading'],
        clubTags: const [],
        limit: 10,
      );
      expect(result, isNotEmpty);
      // The top-ranked result must serve the learning category
      // (which the 'learning.reading' interest belongs to).
      expect(
        result.first.interestCategories,
        contains(InterestCategory.learning),
      );
    });

    test('club tag overlap is treated as a tiebreaker', () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.athlete,
        interestIds: const [],
        clubTags: const ['morning'],
        limit: 5,
      );
      expect(result, isNotEmpty);
      // At least one of the top results should be tagged 'morning'.
      final topHasMorning = result.any((b) => b.clubTags.contains('morning'));
      expect(topHasMorning, isTrue);
    });

    test('limit is respected', () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.creator,
        interestIds: const [
          'creativity.writing',
          'creativity.art',
          'creativity.music',
        ],
        clubTags: const ['reading'],
        limit: 3,
      );
      expect(result.length, lessThanOrEqualTo(3));
    });

    test('result is deterministic for the same inputs', () {
      final first = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.stoic,
        interestIds: const ['mindfulness.journaling'],
        clubTags: const ['reading'],
      );
      final second = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.stoic,
        interestIds: const ['mindfulness.journaling'],
        clubTags: const ['reading'],
      );
      expect(first.map((b) => b.id), second.map((b) => b.id));
    });

    test('unknown interest ids do not crash and are ignored', () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.athlete,
        interestIds: const ['nope.nothing'],
        clubTags: const [],
      );
      // Still returns the archetype fallback list.
      expect(result, isNotEmpty);
    });

    test('cross-archetype blueprints are excluded from someone else\u0027s pack',
        () {
      final result = StarterHabitBlueprint.forPersonalization(
        archetype: UserArchetype.athlete,
        interestIds: const ['faith.prayer'],
        clubTags: const [],
      );
      final hasNonAthlete = result.any(
        (b) => b.archetype != UserArchetype.athlete,
      );
      expect(hasNonAthlete, isFalse,
          reason: 'athlete pack must not contain zealot-only blueprints');
    });
  });
}

/// Local probes so tests can refer to interest-category equivalence
/// without leaking helper enums into production code.
class InterestMatchProbe {
  static const reading = InterestCategory.learning;
}
