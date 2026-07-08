import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompanionEventType', () {
    test('has correct values', () {
      expect(CompanionEventType.values, [
        CompanionEventType.firstFeatureVisit,
        CompanionEventType.milestoneReached,
        CompanionEventType.struggleDetected,
        CompanionEventType.featureUnlocked,
        CompanionEventType.dailyCheckIn,
        CompanionEventType.userInitiated,
      ]);
    });
  });

  group('CompanionMode', () {
    test('has correct values', () {
      expect(CompanionMode.values, [
        CompanionMode.overlay,
        CompanionMode.panel,
        CompanionMode.inlineCard,
      ]);
    });
  });
}
