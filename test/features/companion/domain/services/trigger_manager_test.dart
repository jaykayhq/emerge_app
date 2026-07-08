import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/companion/domain/services/trigger_manager.dart';

void main() {
  group('TriggerManager', () {
    test('userInitiated has highest priority', () {
      final result = TriggerManager.resolvePriority([
        CompanionEventType.firstFeatureVisit,
        CompanionEventType.userInitiated,
        CompanionEventType.milestoneReached,
      ]);
      expect(result, CompanionEventType.userInitiated);
    });

    test('returns null for empty list', () {
      expect(TriggerManager.resolvePriority([]), isNull);
    });

    test('returns only item for single event', () {
      expect(
        TriggerManager.resolvePriority([CompanionEventType.dailyCheckIn]),
        CompanionEventType.dailyCheckIn,
      );
    });
  });
}
