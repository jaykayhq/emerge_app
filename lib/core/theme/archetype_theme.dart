import 'package:flutter/material.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Extension to access identity colors in the theme
class IdentityThemeExtension extends ThemeExtension<IdentityThemeExtension> {
  final Color primaryColor;
  final Color accentColor;
  final List<Color> backgroundGradient;
  final Color surfaceColor;
  final Color textColor;
  final String archetypeName;

  const IdentityThemeExtension({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundGradient,
    required this.surfaceColor,
    required this.textColor,
    required this.archetypeName,
  });

  @override
  ThemeExtension<IdentityThemeExtension> copyWith({
    Color? primaryColor,
    Color? accentColor,
    List<Color>? backgroundGradient,
    Color? surfaceColor,
    Color? textColor,
    String? archetypeName,
  }) {
    return IdentityThemeExtension(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      archetypeName: archetypeName ?? this.archetypeName,
    );
  }

  @override
  ThemeExtension<IdentityThemeExtension> lerp(
    covariant ThemeExtension<IdentityThemeExtension>? other,
    double t,
  ) {
    if (other is! IdentityThemeExtension) {
      return this;
    }
    return IdentityThemeExtension(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      backgroundGradient: [
        Color.lerp(backgroundGradient[0], other.backgroundGradient[0], t)!,
        Color.lerp(backgroundGradient[1], other.backgroundGradient[1], t)!,
      ],
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      archetypeName: other.archetypeName,
    );
  }
}

/// Centralized archetype theming for consistent identity experience
class ArchetypeTheme {
  final UserArchetype archetype;
  final String archetypeName;
  final String tagline;
  final String dailyMantra;
  final String journeyName;
  final IconData journeyIcon;
  final List<String> suggestedMotives;
  final List<ArchetypeHabitSuggestion> suggestedHabits;
  final List<String> strengths;
  final List<String> weaknesses;
  final String habitLoop;

  final IdentityThemeExtension lightColors;
  final IdentityThemeExtension darkColors;

  final String assetPath;
  final String avatarBasePath;
  final String? avatarEvolvedPath;

  const ArchetypeTheme({
    required this.archetype,
    required this.archetypeName,
    required this.tagline,
    required this.dailyMantra,
    required this.journeyName,
    required this.journeyIcon,
    required this.suggestedMotives,
    required this.suggestedHabits,
    required this.strengths,
    required this.weaknesses,
    required this.habitLoop,
    required this.lightColors,
    required this.darkColors,
    required this.assetPath,
    this.avatarBasePath = 'assets/images/avatars/base',
    this.avatarEvolvedPath,
  });

  Color get primaryColor => darkColors.primaryColor;
  Color get accentColor => darkColors.accentColor;
  List<Color> get backgroundGradient => darkColors.backgroundGradient;

  String get emoji {
    switch (archetype) {
      case UserArchetype.athlete: return '🏃‍➡️';
      case UserArchetype.creator: return '🖌️';
      case UserArchetype.scholar: return '📖';
      case UserArchetype.stoic: return '🧘';
      case UserArchetype.zealot: return '🔥'; // zealot/mystic
      case UserArchetype.none: return '✨';
    }
  }

  static List<ArchetypeTheme> get allThemes => [
    _athleteTheme,
    _scholarTheme,
    _creatorTheme,
    _stoicTheme,
    _zealotTheme,
  ];

