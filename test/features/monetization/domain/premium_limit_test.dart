import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/domain/models/premium_limit.dart';
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LimitsCatalog', () {
    test('lists exactly the four enforced limits', () {
      expect(LimitsCatalog.all.map((l) => l.featureKey).toList(), [
        'habits',
        'clubs',
        'coachAsk',
        'themes',
      ]);
    });

    test('every entry is fully copy-able', () {
      for (final limit in LimitsCatalog.all) {
        expect(limit.featureKey, isNotEmpty);
        expect(limit.unit, isNotEmpty);
        expect(limit.paywallTitle, isNotEmpty);
        expect(limit.paywallSubtitle, isNotEmpty);
        expect(limit.enforcedBy, isNotEmpty);
        expect(limit.freeValue, greaterThan(0));
      }
    });

    test('enforced values are 5 habits / 1 club / 3 coach asks / 1 theme', () {
      expect(LimitsCatalog.habits.freeValue, 5);
      expect(LimitsCatalog.clubs.freeValue, 1);
      expect(LimitsCatalog.coachAsk.freeValue, 3);
      expect(LimitsCatalog.themes.freeValue, 1);
    });

    test('habits matches the code default free habit limit', () {
      // Guardrail: Remote Config default and the catalog must not diverge.
      expect(LimitsCatalog.habits.freeValue, kDefaultFreeHabitLimit);
    });

    test('coachAsk matches the runtime quota limit', () {
      // Guardrail: CoachAskQuota (runtime enforcement) and the catalog must
      // not diverge.
      expect(LimitsCatalog.coachAsk.freeValue, CoachAskQuota.freeDailyLimit);
    });

    test('themes is not premium-bypassed', () {
      expect(LimitsCatalog.themes.premiumBypasses, isFalse);
    });

    test('forFeature finds known keys and misses unknown ones', () {
      expect(LimitsCatalog.forFeature('habits'), same(LimitsCatalog.habits));
      expect(LimitsCatalog.forFeature('themes'), same(LimitsCatalog.themes));
      expect(LimitsCatalog.forFeature('does_not_exist'), isNull);
    });
  });
}
