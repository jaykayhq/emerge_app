import 'package:emerge_app/core/domain/models/app_world_theme.dart';

/// Single source of truth for which world themes are selectable.
///
/// `nebula` (Cosmic Nebula) is the main theme and stays unlocked; all
/// others are "coming soon" and locked. Deliberately free of Flutter,
/// storage, and Riverpod so it can be unit-tested without widgets
/// (mirrors CoachAskQuota / resolveBackgroundAsset).
class ThemeLock {
  /// The one theme users can select today.
  static const AppWorldTheme unlockedTheme = AppWorldTheme.nebula;

  static bool isLocked(AppWorldTheme theme) => theme != unlockedTheme;

  /// Clamps any theme to [unlockedTheme] when it is locked.
  /// Used on load so a legacy persisted locked value can never re-activate.
  static AppWorldTheme safeTheme(AppWorldTheme theme) =>
      isLocked(theme) ? unlockedTheme : theme;
}
