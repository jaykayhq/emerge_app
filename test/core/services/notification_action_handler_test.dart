import 'package:emerge_app/core/services/notification_action_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationActionIds', () {
    test('complete action ID is defined', () {
      expect(NotificationActionIds.complete, 'complete');
    });

    test('snooze1h action ID is defined', () {
      expect(NotificationActionIds.snooze1h, 'snooze_1h');
    });

    test('action IDs are distinct', () {
      expect(NotificationActionIds.complete, isNot(
        equals(NotificationActionIds.snooze1h),
      ));
    });
  });

  group('NotificationActionHandler', () {
    /// A minimal ProviderContainer for handler tests.
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('handle with unknown action does not throw', () async {
      await expectLater(
        () => NotificationActionHandler.handle(
          actionId: 'unknown_action',
          payload: 'habit_1',
          container: container,
        ),
        returnsNormally,
      );
    });

    test('handle with null payload does not throw', () async {
      await expectLater(
        () => NotificationActionHandler.handle(
          actionId: NotificationActionIds.complete,
          payload: null,
          container: container,
        ),
        returnsNormally,
      );
    });

    test('handle with empty payload does not throw', () async {
      await expectLater(
        () => NotificationActionHandler.handle(
          actionId: NotificationActionIds.complete,
          payload: '',
          container: container,
        ),
        returnsNormally,
      );
    });
  });
}
