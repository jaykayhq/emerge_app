import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// Archetype-themed notification templates for the Emerge habit formation app.
///
/// Provides customized messaging based on user's chosen archetype (Athlete, Scholar,
/// Creator, Stoic, Zealot, Explorer) to reinforce identity-based habit formation.
/// Each notification type includes unique messaging that aligns with the archetype's
/// motivational themes and values.
class NotificationTemplates {
  NotificationTemplates._();

  /// Welcome notification when a new habit is created.
  ///
  /// Reinforces the user's identity choice and sets an empowering tone for their journey.
  static String welcomeMessage(
    UserArchetype archetype,
    String habitTitle, {
    HabitAttribute? attribute,
  }) {
    final arcEmoji = archetypeEmoji(archetype);
    final attrPart = attribute != null ? '${attributeEmoji(attribute)} ' : '';
    switch (archetype) {
      case UserArchetype.athlete:
        return '$arcEmoji Your journey to greatness begins! $attrPart"$habitTitle" is now part of your training.';
      case UserArchetype.scholar:
        return '$arcEmoji A new quest for knowledge begins! ${attrPart}Mastering "$habitTitle" starts now.';
      case UserArchetype.creator:
        return '$arcEmoji Inspiration strikes! ${attrPart}Your creative journey with "$habitTitle" starts today.';
      case UserArchetype.stoic:
        return '$arcEmoji The path to mastery begins with a single step. $attrPart"$habitTitle" is your practice.';
      case UserArchetype.zealot:
        return '$arcEmoji A sacred commitment! ${attrPart}Your devotion to "$habitTitle" has been consecrated.';
      case UserArchetype.none:
        return '✨ New habit started! $attrPart"$habitTitle" is now part of your journey.';
    }
  }

  /// Recurring reminder notification for habit completion.
  ///
  /// Provides archetype-specific motivation to take action now.
  static String reminderMessage(
    UserArchetype archetype,
    String habitTitle, {
    HabitAttribute? attribute,
  }) {
    final arcEmoji = archetypeEmoji(archetype);
    final attrPart = attribute != null ? '${attributeEmoji(attribute)} ' : '';
    switch (archetype) {
      case UserArchetype.athlete:
        return '$arcEmoji Time to train! Your $attrPart"$habitTitle" session awaits. Make yourself proud!';
      case UserArchetype.scholar:
        return '$arcEmoji Knowledge calls! Your $attrPart"$habitTitle" study session is ready. Begin the quest.';
      case UserArchetype.creator:
        return '$arcEmoji Inspiration strikes! Time for your $attrPart"$habitTitle" creative flow. Create today.';
      case UserArchetype.stoic:
        return '$arcEmoji Master yourself! Your $attrPart"$habitTitle" practice awaits. Show your discipline.';
      case UserArchetype.zealot:
        return '$arcEmoji Stay the path! Your sacred $attrPart"$habitTitle" devotion calls. Honor your commitment.';
      case UserArchetype.none:
        return '⏰ Time to focus! Complete $attrPart"$habitTitle" to stay on track with your goals.';
    }
  }

