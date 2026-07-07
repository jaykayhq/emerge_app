import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
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
        line: const GenericLine('You leveled up! Keep going!'),
      );

      expect(appearance.trigger, NarratorTrigger.levelUp);
      expect(appearance.shellText, 'You leveled up! Keep going!');
      expect(appearance.buttonA, 'Awesome!');
      expect(appearance.buttonB, 'Show Stats');
      expect(appearance.slotKeys, isNull);
      expect(appearance.line, isA<GenericLine>());
      expect(appearance.line.text, 'You leveled up! Keep going!');
      expect(appearance.context, isNull);
    });

    test('can be created with optional slotKeys', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.morningBriefEarlyDays,
        shellText: 'Good morning!',
        buttonA: 'Start Day',
        buttonB: 'Dismiss',
        line: const GenericLine('Good morning!'),
        slotKeys: ['habit_1', 'habit_2'],
      );

      expect(appearance.slotKeys, ['habit_1', 'habit_2']);
    });

    test('can carry a PersonalLine', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.weeklyRecap,
        shellText: 'Your week in numbers.',
        buttonA: 'Show me',
        buttonB: 'Later',
        line: const PersonalLine(
          text: 'Your week in numbers — Tuesday strongest.',
          dataBasis: 'Tuesday 6-week streak',
        ),
      );

      expect(appearance.line, isA<PersonalLine>());
      expect(appearance.line.text, contains('Tuesday'));
    });

    test('can be created with context map', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'Here is your insight.',
        buttonA: 'Tell Me More',
        buttonB: 'Dismiss',
        line: const GenericLine('Here is your insight.'),
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
        line: const GenericLine('You leveled up!'),
      );
      final appearance2 = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
        line: const GenericLine('You leveled up!'),
      );

      expect(appearance1, equals(appearance2));
    });

    test('does not equal different appearance', () {
      final appearance1 = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
        line: const GenericLine('You leveled up!'),
      );
      final appearance2 = NarratorAppearance(
        trigger: NarratorTrigger.onFireState,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
        line: const GenericLine('You leveled up!'),
      );

      expect(appearance1, isNot(equals(appearance2)));
    });

    test('supports copyWith', () {
      final appearance = NarratorAppearance(
        trigger: NarratorTrigger.levelUp,
        shellText: 'You leveled up!',
        buttonA: 'Awesome!',
        buttonB: 'Show Stats',
        line: const GenericLine('You leveled up!'),
      );

      final updated = appearance.copyWith(
        shellText: 'New text!',
        line: const PersonalLine(text: 'New text!', dataBasis: 'copyWith'),
      );

      expect(updated.trigger, NarratorTrigger.levelUp);
      expect(updated.shellText, 'New text!');
      expect(updated.line, isA<PersonalLine>());
      expect(updated.buttonA, 'Awesome!');
    });
  });
}
