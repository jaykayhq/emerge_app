import 'package:emerge_app/features/gamification/domain/services/completion_xp_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompletionXpSplit', () {
    test('user stats receive base + challenge XP', () {
      const split = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      expect(split.userStatsDelta, 15);
    });

    test('tribe totals and contributors receive base XP only', () {
      const split = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      expect(split.tribeDelta, 10);
    });

    test('undo debits are exact mirrors of credit deltas', () {
      const credit = CompletionXpSplit(xpGained: 10, challengeXp: 5);
      const undo = CompletionXpSplit.fromStoredRow(xpGained: 10, challengeXp: 5);
      expect(undo.userStatsDelta, -credit.userStatsDelta);
      expect(undo.tribeDelta, -credit.tribeDelta);
    });

    test('zero-challenge split behaves like legacy', () {
      const split = CompletionXpSplit(xpGained: 7, challengeXp: 0);
      expect(split.userStatsDelta, 7);
      expect(split.tribeDelta, 7);
    });
  });

  group('buildUserStatsXpPayload', () {
    test('emits the single write shape used by credit and undo', () {
      final payload = buildUserStatsXpPayload(
        totalDelta: 15,
        attr: 'vitality',
        level: 3,
        streak: 4,
        updatedAt: '2026-08-01T12:00:00.000',
      );
      expect(payload['avatarStats.totalXp'],
          {'__type__': 'increment', 'value': 15});
      expect(payload['avatarStats.vitalityXp'],
          {'__type__': 'increment', 'value': 15});
      expect(payload['avatarStats.level'], 3);
      expect(payload['avatarStats.streak'], 4);
      expect(payload['updatedAt'], '2026-08-01T12:00:00.000');
    });
  });
}
