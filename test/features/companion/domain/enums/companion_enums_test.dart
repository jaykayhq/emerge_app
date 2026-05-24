import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';

void main() {
  group('CompanionEventType', () {
    test('has all expected values', () {
      expect(CompanionEventType.values.length, 6);
      expect(CompanionEventType.firstFeatureVisit, isA<CompanionEventType>());
      expect(CompanionEventType.milestoneReached, isA<CompanionEventType>());
      expect(CompanionEventType.struggleDetected, isA<CompanionEventType>());
      expect(CompanionEventType.featureUnlocked, isA<CompanionEventType>());
      expect(CompanionEventType.dailyCheckIn, isA<CompanionEventType>());
      expect(CompanionEventType.userInitiated, isA<CompanionEventType>());
    });
  });

  group('CompanionMode', () {
    test('has all expected values', () {
      expect(CompanionMode.values.length, 3);
      expect(CompanionMode.overlay, isA<CompanionMode>());
      expect(CompanionMode.panel, isA<CompanionMode>());
      expect(CompanionMode.inlineCard, isA<CompanionMode>());
    });
  });
}
