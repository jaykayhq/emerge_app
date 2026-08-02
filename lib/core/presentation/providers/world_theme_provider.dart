// lib/core/presentation/providers/world_theme_provider.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/domain/services/theme_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWorldThemeKey = 'app_world_theme';

/// Persisted Riverpod notifier for the user's selected world theme.
/// Defaults to [AppWorldTheme.nebula] so existing users see no change.
class WorldThemeNotifier extends Notifier<AppWorldTheme> {
  @override
  AppWorldTheme build() {
    // Return the default immediately, then load persisted value asynchronously.
    _loadFromPrefs();
    return AppWorldTheme.nebula;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWorldThemeKey);
    if (saved != null) {
      final theme = AppWorldTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppWorldTheme.nebula,
      );
      // Legacy users may have a locked theme persisted from before the
      // lock shipped — clamp it so it can never re-activate.
      state = ThemeLock.safeTheme(theme);
    }
  }

  Future<void> setTheme(AppWorldTheme theme) async {
    // Locked themes are "coming soon": ignore entirely (no state change,
    // no prefs write) so no call site can bypass the lock.
    if (ThemeLock.isLocked(theme)) return;
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWorldThemeKey, theme.name);
  }
}

final worldThemeProvider = NotifierProvider<WorldThemeNotifier, AppWorldTheme>(
  WorldThemeNotifier.new,
);
