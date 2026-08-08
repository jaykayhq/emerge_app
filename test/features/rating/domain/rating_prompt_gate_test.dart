import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 8, 12);
  const cooldown = Duration(days: 90);

  group('RatingPromptGate.shouldAsk', () {
    test('asks when never asked before', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: null,
          versionAskedFor: null,
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isTrue,
      );
    });

    test('does not ask twice in the same version', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.subtract(const Duration(days: 1)),
          versionAskedFor: '1.0.7+12',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('does not ask again in the same version even after cooldown expires', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.subtract(const Duration(days: 120)),
          versionAskedFor: '1.0.7+12',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('asks again in a newer version after cooldown', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: DateTime(2026, 1, 1),
          versionAskedFor: '1.0.5+9',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isTrue,
      );
    });

    test('does not ask within cooldown even in a newer version', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.subtract(const Duration(days: 10)),
          versionAskedFor: '1.0.6+11',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('never asks when dontAskAgain is set', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.challengeCompleted,
          now: now,
          lastAskedAt: null,
          versionAskedFor: null,
          dontAskAgain: true,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });

    test('does not ask when lastAskedAt is in the future (clock skew)', () {
      expect(
        RatingPromptGate.shouldAsk(
          signal: RatingPromptSignal.sevenDayStreak,
          now: now,
          lastAskedAt: now.add(const Duration(days: 1)),
          versionAskedFor: '1.0.6+11',
          dontAskAgain: false,
          currentVersion: '1.0.7+12',
          cooldown: cooldown,
        ),
        isFalse,
      );
    });
  });
}