  static ArchetypeTheme forArchetype(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return _athleteTheme;
      case UserArchetype.scholar:
        return _scholarTheme;
      case UserArchetype.creator:
        return _creatorTheme;
      case UserArchetype.stoic:
        return _stoicTheme;
      case UserArchetype.zealot:
        return _zealotTheme;
      case UserArchetype.none:
        return _explorerTheme;
    }
  }

  // ============ ATHLETE ============
  static final _athleteTheme = ArchetypeTheme(
    archetype: UserArchetype.athlete,
    archetypeName: 'The Athlete',
    tagline: 'Strength through discipline',
    dailyMantra: 'Stronger every single day',
    journeyName: 'Summit Peak',
    journeyIcon: Icons.hiking,
    assetPath: 'assets/images/archetype_athlete.png',
    avatarBasePath: 'assets/images/avatars/base/athlete',
    avatarEvolvedPath:
        'assets/images/avatars/evolved/radiant/athlete_overlay.png',
    suggestedMotives: [
      'I want to feel powerful and capable',
      'I want to set an example for others',
      'I want to prove what my body can do',
      'I want more energy and vitality',
    ],
        suggestedHabits: [
      ArchetypeHabitSuggestion(title: 'Zone 2 Cardio', description: '45 mins steady-state', anchor: 'Morning', icon: Icons.favorite, defaultTime: const TimeOfDay(hour: 6, minute: 0), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Mobility Flow', description: '15 min joint prep', anchor: 'Pre-workout', icon: Icons.accessibility_new, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Protein Tracking', description: 'Log meals', anchor: 'After meals', icon: Icons.restaurant, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Hydration Target', description: 'Drink 1 gallon', anchor: 'Throughout day', icon: Icons.water_drop, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Cold Exposure', description: '2 min cold shower', anchor: 'Morning', icon: Icons.ac_unit, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Sleep Optimization', description: 'No screens 1h before bed', anchor: 'Evening', icon: Icons.nightlight_round, defaultTime: const TimeOfDay(hour: 21, minute: 0), timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Active Recovery', description: '20 min walk', anchor: 'Rest days', icon: Icons.directions_walk, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Grip Training', description: 'Farmer carries', anchor: 'Gym finish', icon: Icons.fitness_center, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Breathwork', description: 'Box breathing (5 mins)', anchor: 'Pre-sleep', icon: Icons.air, defaultTime: const TimeOfDay(hour: 21, minute: 30), timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Sprint Intervals', description: 'HIIT session', anchor: 'Weekend', icon: Icons.run_circle, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Sunlight Viewing', description: '10 min morning sun', anchor: 'Wake up', icon: Icons.wb_sunny, defaultTime: const TimeOfDay(hour: 7, minute: 0), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Meal Prep', description: 'Prep for next day', anchor: 'Evening', icon: Icons.kitchen, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Stretching', description: '10 min static stretch', anchor: 'Post-workout', icon: Icons.boy, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Core Stability', description: 'Plank series', anchor: 'Morning', icon: Icons.foundation, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Vitals Log', description: 'Record resting HR/HRV', anchor: 'Wake up', icon: Icons.monitor_heart, timeOfDayPreference: TimeOfDayPreference.morning),
    ],
    strengths: [
      'High physical energy',
      'Disciplined consistency',
      'Goal-oriented focus',
    ],
    weaknesses: [
      'Risk of burnout',
      'Over-emphasis on metrics',
      'Impatience with slow progress',
    ],
    habitLoop:
        'Action triggers Endorphins, reinforcing Identity as an Elite Performer.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFFFF5252),
      accentColor: const Color(0xFFFF8E72),
      backgroundGradient: const [Color(0xFF1A1A2E), Color(0xFF16213E)],
      surfaceColor: const Color(0xFF193324),
      textColor: const Color(0xFFc0caf5),
      archetypeName: 'The Athlete',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFFE63946),
      accentColor: const Color(0xFFF77F00),
      backgroundGradient: const [Color(0xFFFFF1F2), Color(0xFFFFDDD2)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF1D3557),
      archetypeName: 'The Athlete',
    ),
  );

  // ============ SCHOLAR ============
  static final _scholarTheme = ArchetypeTheme(
    archetype: UserArchetype.scholar,
    archetypeName: 'The Scholar',
    tagline: 'Knowledge is power',
    dailyMantra: 'Wisdom through practice',
    journeyName: 'Knowledge Nexus',
    journeyIcon: Icons.auto_stories,
    assetPath: 'assets/images/archetype_scholar.png',
    avatarBasePath: 'assets/images/avatars/base/scholar',
    avatarEvolvedPath:
        'assets/images/avatars/evolved/radiant/scholar_overlay.png',
    suggestedMotives: [
      'I want to understand the world deeply',
      'I want to solve complex problems',
      'I want to never stop learning',
    ],
        suggestedHabits: [
      ArchetypeHabitSuggestion(title: 'Morning Pages', description: 'Stream of consciousness', anchor: 'Wake up', icon: Icons.edit_note, defaultTime: const TimeOfDay(hour: 7, minute: 0), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Deep Work Block', description: '90 mins undistracted', anchor: 'Morning', icon: Icons.psychology, defaultTime: const TimeOfDay(hour: 9, minute: 0), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Ship Something', description: 'Publish one small thing', anchor: 'End of day', icon: Icons.rocket_launch, defaultTime: const TimeOfDay(hour: 17, minute: 0), timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Idea Capture', description: 'Log 3 new ideas', anchor: 'Lunchtime', icon: Icons.lightbulb, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Visual Journal', description: 'One sketch or photo', anchor: 'Evening', icon: Icons.camera_alt, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Tool Sharpening', description: 'Learn one shortcut', anchor: 'Start of work', icon: Icons.build, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Analog Hour', description: 'No digital devices', anchor: 'After dinner', icon: Icons.nature_people, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Swipe File', description: 'Save 1 piece of inspiration', anchor: 'Morning coffee', icon: Icons.folder_special, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Drafting Phase', description: '30 mins rough draft', anchor: 'Morning', icon: Icons.drafts, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Refining Phase', description: '30 mins editing', anchor: 'Afternoon', icon: Icons.auto_fix_high, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Cross-pollinate', description: 'Read outside your field', anchor: 'Evening', icon: Icons.explore, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Feedback Request', description: 'Share work-in-progress', anchor: 'Weekly', icon: Icons.forum, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Skill Practice', description: '15 mins deliberate practice', anchor: 'Daily', icon: Icons.handyman, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Workspace Reset', description: 'Clear desk', anchor: 'End of work', icon: Icons.cleaning_services, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Ugly First Draft', description: 'Just write, no edits', anchor: 'Morning', icon: Icons.create, timeOfDayPreference: TimeOfDayPreference.morning),
    ],
    strengths: [
      'Deep analytical thinking',
      'Vast knowledge base',
      'Methodical problem solving',
    ],
    weaknesses: [
      'Analysis paralysis',
      'Detachment from physical action',
      'Intellectual perfectionism',
    ],
    habitLoop:
        'Discovery triggers Aha-moments, reinforcing Identity as a Master Learner.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF7C3AED),
      accentColor: const Color(0xFFB794F6),
      backgroundGradient: const [Color(0xFF1A1B2E), Color(0xFF2D2B55)],
      surfaceColor: const Color(0xFF193324),
      textColor: const Color(0xFFc0caf5),
      archetypeName: 'The Scholar',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF4361EE),
      accentColor: const Color(0xFF3F37C9),
      backgroundGradient: const [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF212529),
      archetypeName: 'The Scholar',
    ),
  );

  // ============ CREATOR ============
  static final _creatorTheme = ArchetypeTheme(
    archetype: UserArchetype.creator,
    archetypeName: 'The Creator',
    tagline: 'Make something today',
    dailyMantra: 'Create without fear',
    journeyName: 'Forge Garden',
    journeyIcon: Icons.brush,
    assetPath: 'assets/images/archetype_creator.png',
    avatarBasePath: 'assets/images/avatars/base/creator',
    avatarEvolvedPath:
        'assets/images/avatars/evolved/radiant/creator_overlay.png',
    suggestedMotives: [
      'I want to explore my creativity',
      'I want to build a portfolio',
      'I want to express myself',
    ],
        suggestedHabits: [
      ArchetypeHabitSuggestion(title: 'Syntopic Reading', description: 'Read 2 sources on 1 topic', anchor: 'Evening', icon: Icons.library_books, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Feynman Technique', description: 'Explain a concept simply', anchor: 'After reading', icon: Icons.record_voice_over, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Spaced Repetition', description: 'Anki/Flashcards', anchor: 'Morning transit', icon: Icons.layers, defaultTime: const TimeOfDay(hour: 8, minute: 0), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Zettelkasten', description: 'Process 3 notes', anchor: 'Evening', icon: Icons.note_add, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Primary Sources', description: 'Read original text', anchor: 'Deep work', icon: Icons.account_balance, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Vocabulary Expansion', description: 'Learn 1 new word', anchor: 'Morning', icon: Icons.sort_by_alpha, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Mental Models', description: 'Apply 1 model to life', anchor: 'Journaling', icon: Icons.extension, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Debate Prep', description: 'Argue opposite side', anchor: 'Weekly', icon: Icons.compare_arrows, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Language Practice', description: '15 mins Duo/Babbel', anchor: 'Lunchtime', icon: Icons.language, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Lecture Review', description: 'Summarize key points', anchor: 'Post-lecture', icon: Icons.summarize, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Curiosity Dive', description: '30 mins random Wikipedia', anchor: 'Weekend', icon: Icons.search, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Historical Context', description: 'Research timeline', anchor: 'Reading prep', icon: Icons.history_edu, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Mathematical Thinking', description: 'Solve 1 logic puzzle', anchor: 'Morning', icon: Icons.calculate, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Academic Writing', description: 'Write 200 words formal', anchor: 'Deep work', icon: Icons.edit_document, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Thesis Review', description: 'Review core arguments', anchor: 'Weekly', icon: Icons.fact_check, timeOfDayPreference: TimeOfDayPreference.anytime),
    ],
    strengths: [
      'Lateral thinking',
      'Expressive communication',
      'Aura of inspiration',
    ],
    weaknesses: [
      'Inconsistent routine',
      'Difficulty finishing projects',
      'Sensitivity to criticism',
    ],
    habitLoop:
        'Creation triggers Flow-state, reinforcing Identity as a Visionary Artist.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFFFFD700),
      accentColor: const Color(0xFFFFD93D),
      backgroundGradient: const [Color(0xFF2C1810), Color(0xFF3D2317)],
      surfaceColor: const Color(0xFF193324),
      textColor: const Color(0xFFc0caf5),
      archetypeName: 'The Creator',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFFFB8500),
      accentColor: const Color(0xFFFFB703),
      backgroundGradient: const [Color(0xFFFFFBEB), Color(0xFFFFF3C4)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF370617),
      archetypeName: 'The Creator',
    ),
  );

  // ============ STOIC ============
  static final _stoicTheme = ArchetypeTheme(
    archetype: UserArchetype.stoic,
    archetypeName: 'The Stoic',
    tagline: 'Master your mind',
    dailyMantra: 'Control what you can',
    journeyName: 'Ancient Path',
    journeyIcon: Icons.self_improvement,
    assetPath: 'assets/images/archetype_stoic.png',
    avatarBasePath: 'assets/images/avatars/base/stoic',
    avatarEvolvedPath:
        'assets/images/avatars/evolved/radiant/stoic_overlay.png',
    suggestedMotives: [
      'I want to be calm',
      'I want to be in control',
      'I want to be strong',
    ],
        suggestedHabits: [
      ArchetypeHabitSuggestion(title: 'Premeditatio Malorum', description: 'Negative visualization', anchor: 'Morning', icon: Icons.cloud_off, defaultTime: const TimeOfDay(hour: 6, minute: 30), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Dichotomy of Control', description: 'List what you control', anchor: 'When stressed', icon: Icons.alt_route, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Amor Fati', description: 'Embrace an obstacle', anchor: 'Daily review', icon: Icons.favorite_border, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Voluntary Hardship', description: 'Sleep on floor / fast', anchor: 'Weekly', icon: Icons.landscape, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Evening Examen', description: 'Review moral choices', anchor: 'Bedtime', icon: Icons.balance, defaultTime: const TimeOfDay(hour: 21, minute: 0), timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Memento Mori', description: 'Meditate on mortality', anchor: 'Morning', icon: Icons.hourglass_bottom, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Objective Description', description: 'Strip emotional language', anchor: 'Journaling', icon: Icons.format_clear, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'View from Above', description: 'Cosmic perspective', anchor: 'When overwhelmed', icon: Icons.public, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Temperance Check', description: 'Stop eating at 80%', anchor: 'Meals', icon: Icons.restaurant_menu, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Pause Response', description: 'Count to 5 before reacting', anchor: 'Arguments', icon: Icons.pan_tool, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Endurance Hold', description: 'Plank or wall sit', anchor: 'Workout', icon: Icons.timer, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Minimalist Day', description: 'Use only essentials', anchor: 'Monthly', icon: Icons.inventory_2, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Gratitude for Basics', description: 'Appreciate water/shelter', anchor: 'Morning', icon: Icons.water_drop, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Silence Fast', description: '1 hour no speaking', anchor: 'Evening', icon: Icons.volume_off, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Journaling (Aurelius)', description: 'Write only for yourself', anchor: 'Morning', icon: Icons.book, timeOfDayPreference: TimeOfDayPreference.morning),
    ],
    strengths: [
      'Unshakeable composure',
      'Emotional resilience',
      'Focus on the controllable',
    ],
    weaknesses: [
      'Risk of emotional suppression',
      'Perceived as distant',
      'Difficulty asking for help',
    ],
    habitLoop:
        'Endurance triggers Equanimity, reinforcing Identity as a Pillar of Strength.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF26A69A),
      accentColor: const Color(0xFF4DD4AC),
      backgroundGradient: const [Color(0xFF0D1B1E), Color(0xFF1A3B3E)],
      surfaceColor: const Color(0xFF193324),
      textColor: const Color(0xFFc0caf5),
      archetypeName: 'The Stoic',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF2A9D8F),
      accentColor: const Color(0xFF264653),
      backgroundGradient: const [Color(0xFFF1FAEE), Color(0xFFA8DADC)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF1D3557),
      archetypeName: 'The Stoic',
    ),
  );

  // ============ ZEALOT ============
  static final _zealotTheme = ArchetypeTheme(
    archetype: UserArchetype.zealot,
    archetypeName: 'The Zealot',
    tagline: 'Passion through Unwavering Faith',
    dailyMantra: 'Fire in the heart, peace in the soul.',
    journeyName: 'Sacred Path',
    journeyIcon: Icons.local_fire_department,
    assetPath: 'assets/images/archetype_zealot.png',
    avatarBasePath: 'assets/images/avatars/base/zealot',
    avatarEvolvedPath:
        'assets/images/avatars/evolved/radiant/zealot_overlay.png',
    suggestedMotives: [
      'I want to live with a deeper sense of purpose',
      'I want to cultivate radical consistency in my spiritual life',
      'I want to be a light in the world',
      'I want to master my spirit and my habits',
    ],
        suggestedHabits: [
      ArchetypeHabitSuggestion(title: 'Sacred Ritual', description: 'Morning devotion/prayer', anchor: 'Wake up', icon: Icons.self_improvement, defaultTime: const TimeOfDay(hour: 5, minute: 30), timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Fasting Block', description: '16h intermittent fast', anchor: 'Daily', icon: Icons.no_food, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Mission Alignment', description: 'Read vision statement', anchor: 'Morning', icon: Icons.flag, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Unwavering Focus', description: '2h deep work block', anchor: 'Morning', icon: Icons.center_focus_strong, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Community Service', description: '1 act of service', anchor: 'Weekly', icon: Icons.volunteer_activism, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Scripture/Text Study', description: 'Read core philosophy', anchor: 'Evening', icon: Icons.menu_book, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'High-Intensity Output', description: 'Max effort task', anchor: 'Midday', icon: Icons.bolt, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Digital Detox', description: '24h offline', anchor: 'Weekend', icon: Icons.wifi_off, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Mentor Check-in', description: 'Message accountability partner', anchor: 'Weekly', icon: Icons.people, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Purification', description: 'Sauna or sweat lodge', anchor: 'Weekend', icon: Icons.hot_tub, timeOfDayPreference: TimeOfDayPreference.anytime),
      ArchetypeHabitSuggestion(title: 'Chanting / Mantra', description: '10 min vocalization', anchor: 'Morning', icon: Icons.record_voice_over, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Vow of Simplicity', description: 'Declutter 1 item', anchor: 'Daily', icon: Icons.delete_outline, timeOfDayPreference: TimeOfDayPreference.evening),
      ArchetypeHabitSuggestion(title: 'Charismatic Speaking', description: 'Practice articulation', anchor: 'Before meetings', icon: Icons.campaign, timeOfDayPreference: TimeOfDayPreference.morning),
      ArchetypeHabitSuggestion(title: 'Zealous Defense', description: 'Argue for your cause', anchor: 'Writing', icon: Icons.shield, timeOfDayPreference: TimeOfDayPreference.afternoon),
      ArchetypeHabitSuggestion(title: 'Night Vigil', description: 'Late night reflection', anchor: 'Midnight', icon: Icons.nights_stay, timeOfDayPreference: TimeOfDayPreference.evening),
    ],
    strengths: [
      'Fervent devotion',
      'Moral clarity',
      'Inexhaustible spiritual energy',
    ],
    weaknesses: [
      'Tendency toward rigidity',
      'Risk of spiritual burnout',
      'Potential for dogmatism',
    ],
    habitLoop:
        'Devotion triggers Transcendence, reinforcing Identity as a Sacred Flame.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF991B1B),
      accentColor: const Color(0xFFB45309),
      backgroundGradient: const [Color(0xFF450A0A), Color(0xFF1E1E1E)],
      surfaceColor: const Color(0xFF2C2C2C),
      textColor: const Color(0xFFf3f4f6),
      archetypeName: 'The Zealot',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFFDC2626),
      accentColor: const Color(0xFFD97706),
      backgroundGradient: const [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF7F1D1D),
      archetypeName: 'The Zealot',
    ),
  );

  // ============ EXPLORER (Default) ============
  static final _explorerTheme = ArchetypeTheme(
    archetype: UserArchetype.none,
    archetypeName: 'The Explorer',
    tagline: 'Discover your path',
    dailyMantra: 'Every day is a new adventure',
    journeyName: 'Explorer\'s Journey',
    journeyIcon: Icons.explore,
    assetPath: 'assets/icons/app_icon.png',
    avatarBasePath: 'assets/images/avatars/base/athlete',
    avatarEvolvedPath: null,
    suggestedMotives: const [],
    suggestedHabits: const [],
    strengths: const ['Adaptability', 'Curiosity'],
    weaknesses: const ['Lack of specialization'],
    habitLoop: 'Exploration leads to variety.',
    darkColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF009688),
      accentColor: const Color(0xFF64FFDA),
      backgroundGradient: const [Color(0xFF1A1A2E), Color(0xFF16213E)],
      surfaceColor: const Color(0xFF193324),
      textColor: const Color(0xFFc0caf5),
      archetypeName: 'The Explorer',
    ),
    lightColors: IdentityThemeExtension(
      primaryColor: const Color(0xFF118AB2),
      accentColor: const Color(0xFF06D6A0),
      backgroundGradient: const [Color(0xFFF0F4F8), Color(0xFFD9E2EC)],
      surfaceColor: Colors.white,
      textColor: const Color(0xFF102A43),
      archetypeName: 'The Explorer',
    ),
  );
}

