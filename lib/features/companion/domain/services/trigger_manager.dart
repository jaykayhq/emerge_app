import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';

class TriggerManager {
  static const _priorityOrder = [
    CompanionEventType.userInitiated,
    CompanionEventType.milestoneReached,
    CompanionEventType.struggleDetected,
    CompanionEventType.dailyCheckIn,
    CompanionEventType.firstFeatureVisit,
    CompanionEventType.featureUnlocked,
  ];

  static CompanionEventType? resolvePriority(List<CompanionEventType> events) {
    if (events.isEmpty) return null;
    if (events.length == 1) return events.first;

    for (final priority in _priorityOrder) {
      if (events.contains(priority)) return priority;
    }
    return events.first;
  }

  static CompanionMode resolveMode(CompanionEventType event) {
    return switch (event) {
      CompanionEventType.firstFeatureVisit => CompanionMode.overlay,
      CompanionEventType.featureUnlocked   => CompanionMode.overlay,
      CompanionEventType.userInitiated     => CompanionMode.panel,
      CompanionEventType.milestoneReached  => CompanionMode.inlineCard,
      CompanionEventType.struggleDetected  => CompanionMode.inlineCard,
      CompanionEventType.dailyCheckIn     => CompanionMode.inlineCard,
    };
  }
}
