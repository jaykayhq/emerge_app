import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';

void main() {
  late CompanionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = CompanionRepository();
    await repository.init();
  });

  group('dismissal tracking', () {
    test('returns false for unknown message', () {
      expect(repository.isMessageDismissed('msg_1'), false);
    });

    test('returns true after dismiss', () async {
      await repository.dismissMessage('msg_1');
      expect(repository.isMessageDismissed('msg_1'), true);
    });
  });

  group('daily check-in', () {
    test('returns false when never checked in', () {
      expect(repository.hasCheckedInToday(), false);
    });

    test('returns true after check-in', () async {
      await repository.markCheckInDone();
      expect(repository.hasCheckedInToday(), true);
    });
  });

  group('cooldown', () {
    test('returns true when no cooldown set', () {
      expect(repository.isCooldownActive(), false);
    });
  });

  group('companion enabled', () {
    test('is enabled by default', () {
      expect(repository.isCompanionEnabled(), true);
    });

    test('can be disabled', () async {
      await repository.setCompanionEnabled(false);
      expect(repository.isCompanionEnabled(), false);
    });
  });
}
