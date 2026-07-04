import 'package:emerge_app/features/gamification/domain/models/world_event.dart';
import 'package:emerge_app/features/gamification/domain/services/world_event_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldEventEngine', () {
    final baseStats = UserStats(
      consecutiveActiveDays: 1,
      currentMomentumScore: 50,
      level: 1,
    );

    final fixedNow = DateTime(2026, 7, 2, 12, 0, 0); // July 2, 2026

    group('travelerVisit', () {
      test('fires when consecutiveActiveDays >= 5 and no cooldown', () {
        final stats = baseStats.copyWith(consecutiveActiveDays: 5);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final travelerEvents = events
            .where((e) => e.type == WorldEventType.travelerVisit)
            .toList();
        expect(travelerEvents, hasLength(1));
        expect(travelerEvents.first.payload['travelerName'], 'Wanderer');
      });

      test('does NOT fire when consecutiveActiveDays < 5', () {
        final stats = baseStats.copyWith(consecutiveActiveDays: 4);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final travelerEvents = events
            .where((e) => e.type == WorldEventType.travelerVisit)
            .toList();
        expect(travelerEvents, isEmpty);
      });

      test('does NOT fire when on 24h cooldown', () {
        final stats = baseStats.copyWith(consecutiveActiveDays: 5);
        final recentEvents = {
          WorldEventType.travelerVisit:
              fixedNow.subtract(const Duration(hours: 12)),
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final travelerEvents = events
            .where((e) => e.type == WorldEventType.travelerVisit)
            .toList();
        expect(travelerEvents, isEmpty);
      });

      test('fires when cooldown has expired (>= 24h)', () {
        final stats = baseStats.copyWith(consecutiveActiveDays: 5);
        final recentEvents = {
          WorldEventType.travelerVisit:
              fixedNow.subtract(const Duration(hours: 25)),
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final travelerEvents = events
            .where((e) => e.type == WorldEventType.travelerVisit)
            .toList();
        expect(travelerEvents, hasLength(1));
      });
    });

    group('weatherShift', () {
      test('fires once per day with deterministic weather', () {
        final events = WorldEventEngine.evaluateAndFire(
          stats: baseStats,
          now: fixedNow,
          recentEvents: const {},
        );

        final weatherEvents = events
            .where((e) => e.type == WorldEventType.weatherShift)
            .toList();
        expect(weatherEvents, hasLength(1));
      });

      test('produces deterministic weather for the same date', () {
        // July 2: day=2, month=7 => seed=14 => index=14%6=2 => 'rainy'
        final weather1 = WorldEventEngine.weatherForDate(fixedNow);
        final weather2 = WorldEventEngine.weatherForDate(fixedNow);
        expect(weather1, weather2);
        expect(weather1, 'rainy');
      });

      test('produces different weather for different dates', () {
        final date1 = DateTime(2026, 7, 2); // day=2, month=7 => seed=14 => 'rainy'
        final date2 = DateTime(2026, 7, 3); // day=3, month=7 => seed=21 => 'foggy' (21%6=3 => 'foggy')

        final weather1 = WorldEventEngine.weatherForDate(date1);
        final weather2 = WorldEventEngine.weatherForDate(date2);
        expect(weather1, isNot(equals(weather2)));
      });

      test('does NOT fire twice on the same day', () {
        final recentEvents = {
          WorldEventType.weatherShift: fixedNow,
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: baseStats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final weatherEvents = events
            .where((e) => e.type == WorldEventType.weatherShift)
            .toList();
        expect(weatherEvents, isEmpty);
      });
    });

    group('discoveryBurst', () {
      test('fires when momentumScore >= 90 and no cooldown', () {
        final stats = baseStats.copyWith(currentMomentumScore: 90);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final burstEvents = events
            .where((e) => e.type == WorldEventType.discoveryBurst)
            .toList();
        expect(burstEvents, hasLength(1));
        expect(burstEvents.first.payload['xpBonus'], 25); // level 1 => 25 XP
      });

      test('does NOT fire when momentumScore < 90', () {
        final stats = baseStats.copyWith(currentMomentumScore: 89);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final burstEvents = events
            .where((e) => e.type == WorldEventType.discoveryBurst)
            .toList();
        expect(burstEvents, isEmpty);
      });

      test('scales XP bonus with level', () {
        // Level >= 30 => 100 XP
        final stats100 = baseStats.copyWith(
          currentMomentumScore: 95,
          level: 30,
        );
        final events100 = WorldEventEngine.evaluateAndFire(
          stats: stats100,
          now: fixedNow,
          recentEvents: const {},
        );
        final burst100 = events100
            .where((e) => e.type == WorldEventType.discoveryBurst)
            .first;
        expect(burst100.payload['xpBonus'], 100);

        // Level 20 => 75 XP
        final stats75 = baseStats.copyWith(
          currentMomentumScore: 95,
          level: 20,
        );
        final events75 = WorldEventEngine.evaluateAndFire(
          stats: stats75,
          now: fixedNow,
          recentEvents: const {},
        );
        final burst75 = events75
            .where((e) => e.type == WorldEventType.discoveryBurst)
            .first;
        expect(burst75.payload['xpBonus'], 75);

        // Level 10 => 50 XP
        final stats50 = baseStats.copyWith(
          currentMomentumScore: 95,
          level: 10,
        );
        final events50 = WorldEventEngine.evaluateAndFire(
          stats: stats50,
          now: fixedNow,
          recentEvents: const {},
        );
        final burst50 = events50
            .where((e) => e.type == WorldEventType.discoveryBurst)
            .first;
        expect(burst50.payload['xpBonus'], 50);
      });
    });

    group('biomeTransition', () {
      test('fires at level 5', () {
        final stats = baseStats.copyWith(level: 5);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, hasLength(1));
        expect(biomeEvents.first.payload['newLevel'], 5);
      });

      test('fires at level 10', () {
        final stats = baseStats.copyWith(level: 10);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, hasLength(1));
      });

      test('fires at level 20', () {
        final stats = baseStats.copyWith(level: 20);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, hasLength(1));
      });

      test('fires at level 30', () {
        final stats = baseStats.copyWith(level: 30);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, hasLength(1));
      });

      test('does NOT fire at non-biome levels', () {
        // Level 4 — just below the first threshold
        final stats = baseStats.copyWith(level: 4);
        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, isEmpty);
      });

      test('does NOT fire when on 24h cooldown', () {
        final stats = baseStats.copyWith(level: 5);
        final recentEvents = {
          WorldEventType.biomeTransition:
              fixedNow.subtract(const Duration(hours: 1)),
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final biomeEvents = events
            .where((e) => e.type == WorldEventType.biomeTransition)
            .toList();
        expect(biomeEvents, isEmpty);
      });
    });

    group('multiple events', () {
      test('can fire multiple events simultaneously', () {
        // Level 30 + momentum 95 + 5 consecutive days = biome + burst + traveler + weather
        final stats = UserStats(
          consecutiveActiveDays: 5,
          currentMomentumScore: 95,
          level: 30,
        );

        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: const {},
        );

        // Should get biomeTransition, discoveryBurst, travelerVisit, and weatherShift
        final types = events.map((e) => e.type).toSet();
        expect(types, contains(WorldEventType.biomeTransition));
        expect(types, contains(WorldEventType.discoveryBurst));
        expect(types, contains(WorldEventType.travelerVisit));
        expect(types, contains(WorldEventType.weatherShift));
      });
    });

    group('edge cases', () {
      test('returns empty list when no conditions are met', () {
        final stats = UserStats(
          consecutiveActiveDays: 0,
          currentMomentumScore: 0,
          level: 0,
        );

        // Use a date where weather has already fired today
        final recentEvents = {
          WorldEventType.weatherShift: fixedNow,
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: stats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        expect(events, isEmpty);
      });

      test('weather does not fire if weather already fired today', () {
        final recentEvents = {
          WorldEventType.weatherShift: fixedNow.subtract(
            const Duration(hours: 2),
          ),
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: baseStats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final weatherEvents = events
            .where((e) => e.type == WorldEventType.weatherShift)
            .toList();
        expect(weatherEvents, isEmpty);
      });

      test('weather fires again on a different day', () {
        final yesterday = fixedNow.subtract(const Duration(days: 1));
        final recentEvents = {
          WorldEventType.weatherShift: yesterday,
        };

        final events = WorldEventEngine.evaluateAndFire(
          stats: baseStats,
          now: fixedNow,
          recentEvents: recentEvents,
        );

        final weatherEvents = events
            .where((e) => e.type == WorldEventType.weatherShift)
            .toList();
        expect(weatherEvents, hasLength(1));
      });
    });

    group('weatherForDate', () {
      test('returns one of the six weather types', () {
        const validWeathers = [
          'clear',
          'cloudy',
          'rainy',
          'stormy',
          'windy',
          'foggy',
        ];

        // Test a month's worth of days
        for (int day = 1; day <= 31; day++) {
          final date = DateTime(2026, 7, day);
          final weather = WorldEventEngine.weatherForDate(date);
          expect(validWeathers, contains(weather));
        }
      });
    });

    group('biomeTransitionLevels', () {
      test('returns the correct levels', () {
        expect(
          WorldEventEngine.biomeTransitionLevels,
          [5, 10, 20, 30],
        );
      });
    });
  });
}

/// Extension on UserStats to provide a copyWith helper for tests.
extension _UserStatsCopy on UserStats {
  UserStats copyWith({
    int? consecutiveActiveDays,
    int? currentMomentumScore,
    int? level,
  }) {
    return UserStats(
      consecutiveActiveDays: consecutiveActiveDays ?? this.consecutiveActiveDays,
      currentMomentumScore: currentMomentumScore ?? this.currentMomentumScore,
      level: level ?? this.level,
    );
  }
}
