import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalSettingsRepository', () {
    late LocalSettingsRepository repo;

    setUp(() {
      repo = LocalSettingsRepository();
    });

    test('isTutorialsEnabled defaults to true for new users', () {
      expect(repo.isTutorialsEnabled(), isTrue);
    });

    test('setTutorialsEnabled(false) then isTutorialsEnabled returns false',
        () async {
      await repo.setTutorialsEnabled(false);
      expect(repo.isTutorialsEnabled(), isFalse);
    });

    test('setTutorialsEnabled(true) after setting false returns true',
        () async {
      await repo.setTutorialsEnabled(false);
      await repo.setTutorialsEnabled(true);
      expect(repo.isTutorialsEnabled(), isTrue);
    });
  });
}