  /// Warning notification when a streak is at risk.
  ///
  /// Urgent messaging to prevent streak loss, framed within archetype context.
  static String streakWarning(UserArchetype archetype, int streakDays) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '⚠️ 💪 Your $streakDays-day training streak is at risk! Don\'t lose your momentum—train now!';
      case UserArchetype.scholar:
        return '⚠️ 📚 Your $streakDays-day knowledge quest is fading! Protect your streak—learn now.';
      case UserArchetype.zealot:
        return '⚠️ 🔥 Your $streakDays-day sacred devotion wavers! Rekindle your flame—act now.';
      case UserArchetype.creator:
        return '⚠️ 🎨 Your $streakDays-day creative flow is at risk! Keep the inspiration going—create now.';
      case UserArchetype.stoic:
        return '⚠️ 🏛️ Your $streakDays-day practice is imperiled! Maintain your discipline—act now.';
      case UserArchetype.none:
        return '⚠️ Your $streakDays-day streak is at risk! Complete your habit now to keep it alive.';
    }
  }

  /// Greeting message for daily AI insight notifications.
  ///
  /// Welcomes the user to personalized wisdom/recommendations.
  static String aiInsightGreeting(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '💪 Your training insights are ready! Optimize your performance today.';
      case UserArchetype.scholar:
        return '📚 Wisdom awaits! Your personalized learning insights have arrived.';
      case UserArchetype.creator:
        return '🎨 Creative inspiration delivered! Your muse has new insights for you.';
      case UserArchetype.stoic:
        return '🏛️ Clarity awaits! Your daily reflection on mastery and discipline is here.';
      case UserArchetype.zealot:
        return '🔥 Divine guidance! Your sacred insights for the path have been revealed.';
      case UserArchetype.none:
        return '✨ Your daily insights are ready! Discover what\'s possible today.';
    }
  }

  /// Level up achievement notification.
  ///
  /// Celebrates progression and reinforces identity growth.
  static String levelUp(UserArchetype archetype, int newLevel) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '🏆 💪 LEVEL UP! You\'ve reached Level $newLevel! Your training yields greatness!';
      case UserArchetype.scholar:
        return '🏆 📚 WISDOM GROWS! You\'ve reached Level $newLevel! Knowledge expands within you.';
      case UserArchetype.creator:
        return '🏆 🎨 MUSE FAVORS YOU! You\'ve reached Level $newLevel! Your artistry elevates!';
      case UserArchetype.stoic:
        return '🏆 🏛️ MASTERY AWAITS! You\'ve reached Level $newLevel! Your discipline strengthens!';
      case UserArchetype.zealot:
        return '🏆 🔥 SACRED ASCENSION! You\'ve reached Level $newLevel! Your devotion burns brighter!';
      case UserArchetype.none:
        return '🏆 LEVEL UP! You\'ve reached Level $newLevel! Keep up the amazing work!';
    }
  }

  /// Achievement unlocked notification.
  ///
  /// Celebrates specific milestones and accomplishments.
  static String achievement(UserArchetype archetype, String achievementName) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '🏅 💪 ACHIEVEMENT UNLOCKED: $achievementName! Your dedication knows no bounds!';
      case UserArchetype.scholar:
        return '🏅 📚 KNOWLEDGE CONQUERED: $achievementName! Your quest for wisdom succeeds!';
      case UserArchetype.creator:
        return '🏅 🎨 MASTERPIECE CREATED: $achievementName! Your creative vision manifests!';
      case UserArchetype.stoic:
        return '🏅 🏛️ VIRTUE ATTAINED: $achievementName! Your stoic practice bears fruit!';
      case UserArchetype.zealot:
        return '🏅 🔥 SACRED HONOR EARNED: $achievementName! Your devotion is recognized!';
      case UserArchetype.none:
        return '🏅 ACHIEVEMENT UNLOCKED: $achievementName! You\'re making incredible progress!';
    }
  }

  /// Returns the default notification hour for an archetype.
  ///
  /// Each archetype has an optimal time aligned with its philosophy:
  /// - Stoic: 5 AM (early morning discipline)
  /// - Athlete: 6 AM (training time)
  /// - Zealot: 6 AM (morning devotion)
  /// - Scholar: 8 AM (mind is fresh)
  /// - Creator: 9 AM (creative peak)
  static int getDefaultHour(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.stoic:
        return 5;
      case UserArchetype.athlete:
      case UserArchetype.zealot:
        return 6;
      case UserArchetype.scholar:
        return 8;
      case UserArchetype.creator:
        return 9;
      case UserArchetype.none:
        return 7;
    }
  }

  /// Identity-first emoji mapping for archetypes.
  static String archetypeEmoji(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return '🏃‍➡️';
      case UserArchetype.creator:
        return '🖌️';
      case UserArchetype.scholar:
        return '📖';
      case UserArchetype.stoic:
        return '🧘';
      case UserArchetype.zealot:
        return '🔥';
      case UserArchetype.none:
        return '✨';
    }
  }

  /// Attribute-based emoji mapping for granular habit identification.
  static String attributeEmoji(HabitAttribute attribute) {
    switch (attribute) {
      case HabitAttribute.strength:
        return '💪';
      case HabitAttribute.intellect:
        return '📚';
      case HabitAttribute.vitality:
        return '⚡';
      case HabitAttribute.creativity:
        return '🎨';
      case HabitAttribute.focus:
        return '🎯';
      case HabitAttribute.spirit:
        return '✨';
    }
  }
}

/// Notification channel IDs for different notification types.
///
/// These constants map to Android notification channels used to categorize
/// and group notifications for better user control and organization.
class NotificationChannels {
  NotificationChannels._();

  /// Returns the archetype-specific habit reminder channel ID.
  static String channelForArchetype(UserArchetype archetype) {
    return '${archetype.name}_habits';
  }

  /// General habit reminders channel
  static const String habitReminders = 'habit_reminders';

  /// Streak at risk warnings channel
  static const String streakWarnings = 'streak_warnings';

  /// Daily AI insights and recommendations channel
  static const String aiInsights = 'ai_insights';

  /// Community and tribe updates channel
  static const String communityUpdates = 'community_updates';

  /// Rewards, achievements, and level-ups channel
  static const String rewards = 'rewards';

  /// Weekly recap and progress summaries channel
  static const String weeklyRecap = 'weekly_recap';
}

/// Icon mappings for archetype-themed notifications.
///
/// Provides the icon asset name for each archetype to use in
/// notification display, ensuring visual consistency with the user's
/// chosen identity throughout the app.
class NotificationIcons {
  NotificationIcons._();

  /// Maps each archetype to its corresponding icon asset name.
  static const Map<UserArchetype, String> archetypeIcons = {
    UserArchetype.athlete: 'icon_athlete',
    UserArchetype.scholar: 'icon_scholar',
    UserArchetype.creator: 'icon_creator',
    UserArchetype.stoic: 'icon_stoic',
    UserArchetype.zealot: 'icon_zealot',
    UserArchetype.none: 'icon_default',
  };
}
