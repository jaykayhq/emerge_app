import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorTrigger', () {
    test('has exactly 9 values', () {
      expect(NarratorTrigger.values.length, 9);
    });

    test('contains onboardingPostArchetype', () {
      expect(
        NarratorTrigger.values,
        contains(NarratorTrigger.onboardingPostArchetype),
      );
    });

    test('contains morningBriefEarlyDays', () {
      expect(
        NarratorTrigger.values,
        contains(NarratorTrigger.morningBriefEarlyDays),
      );
    });

    test('contains streakBreakFirstMiss', () {
      expect(
        NarratorTrigger.values,
        contains(NarratorTrigger.streakBreakFirstMiss),
      );
    });

    test('contains onFireState', () {
      expect(NarratorTrigger.values, contains(NarratorTrigger.onFireState));
    });

    test('contains levelUp', () {
      expect(NarratorTrigger.values, contains(NarratorTrigger.levelUp));
    });

    test('contains weeklyRecap', () {
      expect(NarratorTrigger.values, contains(NarratorTrigger.weeklyRecap));
    });

    test('contains longAbsence', () {
      expect(NarratorTrigger.values, contains(NarratorTrigger.longAbsence));
    });

    test('contains askNarrator', () {
      expect(NarratorTrigger.values, contains(NarratorTrigger.askNarrator));
    });

    test('contains eveningReflection', () {
      expect(
        NarratorTrigger.values,
        contains(NarratorTrigger.eveningReflection),
      );
    });


  });
}

