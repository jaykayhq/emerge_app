import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationTemplates', () {
    group('welcomeMessage', () {
      test('returns correct messages for all archetypes', () {
        const habit = 'Test Habit';
        final cases = {
          UserArchetype.athlete:
              '💪 Your journey to greatness begins! "$habit" is now part of your training.',
          UserArchetype.scholar:
              '📚 A new quest for knowledge begins! Mastering "$habit" starts now.',
          UserArchetype.creator:
              '🎨 Inspiration strikes! Your creative journey with "$habit" starts today.',
          UserArchetype.stoic:
              '🏛️ The path to mastery begins with a single step. "$habit" is your practice.',
          UserArchetype.zealot:
              '🔥 A sacred commitment! Your devotion to "$habit" has been consecrated.',
          UserArchetype.none:
              '✨ New habit started! "$habit" is now part of your journey.',
        };
        cases.forEach((archetype, expected) {
          expect(
            NotificationTemplates.welcomeMessage(archetype, habit),
            expected,
          );
        });
      });

      test('handles empty habit title', () {
        expect(
          NotificationTemplates.welcomeMessage(UserArchetype.athlete, ''),
          contains(''),
        );
      });
    });

    group('reminderMessage', () {
      test('returns correct messages for all archetypes', () {
        const habit = 'Test Habit';
        final cases = {
          UserArchetype.athlete:
              '💪 Time to train! Your "$habit" session awaits. Make yourself proud!',
          UserArchetype.scholar:
              '📚 Knowledge calls! Your "$habit" study session is ready. Begin the quest.',
          UserArchetype.creator:
              '🎨 Inspiration strikes! Time for your "$habit" creative flow. Create today.',
          UserArchetype.stoic:
              '🏛️ Master yourself! Your "$habit" practice awaits. Show your discipline.',
          UserArchetype.zealot:
              '🔥 Stay the path! Your sacred "$habit" devotion calls. Honor your commitment.',
          UserArchetype.none:
              '⏰ Time to focus! Complete "$habit" to stay on track with your goals.',
        };
        cases.forEach((archetype, expected) {
          expect(
            NotificationTemplates.reminderMessage(archetype, habit),
            expected,
          );
        });
      });
    });

    group('streakWarning', () {
      test('includes streak days for all archetypes', () {
        const streakDays = 21;
        final cases = {
          UserArchetype.athlete:
              '⚠️ 💪 Your $streakDays-day training streak is at risk! Don\'t lose your momentum—train now!',
          UserArchetype.scholar:
              '⚠️ 📚 Your $streakDays-day knowledge quest is fading! Protect your streak—learn now.',
          UserArchetype.creator:
              '⚠️ 🎨 Your $streakDays-day creative flow is at risk! Keep the inspiration going—create now.',
          UserArchetype.stoic:
              '⚠️ 🏛️ Your $streakDays-day practice is imperiled! Maintain your discipline—act now.',
          UserArchetype.zealot:
              '⚠️ 🔥 Your $streakDays-day sacred devotion wavers! Rekindle your flame—act now.',
          UserArchetype.none:
              '⚠️ Your $streakDays-day streak is at risk! Complete your habit now to keep it alive.',
        };
        cases.forEach((archetype, expected) {
          expect(
            NotificationTemplates.streakWarning(archetype, streakDays),
            expected,
          );
        });
      });

      test('handles zero streak days', () {
        expect(
          NotificationTemplates.streakWarning(UserArchetype.athlete, 0),
          contains('0-day'),
        );
      });
    });

    group('aiInsightGreeting', () {
      test('returns correct messages for all archetypes', () {
        final cases = {
          UserArchetype.athlete:
              '💪 Your training insights are ready! Optimize your performance today.',
          UserArchetype.scholar:
              '📚 Wisdom awaits! Your personalized learning insights have arrived.',
          UserArchetype.creator:
              '🎨 Creative inspiration delivered! Your muse has new insights for you.',
          UserArchetype.stoic:
              '🏛️ Clarity awaits! Your daily reflection on mastery and discipline is here.',
          UserArchetype.zealot:
              '🔥 Divine guidance! Your sacred insights for the path have been revealed.',
          UserArchetype.none:
              '✨ Your daily insights are ready! Discover what\'s possible today.',
        };
        cases.forEach((archetype, expected) {
          expect(NotificationTemplates.aiInsightGreeting(archetype), expected);
        });
      });
    });

    group('levelUp', () {
      test('returns correct messages for all archetypes', () {
        const newLevel = 5;
        final cases = {
          UserArchetype.athlete:
              '🏆 💪 LEVEL UP! You\'ve reached Level $newLevel! Your training yields greatness!',
          UserArchetype.scholar:
              '🏆 📚 WISDOM GROWS! You\'ve reached Level $newLevel! Knowledge expands within you.',
          UserArchetype.creator:
              '🏆 🎨 MUSE FAVORS YOU! You\'ve reached Level $newLevel! Your artistry elevates!',
          UserArchetype.stoic:
              '🏆 🏛️ MASTERY AWAITS! You\'ve reached Level $newLevel! Your discipline strengthens!',
          UserArchetype.zealot:
              '🏆 🔥 SACRED ASCENSION! You\'ve reached Level $newLevel! Your devotion burns brighter!',
          UserArchetype.none:
              '🏆 LEVEL UP! You\'ve reached Level $newLevel! Keep up the amazing work!',
        };
        cases.forEach((archetype, expected) {
          expect(NotificationTemplates.levelUp(archetype, newLevel), expected);
        });
      });

      test('handles zero level', () {
        expect(
          NotificationTemplates.levelUp(UserArchetype.athlete, 0),
          contains('Level 0'),
        );
      });
    });

    group('achievement', () {
      test('returns correct messages for all archetypes', () {
        const achievement = 'Test Achievement';
        final cases = {
          UserArchetype.athlete:
              '🏅 💪 ACHIEVEMENT UNLOCKED: $achievement! Your dedication knows no bounds!',
          UserArchetype.scholar:
              '🏅 📚 KNOWLEDGE CONQUERED: $achievement! Your quest for wisdom succeeds!',
          UserArchetype.creator:
              '🏅 🎨 MASTERPIECE CREATED: $achievement! Your creative vision manifests!',
          UserArchetype.stoic:
              '🏅 🏛️ VIRTUE ATTAINED: $achievement! Your stoic practice bears fruit!',
          UserArchetype.zealot:
              '🏅 🔥 SACRED HONOR EARNED: $achievement! Your devotion is recognized!',
          UserArchetype.none:
              '🏅 ACHIEVEMENT UNLOCKED: $achievement! You\'re making incredible progress!',
        };
        cases.forEach((archetype, expected) {
          expect(
            NotificationTemplates.achievement(archetype, achievement),
            expected,
          );
        });
      });

      test('handles empty achievement name', () {
        expect(
          NotificationTemplates.achievement(UserArchetype.athlete, ''),
          contains('ACHIEVEMENT UNLOCKED:'),
        );
      });
    });

    group('getDefaultHour', () {
      test('returns correct hour for all archetypes', () {
        final cases = {
          UserArchetype.stoic: 5,
          UserArchetype.athlete: 6,
          UserArchetype.zealot: 6,
          UserArchetype.scholar: 8,
          UserArchetype.creator: 9,
          UserArchetype.none: 7,
        };
        cases.forEach((archetype, expectedHour) {
          expect(NotificationTemplates.getDefaultHour(archetype), expectedHour);
        });
      });
    });
  });

  group('NotificationChannels', () {
    group('channelForArchetype', () {
      test('returns correct channel IDs for all archetypes', () {
        final cases = {
          UserArchetype.athlete: 'athlete_habits',
          UserArchetype.scholar: 'scholar_habits',
          UserArchetype.creator: 'creator_habits',
          UserArchetype.stoic: 'stoic_habits',
          UserArchetype.zealot: 'zealot_habits',
          UserArchetype.none: 'none_habits',
        };
        cases.forEach((archetype, expectedChannel) {
          expect(
            NotificationChannels.channelForArchetype(archetype),
            expectedChannel,
          );
        });
      });
    });
  });

  group('NotificationIcons', () {
    group('archetypeIcons', () {
      test('returns correct icon names for all archetypes', () {
        final cases = {
          UserArchetype.athlete: 'icon_athlete',
          UserArchetype.scholar: 'icon_scholar',
          UserArchetype.creator: 'icon_creator',
          UserArchetype.stoic: 'icon_stoic',
          UserArchetype.zealot: 'icon_zealot',
          UserArchetype.none: 'icon_default',
        };
        cases.forEach((archetype, expectedIcon) {
          expect(NotificationIcons.archetypeIcons[archetype], expectedIcon);
        });
      });
    });
  });
}
