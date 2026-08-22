import 'package:emerge_app/core/services/notification_gate.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserSettings base({bool? master, bool? community, bool? habit, bool? streak, bool? ai, bool? rewards, bool? archetype, bool? dnd}) {
    return UserSettings(
      notificationsEnabled: master ?? true,
      habitReminders: habit ?? true,
      streakWarnings: streak ?? true,
      aiInsights: ai ?? true,
      communityUpdates: community ?? true,
      rewardsUpdates: rewards ?? true,
      archetypeNudges: archetype ?? true,
      doNotDisturb: dnd ?? false,
    );
  }

  group('NotificationGate', () {
    test('master off blocks everything', () {
      final s = base(master: false);
      for (final k in NotificationChannelKind.values) {
        expect(NotificationGate.shouldShow(s, k), isFalse, reason: '$k');
      }
    });

    test('null settings fail-open', () {
      expect(NotificationGate.shouldShow(null, NotificationChannelKind.general), isTrue);
    });

    test('per-channel toggles respected', () {
      expect(NotificationGate.shouldShow(base(community: false), NotificationChannelKind.community), isFalse);
      expect(NotificationGate.shouldShow(base(habit: false), NotificationChannelKind.habitReminder), isFalse);
      expect(NotificationGate.shouldShow(base(streak: false), NotificationChannelKind.streakWarning), isFalse);
      expect(NotificationGate.shouldShow(base(ai: false), NotificationChannelKind.aiInsight), isFalse);
      expect(NotificationGate.shouldShow(base(rewards: false), NotificationChannelKind.rewards), isFalse);
      expect(NotificationGate.shouldShow(base(archetype: false), NotificationChannelKind.archetypeNudge), isFalse);
    });

    test('DND suppresses during quiet hours', () {
      final s = base(dnd: true);
      expect(NotificationGate.shouldShow(s, NotificationChannelKind.general, now: DateTime(2026, 1, 1, 23, 0)), isFalse);
      expect(NotificationGate.shouldShow(s, NotificationChannelKind.general, now: DateTime(2026, 1, 1, 6, 59)), isFalse);
      expect(NotificationGate.shouldShow(s, NotificationChannelKind.general, now: DateTime(2026, 1, 1, 7, 0)), isTrue);
      expect(NotificationGate.shouldShow(s, NotificationChannelKind.general, now: DateTime(2026, 1, 1, 22, 0)), isFalse);
      expect(NotificationGate.shouldShow(s, NotificationChannelKind.general, now: DateTime(2026, 1, 1, 12, 0)), isTrue);
    });
  });
}