/// A suggested habit for an archetype during onboarding
class ArchetypeHabitSuggestion {
  final String title;
  final String description;
  final String anchor;
  final IconData icon;
  final TimeOfDay? defaultTime;
  final TimeOfDayPreference? timeOfDayPreference;

  const ArchetypeHabitSuggestion({
    required this.title,
    required this.description,
    required this.anchor,
    required this.icon,
    this.defaultTime,
    this.timeOfDayPreference,
  });
}

/// Unified color system for archetypes
/// Used across world map, profile, and synergy cards
/// NOTE: These colors must match ArchetypeTheme.darkColors for consistency
class ArchetypeColors {
  const ArchetypeColors({
    required this.primary,
    required this.accent,
    required this.attributes,
  });

  final Color primary;
  final Color accent;
  final List<String>
  attributes; // Attribute names that use this archetype's theming

  static const Map<String, ArchetypeColors> all = {
    'athlete': ArchetypeColors(
      primary: Color(0xFFFF5252),
      accent: Color(0xFFFF8E72),
      attributes: ['strength', 'vitality'],
    ),
    'scholar': ArchetypeColors(
      primary: Color(0xFF7C3AED),
      accent: Color(0xFFB794F6),
      attributes: ['intellect', 'focus'],
    ),
    'creator': ArchetypeColors(
      primary: Color(0xFFFFD700),
      accent: Color(0xFFFFD93D),
      attributes: ['creativity', 'vitality'],
    ),
    'stoic': ArchetypeColors(
      primary: Color(0xFF26A69A),
      accent: Color(0xFF4DD4AC),
      attributes: ['focus', 'spirit'],
    ),
    'zealot': ArchetypeColors(
      primary: Color(0xFF991B1B),
      accent: Color(0xFFB45309),
      attributes: ['spirit', 'strength'],
    ),
    'explorer': ArchetypeColors(
      primary: Color(0xFF009688),
      accent: Color(0xFF64FFDA),
      attributes: [
        'strength',
        'intellect',
        'vitality',
        'creativity',
        'focus',
        'spirit',
      ],
    ),
  };

  /// Get colors for an archetype key
  static ArchetypeColors forKey(String key) {
    return all[key.toLowerCase()] ?? all['explorer']!;
  }

  /// Get color for a specific attribute
  static Color forAttribute(String attribute) {
    for (final colors in all.values) {
      if (colors.attributes.contains(attribute.toLowerCase())) {
        return colors.primary;
      }
    }
    return all['explorer']!.primary;
  }
}
