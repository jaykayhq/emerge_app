import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

void main() {
  group('Blueprint model', () {
    test('fromMap and toMap are symmetric', () {
      final now = DateTime(2025, 6, 1);
      final blueprint = Blueprint(
        id: 'test_1',
        title: 'Morning Ritual',
        description: 'Start your day right',
        category: 'Morning',
        creatorName: 'Test Creator',
        creatorUserId: 'user_1',
        creatorArchetype: 'Scholar',
        createdAt: now,
        habits: [
          const BlueprintHabit(title: 'Wake up early'),
          const BlueprintHabit(
            title: 'Meditate',
            attribute: HabitAttribute.focus,
          ),
        ],
      );

      final map = blueprint.toMap();
      final restored = Blueprint.fromMap('test_1', map);

      expect(restored.id, blueprint.id);
      expect(restored.title, blueprint.title);
      expect(restored.description, blueprint.description);
      expect(restored.category, blueprint.category);
      expect(restored.creatorName, blueprint.creatorName);
      expect(restored.creatorUserId, blueprint.creatorUserId);
      expect(restored.creatorArchetype, blueprint.creatorArchetype);
      expect(restored.habits.length, blueprint.habits.length);
      expect(restored.habits[0].title, blueprint.habits[0].title);
      expect(restored.habits[1].attribute, blueprint.habits[1].attribute);
    });

    test('default values for new blueprint', () {
      final blueprint = Blueprint(
        id: 'test_2',
        title: 'Test',
        description: '',
        category: 'Fitness',
        creatorName: 'Emerge Official',
        creatorUserId: 'system',
        creatorArchetype: 'General',
        createdAt: DateTime.now(),
        habits: [const BlueprintHabit(title: 'Exercise')],
      );

      expect(blueprint.adoptionCount, 0);
      expect(blueprint.isPremium, false);
      expect(blueprint.tribeMemberCount, 0);
      expect(blueprint.isCreatorBlueprint, false);
      expect(blueprint.difficulty, BlueprintDifficulty.beginner);
    });

    test('copyWith preserves unchanged fields and overrides specified ones', () {
      final blueprint = Blueprint(
        id: 'test_3',
        title: 'Original',
        description: 'Original description',
        category: 'Fitness',
        creatorName: 'Creator',
        creatorUserId: 'user_1',
        creatorArchetype: 'Athlete',
        createdAt: DateTime.now(),
        habits: [const BlueprintHabit(title: 'Run')],
        adoptionCount: 10,
      );

      final copy = blueprint.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(copy.description, 'Original description');
      expect(copy.adoptionCount, 10);
      expect(copy.id, blueprint.id);
    });

    test('BlueprintHabit fromMap and toMap are symmetric', () {
      const habit = BlueprintHabit(
        title: 'Test Habit',
        timeOfDay: 'Morning',
        attribute: HabitAttribute.strength,
        frequency: 'Daily',
      );

      final map = habit.toMap();
      final restored = BlueprintHabit.fromMap(map);

      expect(restored.title, habit.title);
      expect(restored.timeOfDay, habit.timeOfDay);
      expect(restored.attribute, habit.attribute);
      expect(restored.frequency, habit.frequency);
    });

    test('BlueprintHabit defaults', () {
      const habit = BlueprintHabit(title: 'Minimal');
      expect(habit.attribute, HabitAttribute.vitality);
      expect(habit.frequency, 'Daily');
      expect(habit.timeOfDay, isNull);
    });
  });
}
