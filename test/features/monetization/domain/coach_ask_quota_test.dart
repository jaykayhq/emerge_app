import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachAskQuota', () {
    test('free user starts with 3 remaining', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 0,
        isPremium: false,
      );
      expect(quota.canAsk, isTrue);
      expect(quota.remaining, 3);
    });

    test('free user is blocked at the daily limit', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 3,
        isPremium: false,
      );
      expect(quota.canAsk, isFalse);
      expect(quota.remaining, 0);
    });

    test('premium user is never blocked', () {
      const quota = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 100,
        isPremium: true,
      );
      expect(quota.canAsk, isTrue);
      expect(quota.remaining, -1);
    });

    test('consume increments for free users only', () {
      const before = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 1,
        isPremium: false,
      );
      final after = before.consume();
      expect(after.usedToday, 2);

      const premium = CoachAskQuota(
        dateKey: '2026-08-01',
        usedToday: 5,
        isPremium: true,
      );
      expect(premium.consume().usedToday, 5);
    });

    test('fromStorage resets the counter when the date rolls over', () {
      final quota = CoachAskQuota.fromStorage(
        storedKey: '2026-07-31',
        used: 3,
        isPremium: false,
        now: DateTime(2026, 8, 1, 9),
      );
      expect(quota.usedToday, 0);
      expect(quota.dateKey, '2026-08-01');
    });

    test('fromStorage keeps the counter on the same day', () {
      final quota = CoachAskQuota.fromStorage(
        storedKey: '2026-08-01',
        used: 2,
        isPremium: false,
        now: DateTime(2026, 8, 1, 20),
      );
      expect(quota.usedToday, 2);
    });
  });
}
