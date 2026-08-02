import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/domain/services/theme_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeLock', () {
    test('unlockedTheme is the nebula default', () {
      expect(ThemeLock.unlockedTheme, AppWorldTheme.nebula);
    });

    test('nebula is unlocked', () {
      expect(ThemeLock.isLocked(AppWorldTheme.nebula), isFalse);
    });

    test('every other theme is locked', () {
      for (final theme in AppWorldTheme.values) {
        if (theme == AppWorldTheme.nebula) continue;
        expect(ThemeLock.isLocked(theme), isTrue, reason: '$theme should be locked');
      }
    });

    test('safeTheme passes the unlocked theme through', () {
      expect(ThemeLock.safeTheme(AppWorldTheme.nebula), AppWorldTheme.nebula);
    });

    test('safeTheme clamps every locked theme to nebula', () {
      for (final theme in AppWorldTheme.values) {
        expect(ThemeLock.safeTheme(theme), AppWorldTheme.nebula);
      }
    });
  });
}
