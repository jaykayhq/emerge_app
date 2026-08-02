// Pure-function tests for the create-screen typeahead recommendation filter.
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_recommendations_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const templates = <HabitTemplate>[
    HabitTemplate(
      title: 'Kettlebell Swings',
      description: '50 swings',
      anchor: 'After arriving home',
      category: 'Strength',
      emoji: '💪',
      attribute: HabitAttribute.strength,
      timerDurationMinutes: 5,
    ),
    HabitTemplate(
      title: 'Meditation',
      description: '10 minutes',
      anchor: 'Before bed',
      category: 'Spirit',
      emoji: '🧘',
      attribute: HabitAttribute.spirit,
    ),
    HabitTemplate(
      title: 'Read for 10 minutes',
      description: '10 pages',
      anchor: 'Morning',
      category: 'Intellect',
      emoji: '📖',
      attribute: HabitAttribute.intellect,
    ),
  ];

  const suggestions = <String>['Drink water', 'Meditate', 'Walk'];

  group('filterHabitRecommendations', () {
    test('empty term returns curated suggestions first, then templates',
        () {
      final result = filterHabitRecommendations(
        term: '',
        templates: templates,
        suggestions: suggestions,
        limit: 10,
      );

      expect(result.map((r) => r.title).toList(), [
        'Drink water',
        'Meditate',
        'Walk',
        'Kettlebell Swings',
        'Meditation',
        'Read for 10 minutes',
      ]);
      // Suggestions carry no emoji; templates do.
      expect(result[0].emoji, isNull);
      expect(result[3].emoji, '💪');
    });

    test('prefix matches rank above substring matches', () {
      final result = filterHabitRecommendations(
        term: 'med',
        templates: templates,
        suggestions: suggestions,
        limit: 10,
      );

      // Emoji-rich template matches lead (they fill more fields), then plain
      // suggestions — both are prefix matches here.
      expect(result.first.title, 'Meditation');
      expect(result[1].title, 'Meditate');
      final titles = result.map((r) => r.title).toList();
      expect(titles, contains('Meditate'));
    });

    test('case-insensitive matching', () {
      final result = filterHabitRecommendations(
        term: 'KETTLE',
        templates: templates,
        suggestions: suggestions,
        limit: 10,
      );

      expect(result.first.title, 'Kettlebell Swings');
      expect(result.first.emoji, '💪');
      expect(result.first.attribute, HabitAttribute.strength);
      expect(result.first.timerMinutes, 5);
    });

    test('substring-only match is still returned', () {
      final result = filterHabitRecommendations(
        term: 'minutes',
        templates: templates,
        suggestions: suggestions,
        limit: 10,
      );

      expect(result.map((r) => r.title), contains('Read for 10 minutes'));
    });

    test('no match returns empty list', () {
      final result = filterHabitRecommendations(
        term: 'zzzz',
        templates: templates,
        suggestions: suggestions,
        limit: 10,
      );

      expect(result, isEmpty);
    });

    test('dedupes identical titles between suggestions and templates', () {
      final result = filterHabitRecommendations(
        term: '',
        templates: const [
          HabitTemplate(
            title: 'Drink water',
            description: '2L',
            anchor: 'After waking',
            category: 'Vitality',
            emoji: '💧',
          ),
        ],
        suggestions: suggestions,
        limit: 10,
      );

      final titles = result.map((r) => r.title).toList();
      expect(titles.where((t) => t == 'Drink water').length, 1);
    });

    test('respects the limit', () {
      final result = filterHabitRecommendations(
        term: '',
        templates: templates,
        suggestions: suggestions,
        limit: 2,
      );

      expect(result.length, 2);
    });
  });
}
