/// Types of world events that can fire in the game world.
enum WorldEventType {
  /// A mysterious traveler visits the user's world.
  travelerVisit,

  /// The weather in the user's world shifts (deterministic, seeded by date).
  weatherShift,

  /// A burst of discovery occurs when momentum is high.
  discoveryBurst,

  /// The biome transitions at key level thresholds.
  biomeTransition,
}

/// A world event that fires in the game world, carrying contextual payload data.
class WorldEvent {
  final WorldEventType type;
  final Map<String, dynamic> payload;
  final DateTime firedAt;

  const WorldEvent({
    required this.type,
    required this.payload,
    required this.firedAt,
  });

  /// Creates a [WorldEvent] for a traveler visit.
  factory WorldEvent.travelerVisit({
    required DateTime firedAt,
    String? travelerName,
  }) {
    return WorldEvent(
      type: WorldEventType.travelerVisit,
      payload: {'travelerName': travelerName ?? 'Wanderer'},
      firedAt: firedAt,
    );
  }

  /// Creates a [WorldEvent] for a weather shift.
  factory WorldEvent.weatherShift({
    required DateTime firedAt,
    required String weatherType,
  }) {
    return WorldEvent(
      type: WorldEventType.weatherShift,
      payload: {'weatherType': weatherType},
      firedAt: firedAt,
    );
  }

  /// Creates a [WorldEvent] for a discovery burst.
  factory WorldEvent.discoveryBurst({
    required DateTime firedAt,
    required int xpBonus,
  }) {
    return WorldEvent(
      type: WorldEventType.discoveryBurst,
      payload: {'xpBonus': xpBonus},
      firedAt: firedAt,
    );
  }

  /// Creates a [WorldEvent] for a biome transition.
  factory WorldEvent.biomeTransition({
    required DateTime firedAt,
    required int newLevel,
  }) {
    return WorldEvent(
      type: WorldEventType.biomeTransition,
      payload: {'newLevel': newLevel},
      firedAt: firedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          firedAt == other.firedAt &&
          payload == other.payload;

  @override
  int get hashCode => Object.hash(type, firedAt, payload);

  @override
  String toString() =>
      'WorldEvent(type: $type, firedAt: $firedAt, payload: $payload)';
}

/// User statistics used by the [WorldEventEngine] to evaluate events.
class UserStats {
  final int consecutiveActiveDays;
  final int currentMomentumScore;
  final int level;

  const UserStats({
    required this.consecutiveActiveDays,
    required this.currentMomentumScore,
    required this.level,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStats &&
          runtimeType == other.runtimeType &&
          consecutiveActiveDays == other.consecutiveActiveDays &&
          currentMomentumScore == other.currentMomentumScore &&
          level == other.level;

  @override
  int get hashCode =>
      Object.hash(consecutiveActiveDays, currentMomentumScore, level);

  @override
  String toString() =>
      'UserStats(consecutiveActiveDays: $consecutiveActiveDays, '
      'currentMomentumScore: $currentMomentumScore, level: $level)';
}
