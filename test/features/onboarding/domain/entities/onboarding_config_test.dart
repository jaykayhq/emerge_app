import 'package:emerge_app/features/onboarding/domain/entities/onboarding_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchetypeConfig', () {
    const testArchetype = ArchetypeConfig(
      id: 'athlete',
      title: 'Athlete',
      description: 'You are driven by physical excellence.',
      imageUrl: 'https://example.com/athlete.png',
    );

    test('constructor sets all fields', () {
      expect(testArchetype.id, 'athlete');
      expect(testArchetype.title, 'Athlete');
      expect(testArchetype.description, 'You are driven by physical excellence.');
      expect(testArchetype.imageUrl, 'https://example.com/athlete.png');
    });

    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 'scholar',
        'title': 'Scholar',
        'description': 'You love learning.',
        'imageUrl': 'https://example.com/scholar.png',
      };
      final parsed = ArchetypeConfig.fromJson(json);

      expect(parsed.id, 'scholar');
      expect(parsed.title, 'Scholar');
      expect(parsed.description, 'You love learning.');
      expect(parsed.imageUrl, 'https://example.com/scholar.png');
    });

    test('Equatable equality', () {
      final a = ArchetypeConfig(
        id: 'stoic',
        title: 'Stoic',
        description: 'Desc',
        imageUrl: 'url',
      );
      final b = ArchetypeConfig(
        id: 'stoic',
        title: 'Stoic',
        description: 'Desc',
        imageUrl: 'url',
      );
      final c = ArchetypeConfig(
        id: 'athlete',
        title: 'Athlete',
        description: 'Desc',
        imageUrl: 'url',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AttributeConfig', () {
    const testAttribute = AttributeConfig(
      id: 'strength',
      title: 'Strength',
      description: 'Physical power and endurance.',
      icon: 'fitness_center',
      color: '#FF5733',
    );

    test('constructor sets all fields', () {
      expect(testAttribute.id, 'strength');
      expect(testAttribute.title, 'Strength');
      expect(testAttribute.description, 'Physical power and endurance.');
      expect(testAttribute.icon, 'fitness_center');
      expect(testAttribute.color, '#FF5733');
    });

    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 'intellect',
        'title': 'Intellect',
        'description': 'Mental sharpness.',
        'icon': 'menu_book',
        'color': '#3357FF',
      };
      final parsed = AttributeConfig.fromJson(json);

      expect(parsed.id, 'intellect');
      expect(parsed.title, 'Intellect');
      expect(parsed.icon, 'menu_book');
      expect(parsed.color, '#3357FF');
    });

    test('Equatable equality', () {
      final a = AttributeConfig(
        id: 'focus',
        title: 'Focus',
        description: 'Desc',
        icon: 'icon',
        color: '#000',
      );
      final b = AttributeConfig(
        id: 'focus',
        title: 'Focus',
        description: 'Desc',
        icon: 'icon',
        color: '#000',
      );
      final c = AttributeConfig(
        id: 'spirit',
        title: 'Spirit',
        description: 'Desc',
        icon: 'icon',
        color: '#000',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('HabitSuggestion', () {
    const testSuggestion = HabitSuggestion(
      id: 'morning_run',
      title: 'Morning Run',
      icon: 'directions_run',
    );

    test('constructor sets all fields', () {
      expect(testSuggestion.id, 'morning_run');
      expect(testSuggestion.title, 'Morning Run');
      expect(testSuggestion.icon, 'directions_run');
    });

    test('fromJson parses correctly', () {
      final json = <String, dynamic>{
        'id': 'meditate',
        'title': 'Meditate',
        'icon': 'self_improvement',
      };
      final parsed = HabitSuggestion.fromJson(json);

      expect(parsed.id, 'meditate');
      expect(parsed.title, 'Meditate');
      expect(parsed.icon, 'self_improvement');
    });

    test('Equatable equality', () {
      final a = HabitSuggestion(id: 'read', title: 'Read', icon: 'book');
      final b = HabitSuggestion(id: 'read', title: 'Read', icon: 'book');
      final c = HabitSuggestion(id: 'write', title: 'Write', icon: 'edit');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('OnboardingConfig', () {
    final archetypes = [
      const ArchetypeConfig(
        id: 'athlete',
        title: 'Athlete',
        description: 'Desc',
        imageUrl: 'url',
      ),
    ];
    final attributes = [
      const AttributeConfig(
        id: 'strength',
        title: 'Strength',
        description: 'Desc',
        icon: 'icon',
        color: '#000',
      ),
    ];
    final suggestions = [
      const HabitSuggestion(id: 'run', title: 'Run', icon: 'run'),
    ];

    test('constructor with lists', () {
      final config = OnboardingConfig(
        archetypes: archetypes,
        attributes: attributes,
        habitSuggestions: suggestions,
      );

      expect(config.archetypes, archetypes);
      expect(config.attributes, attributes);
      expect(config.habitSuggestions, suggestions);
    });

    test('Equatable equality with different lists', () {
      final a = OnboardingConfig(
        archetypes: archetypes,
        attributes: attributes,
        habitSuggestions: suggestions,
      );
      final b = OnboardingConfig(
        archetypes: archetypes,
        attributes: attributes,
        habitSuggestions: suggestions,
      );
      final c = OnboardingConfig(
        archetypes: [],
        attributes: attributes,
        habitSuggestions: suggestions,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
