import 'package:emerge_app/features/gamification/domain/models/world_event.dart';

/// Pure logic engine that determines which world events should fire.
///
/// This class has NO framework dependencies and is fully testable.
///
/// Rules:
/// - [WorldEventType.travelerVisit]: fires when the user has 5+ consecutive
///   active days. 24-hour cooldown.
/// - [WorldEventType.weatherShift]: fires once per day, seeded by the day
///   of the year × month to produce fully deterministic weather. No cooldown
///   beyond "one per day".
/// - [WorldEventType.discoveryBurst]: fires when momentum score >= 90.
///   24-hour cooldown.
/// - [WorldEventType.biomeTransition]: fires ONCE when the user's level
///   crosses one of the biome-transition thresholds: 5, 10, 20, or 30
///   (i.e. previous level below the threshold, current level at or above).
///   No cooldown needed — a threshold can only be crossed once.
class WorldEventEngine {
  /// Cooldown duration for events (24 hours).
  static const Duration _eventCooldown = Duration(hours: 24);

  /// Levels that trigger a [WorldEventType.biomeTransition].
  static const List<int> _biomeTransitionLevels = [5, 10, 20, 30];

  /// Minimum consecutive active days for a traveler visit.
  static const int _travelerVisitMinDays = 5;

  /// Minimum momentum score for a discovery burst.
  static const int _discoveryBurstMinScore = 90;

  /// Evaluates the user's state and decides which world events should fire.
  ///
  /// [stats] - the user's current statistics.
  /// [now] - the current date/time (injected for testability).
  /// [recentEvents] - world events that have already fired recently, keyed by
  ///   their type. Used to enforce cooldowns.
  ///
  /// Returns a list of [WorldEvent]s that should fire. The order follows the
  /// priority: biomeTransition > discoveryBurst > travelerVisit > weatherShift.
  static List<WorldEvent> evaluateAndFire({
    required UserStats stats,
    required DateTime now,
    required Map<WorldEventType, DateTime> recentEvents,
  }) {
    final events = <WorldEvent>[];

    // biomeTransition — highest priority.
    // Fires only when the level JUST crossed a threshold (previous level
    // below, current level at or above), so it can never re-fire for a
    // transition that was already celebrated.
    if (_isBiomeTransition(stats.previousLevel ?? stats.level, stats.level)) {
      events.add(WorldEvent.biomeTransition(
        firedAt: now,
        newLevel: stats.level,
      ));
    }

    // discoveryBurst
    if (stats.currentMomentumScore >= _discoveryBurstMinScore &&
        !_isOnCooldown(
            WorldEventType.discoveryBurst, now, recentEvents)) {
      events.add(WorldEvent.discoveryBurst(
        firedAt: now,
        xpBonus: _calculateXpBonus(stats.level),
      ));
    }

    // travelerVisit
    if (stats.consecutiveActiveDays >= _travelerVisitMinDays &&
        !_isOnCooldown(
            WorldEventType.travelerVisit, now, recentEvents)) {
      events.add(WorldEvent.travelerVisit(firedAt: now));
    }

    // weatherShift — one per day, no cooldown beyond that
    if (!_hasWeatherFiredToday(now, recentEvents)) {
      events.add(WorldEvent.weatherShift(
        firedAt: now,
        weatherType: _deterministicWeather(now),
      ));
    }

    return events;
  }

  /// Returns the deterministic weather type for the given date.
  ///
  /// Uses a simple seed based on day-of-year × month to produce a consistent
  /// result for any given date.
  static String _deterministicWeather(DateTime date) {
    final seed = date.day * date.month;
    final index = seed % 6;
    const weatherTypes = [
      'clear',
      'cloudy',
      'rainy',
      'stormy',
      'windy',
      'foggy',
    ];
    return weatherTypes[index];
  }

  /// Calculates the XP bonus for a discovery burst based on the user's level.
  static int _calculateXpBonus(int level) {
    if (level >= 30) return 100;
    if (level >= 20) return 75;
    if (level >= 10) return 50;
    return 25;
  }

  /// Checks whether the user's level just crossed a biome-transition
  /// threshold: the previous level was below the threshold and the current
  /// level is at or above it. This guarantees the event fires exactly once
  /// per threshold, regardless of cooldowns or how often evaluation runs.
  static bool _isBiomeTransition(int previousLevel, int currentLevel) {
    return _biomeTransitionLevels.any(
        (threshold) => previousLevel < threshold && currentLevel >= threshold);
  }

  /// Checks if a weather shift has already fired today.
  static bool _hasWeatherFiredToday(
      DateTime now, Map<WorldEventType, DateTime> recentEvents) {
    final lastWeather = recentEvents[WorldEventType.weatherShift];
    if (lastWeather == null) return false;
    return lastWeather.year == now.year &&
        lastWeather.month == now.month &&
        lastWeather.day == now.day;
  }

  /// Checks whether the given event type is on cooldown.
  static bool _isOnCooldown(
    WorldEventType type,
    DateTime now,
    Map<WorldEventType, DateTime> recentEvents,
  ) {
    final lastFired = recentEvents[type];
    if (lastFired == null) return false;
    return now.difference(lastFired) < _eventCooldown;
  }

  // ---------------------------------------------------------------------------
  // Public helpers for testing
  // ---------------------------------------------------------------------------

  /// Returns the deterministic weather type for the given date (public helper).
  static String weatherForDate(DateTime date) => _deterministicWeather(date);

  /// Returns the list of biome transition levels (public helper).
  static List<int> get biomeTransitionLevels =>
      List.unmodifiable(_biomeTransitionLevels);
}
