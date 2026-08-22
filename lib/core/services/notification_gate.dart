import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Channel kinds for permission gating. Every notification–producing path
/// must declare which kind it is so [NotificationGate] can enforce the
/// corresponding [UserSettings] toggle (or the master switch / DND window).
enum NotificationChannelKind {
  habitReminder,
  streakWarning,
  aiInsight,
  community,
  rewards,
  archetypeNudge,
  general,
}

/// Pure, testable permission gate for notifications.
///
/// The gate enforces, in order:
/// 1. Master switch [UserSettings.notificationsEnabled] — off means nothing.
/// 2. Per-channel toggle (see [_channelAllowed]).
/// 3. Do-Not-Disturb quiet-hours window (22:00–07:00 local) — suppresses all
///    non-critical channels. Streak warnings are considered non-critical too
///    and are also suppressed during DND; only a future "critical" kind
///    would bypass this.
/// 4. `null` settings (not yet loaded) → fail-open (allow) so first-launch
///    reminders still fire; the master toggle defaults to `true` anyway.
abstract final class NotificationGate {
  static bool shouldShow(
    UserSettings? settings,
    NotificationChannelKind kind, {
    DateTime? now,
  }) {
    final s = settings;
    if (s == null) return true;
    if (!s.notificationsEnabled) return false;

    // DND suppresses everything during 22:00–07:00.
    if (s.doNotDisturb && _isInDndWindow(now ?? DateTime.now())) return false;

    return _channelAllowed(s, kind);
  }

  static bool _isInDndWindow(DateTime t) {
    final h = t.hour;
    return h >= 22 || h < 7;
  }

  static bool _channelAllowed(UserSettings s, NotificationChannelKind k) {
    switch (k) {
      case NotificationChannelKind.habitReminder:
        return s.habitReminders;
      case NotificationChannelKind.streakWarning:
        return s.streakWarnings;
      case NotificationChannelKind.aiInsight:
        return s.aiInsights;
      case NotificationChannelKind.community:
        return s.communityUpdates;
      case NotificationChannelKind.rewards:
        return s.rewardsUpdates;
      case NotificationChannelKind.archetypeNudge:
        return s.archetypeNudges;
      case NotificationChannelKind.general:
        return true; // gated only by master + DND
    }
  }
}
