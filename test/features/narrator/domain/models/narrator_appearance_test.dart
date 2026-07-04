import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorAppearance', () {
    test('can be created with all required fields', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up! Keep going!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );

      expect(appearance.trigger, NarratorTrigger.levelUp);
      expect(appearance.shellText, 'You leveled up! Keep going!');
      expect(appearance.buttonA, 'Awesome!');
      expect(appearance.buttonB, 'Show Stats');
      expect(appearance.slotKeys, isNull);
      expect(appearance.hasTextField, false);
      expect(appearance.context, isNull);
    });

    test('can be created with optional slotKeys', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.morningBriefEarlyDays,
        shellText: 'Good morning!',
        buttonA: 'Start Day',
        buttonB: 'Dismiss',
        slotKeys: ['habit_1', 'habit_2'],
      );

      expect(appearance.slotKeys, ['habit_1', 'habit_2']);
    });

    test('can be created with hasTextField true', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.eveningReflection,
        shellText: 'How was your day?',
        buttonA: 'Save',
        buttonB: 'Skip',
        hasTextField: true,
      );

      expect(appearance.hasTextField, true);
    });

    test('can be created with context map', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.dailyInsight,
        shellText: 'Here is your daily insight.',
        buttonA: 'Tell Me More',
        buttonB: 'Dismiss',
        context: {'xp': 50, 'streak': 3},
      );

      expect(appearance.context, {'xp': 50, 'streak': 3});
    });

    test('supports value equality', () {
      final appearance1 = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );
      final appearance2 = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );

      expect(appearance1, equals(appearance2));
    });

    test('does not equal different appearance', () {
      final appearance1 = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );
      final appearance2 = NarratorAppearance(
        trigger: NarratorTrigger.onFireState,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );

      expect(appearance1, isNot(equals(appearance2)));
    });

    test('supports copyWith', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
      );

      final updated = appearance.copyWith(
        shellText: 'New text!',
        hasTextField: true,
      );

      expect(updated.trigger, NarratorTrigger.levelUp);
      expect(updated.shellText, 'New text!');
      expect(updated.hasTextField, true);
      expect(updated.buttonA, 'Awesome!');
    });
  });
}
