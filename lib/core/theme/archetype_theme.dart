import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Centralized archetype theming for consistent identity experience
/// Provides colors, icons, copy, and suggested habits per archetype
class ArchetypeTheme {
  final UserArchetype archetype;
  final String archetypeName;
  final String tagline;
  final String dailyMantra;
  final String journeyName;
  final Color primaryColor;
  final Color accentColor;
  final List<Color> backgroundGradient;
  final IconData journeyIcon;
  final List<String> suggestedMotives;
  final List<ArchetypeHabitSuggestion> suggestedHabits;

  const ArchetypeTheme({
    required this.archetype,
    required this.archetypeName,
    required this.tagline,
    required this.dailyMantra,
    required this.journeyName,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundGradient,
    required this.journeyIcon,
    required this.suggestedMotives,
    required this.suggestedHabits,
  });

  /// Get theme for a specific archetype
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
      case UserArchetype.mystic:
        return _mysticTheme;
      case UserArchetype.none:
        return _explorerTheme;
    }
  }

  /// All available themes for selection UI
  static List<ArchetypeTheme> get allThemes => [
    _athleteTheme,
    _scholarTheme,
    _creatorTheme,
    _stoicTheme,
    _mysticTheme,
  ];

  // ============ ATHLETE ============
  static const _athleteTheme = ArchetypeTheme(
    archetype: UserArchetype.athlete,
    archetypeName: 'The Athlete',
    tagline: 'Strength through discipline',
    dailyMantra: 'Stronger every single day',
    journeyName: 'Summit Peak',
    primaryColor: EmergeColors.coral,
    accentColor: Color(0xFFFF8E72),
    backgroundGradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    journeyIcon: Icons.hiking,
    suggestedMotives: [
      'I want to feel powerful and capable',
      'I want to set an example for others',
      'I want to prove what my body can do',
      'I want more energy and vitality',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Morning Movement',
        description: '10 minutes of stretching or exercise',
        anchor: 'After waking up',
        icon: Icons.fitness_center,
      ),
      ArchetypeHabitSuggestion(
        title: 'Hydration Check',
        description: 'Drink a full glass of water',
        anchor: 'After waking up',
        icon: Icons.water_drop,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Walk',
        description: '15 minute walk to decompress',
        anchor: 'After dinner',
        icon: Icons.directions_walk,
      ),
    ],
  );

  // ============ SCHOLAR ============
  static const _scholarTheme = ArchetypeTheme(
    archetype: UserArchetype.scholar,
    archetypeName: 'The Scholar',
    tagline: 'Knowledge is power',
    dailyMantra: 'Wisdom through practice',
    journeyName: 'Knowledge Nexus',
    primaryColor: EmergeColors.violet,
    accentColor: Color(0xFFB794F6),
    backgroundGradient: [Color(0xFF1A1B2E), Color(0xFF2D2B55)],
    journeyIcon: Icons.auto_stories,
    suggestedMotives: [
      'I want to understand the world deeply',
      'I want to solve complex problems',
      'I want to never stop learning',
      'I want to share knowledge with others',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Daily Reading',
        description: 'Read 10 pages of a book',
        anchor: 'After morning coffee',
        icon: Icons.menu_book,
      ),
      ArchetypeHabitSuggestion(
        title: 'Learning Session',
        description: '20 minutes of focused study',
        anchor: 'After lunch',
        icon: Icons.school,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Reflection',
        description: 'Write 3 things you learned today',
        anchor: 'Before bed',
        icon: Icons.edit_note,
      ),
    ],
  );

  // ============ CREATOR ============
  static const _creatorTheme = ArchetypeTheme(
    archetype: UserArchetype.creator,
    archetypeName: 'The Creator',
    tagline: 'Make something today',
    dailyMantra: 'Create without fear',
    journeyName: 'Forge Garden',
    primaryColor: EmergeColors.yellow,
    accentColor: Color(0xFFFFD93D),
    backgroundGradient: [Color(0xFF2C1810), Color(0xFF3D2317)],
    journeyIcon: Icons.brush,
    suggestedMotives: [
      'I want to express myself authentically',
      'I want to build things that matter',
      'I want to leave a creative legacy',
      'I want to inspire others through my work',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Creative Morning',
        description: '15 minutes of creative work',
        anchor: 'After waking up',
        icon: Icons.palette,
      ),
      ArchetypeHabitSuggestion(
        title: 'Idea Capture',
        description: 'Write down 3 new ideas',
        anchor: 'After morning coffee',
        icon: Icons.lightbulb,
      ),
      ArchetypeHabitSuggestion(
        title: 'Ship Something',
        description: 'Complete and share one small creation',
        anchor: 'Before bed',
        icon: Icons.rocket_launch,
      ),
    ],
  );

  // ============ STOIC ============
  static const _stoicTheme = ArchetypeTheme(
    archetype: UserArchetype.stoic,
    archetypeName: 'The Stoic',
    tagline: 'Master your mind',
    dailyMantra: 'Control what you can',
    journeyName: 'Ancient Path',
    primaryColor: EmergeColors.teal,
    accentColor: Color(0xFF4DD4AC),
    backgroundGradient: [Color(0xFF0D1B1E), Color(0xFF1A3B3E)],
    journeyIcon: Icons.self_improvement,
    suggestedMotives: [
      'I want inner peace and clarity',
      'I want to respond, not react',
      'I want to be unshakeable',
      'I want to live with intention',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Morning Meditation',
        description: '5 minutes of silent reflection',
        anchor: 'After waking up',
        icon: Icons.spa,
      ),
      ArchetypeHabitSuggestion(
        title: 'Stoic Journaling',
        description: 'Write about what you control',
        anchor: 'After morning coffee',
        icon: Icons.edit,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Review',
        description: 'Reflect on your reactions today',
        anchor: 'Before bed',
        icon: Icons.nights_stay,
      ),
    ],
  );

  // ============ MYSTIC ============
  static const _mysticTheme = ArchetypeTheme(
    archetype: UserArchetype.mystic,
    archetypeName: 'The Mystic',
    tagline: 'Trust the journey',
    dailyMantra: 'Everything is connected',
    journeyName: 'Ethereal Realm',
    primaryColor: Color(0xFF8E44AD),
    accentColor: Color(0xFFBB6BD9),
    backgroundGradient: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
    journeyIcon: Icons.auto_awesome,
    suggestedMotives: [
      'I want to connect with something greater',
      'I want to trust my intuition',
      'I want to find meaning in everything',
      'I want to cultivate wonder',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Morning Intention',
        description: 'Set your intention for the day',
        anchor: 'After waking up',
        icon: Icons.flare,
      ),
      ArchetypeHabitSuggestion(
        title: 'Gratitude Practice',
        description: 'Write 3 things you\'re grateful for',
        anchor: 'After morning coffee',
        icon: Icons.favorite,
      ),
      ArchetypeHabitSuggestion(
        title: 'Dream Journaling',
        description: 'Record your dreams and insights',
        anchor: 'After waking up',
        icon: Icons.cloud,
      ),
    ],
  );

  // ============ EXPLORER (Default/None) ============
  static const _explorerTheme = ArchetypeTheme(
    archetype: UserArchetype.none,
    archetypeName: 'The Explorer',
    tagline: 'Discover your path',
    dailyMantra: 'Every day is a new adventure',
    journeyName: 'Explorer\'s Journey',
    primaryColor: EmergeColors.teal,
    accentColor: Color(0xFF64FFDA),
    backgroundGradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    journeyIcon: Icons.explore,
    suggestedMotives: [
      'I want to find my true calling',
      'I want to try new things',
      'I want to grow in all areas',
      'I want to become my best self',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Morning Routine',
        description: 'A simple 5-minute morning ritual',
        anchor: 'After waking up',
        icon: Icons.wb_sunny,
      ),
      ArchetypeHabitSuggestion(
        title: 'Daily Learning',
        description: 'Learn one new thing',
        anchor: 'After lunch',
        icon: Icons.psychology,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Wind-Down',
        description: '10 minutes to decompress',
        anchor: 'Before bed',
        icon: Icons.bedtime,
      ),
    ],
  );
}

/// A suggested habit for an archetype during onboarding
class ArchetypeHabitSuggestion {
  final String title;
  final String description;
  final String anchor;
  final IconData icon;

  const ArchetypeHabitSuggestion({
    required this.title,
    required this.description,
    required this.anchor,
    required this.icon,
  });
}
