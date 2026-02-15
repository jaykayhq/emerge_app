import 'package:flutter/material.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';

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

  // Colors are now handled by getters that return IdentityThemeExtension per mode
  final IdentityThemeExtension lightColors;
  final IdentityThemeExtension darkColors;

  // Asset path for the archetype portrait
  final String assetPath;

  const ArchetypeTheme({
    required this.archetype,
    required this.archetypeName,
    required this.tagline,
    required this.dailyMantra,
    required this.journeyName,
    required this.journeyIcon,
    required this.suggestedMotives,
    required this.suggestedHabits,
    required this.lightColors,
    required this.darkColors,
    required this.assetPath,
  });

  // Backward compatibility getters (Default to Dark/Canonical identity)
  Color get primaryColor => darkColors.primaryColor;
  Color get accentColor => darkColors.accentColor;
  List<Color> get backgroundGradient => darkColors.backgroundGradient;

  /// All available themes for selection UI
  static List<ArchetypeTheme> get allThemes => [
    _athleteTheme,
    _scholarTheme,
    _creatorTheme,
    _stoicTheme,
    _mysticTheme,
  ];

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

  // ============ ATHLETE ============
  static final _athleteTheme = ArchetypeTheme(
    archetype: UserArchetype.athlete,
    archetypeName: 'The Athlete',
    tagline: 'Strength through discipline',
    dailyMantra: 'Stronger every single day',
    journeyName: 'Summit Peak',
    journeyIcon: Icons.hiking,
    assetPath: 'assets/images/archetype_athlete.png',
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
        title: 'Power Workout',
        description: '30 minute strength training',
        anchor: 'After work',
        icon: Icons.sports_gymnastics,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Walk',
        description: '15 minute walk to decompress',
        anchor: 'After dinner',
        icon: Icons.directions_walk,
      ),
    ],
    // Dark Mode (Tokyo Night/Original)
    darkColors: IdentityThemeExtension(
      primaryColor: EmergeColors.coral,
      accentColor: Color(0xFFFF8E72),
      backgroundGradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Athlete',
    ),
    // Light Mode (Clean, High Energy)
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFFE63946), // Vibrant Red
      accentColor: Color(0xFFF77F00), // Energetic Orange
      backgroundGradient: [Color(0xFFFFF1F2), Color(0xFFFFDDD2)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF1D3557),
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
    suggestedMotives: [
      'I want to understand the world deeply',
      'I want to solve complex problems',
      'I want to never stop learning',
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
        title: 'Podcast Learning',
        description: 'Listen to educational content',
        anchor: 'During commute',
        icon: Icons.podcasts,
      ),
    ],
    // Dark Mode
    darkColors: IdentityThemeExtension(
      primaryColor: EmergeColors.violet,
      accentColor: Color(0xFFB794F6),
      backgroundGradient: [Color(0xFF1A1B2E), Color(0xFF2D2B55)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Scholar',
    ),
    // Light Mode (Academic, Paper-like)
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFF4361EE), // Intellectual Blue
      accentColor: Color(0xFF3F37C9),
      backgroundGradient: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF212529),
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
    suggestedMotives: [
      'I want to explore my creativity',
      'I want to build a portfolio',
      'I want to express myself',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Daily Sketch',
        description: 'Draw something for 5 minutes',
        anchor: 'After dinner',
        icon: Icons.brush,
      ),
      ArchetypeHabitSuggestion(
        title: 'Idea Capture',
        description: 'Write down 3 new ideas',
        anchor: 'After morning coffee',
        icon: Icons.lightbulb,
      ),
      ArchetypeHabitSuggestion(
        title: 'Ship Something',
        description: 'Complete and share one creation',
        anchor: 'Before bed',
        icon: Icons.rocket_launch,
      ),
    ],
    // Dark Mode
    darkColors: IdentityThemeExtension(
      primaryColor: EmergeColors.yellow,
      accentColor: Color(0xFFFFD93D),
      backgroundGradient: [Color(0xFF2C1810), Color(0xFF3D2317)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Creator',
    ),
    // Light Mode (Studio, Bright)
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFFFB8500), // Creative Orange
      accentColor: Color(0xFFFFB703),
      backgroundGradient: [Color(0xFFFFFBEB), Color(0xFFFFF3C4)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF370617),
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
    suggestedMotives: [
      'I want to be calm',
      'I want to be in control',
      'I want to be strong',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Meditation',
        description: 'Meditate for 10 minutes',
        anchor: 'After waking up',
        icon: Icons.self_improvement,
      ),
      ArchetypeHabitSuggestion(
        title: 'Gratitude Journal',
        description: 'Write 3 things you are grateful for',
        anchor: 'Before bed',
        icon: Icons.favorite,
      ),
      ArchetypeHabitSuggestion(
        title: 'Digital Sunset',
        description: 'No screens 1 hour before bed',
        anchor: 'Before bed',
        icon: Icons.phone_disabled,
      ),
    ],
    // Dark Mode
    darkColors: IdentityThemeExtension(
      primaryColor: EmergeColors.teal,
      accentColor: Color(0xFF4DD4AC),
      backgroundGradient: [Color(0xFF0D1B1E), Color(0xFF1A3B3E)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Stoic',
    ),
    // Light Mode (Marble, Minimal)
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFF2A9D8F), // Calm Teal
      accentColor: Color(0xFF264653),
      backgroundGradient: [Color(0xFFF1FAEE), Color(0xFFA8DADC)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF1D3557),
      archetypeName: 'The Stoic',
    ),
  );

  // ============ MYSTIC ============
  static final _mysticTheme = ArchetypeTheme(
    archetype: UserArchetype.mystic,
    archetypeName: 'The Mystic',
    tagline: 'Trust the journey',
    dailyMantra: 'Everything is connected',
    journeyName: 'Ethereal Realm',
    journeyIcon: Icons.auto_awesome,
    assetPath: 'assets/images/archetype_mystic.png',
    suggestedMotives: [
      'I want to find meaning',
      'I want to connect with the universe',
      'I want to explore the unknown',
    ],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Stargazing',
        description: 'Look at the stars',
        anchor: 'Before bed',
        icon: Icons.star,
      ),
      ArchetypeHabitSuggestion(
        title: 'Morning Meditation',
        description: '5 minutes of silent reflection',
        anchor: 'After waking up',
        icon: Icons.spa,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Reflection',
        description: 'Review your day mindfully',
        anchor: 'Before bed',
        icon: Icons.nights_stay,
      ),
    ],
    // Dark Mode
    darkColors: IdentityThemeExtension(
      primaryColor: Color(0xFF8E44AD),
      accentColor: Color(0xFFBB6BD9),
      backgroundGradient: [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Mystic',
    ),
    // Light Mode (Ethereal, Lavender)
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFF7209B7), // Deep Purple
      accentColor: Color(0xFFB5179E),
      backgroundGradient: [Color(0xFFF3E8FF), Color(0xFFE0C3FC)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF3C096C),
      archetypeName: 'The Mystic',
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
    assetPath: 'assets/images/emerge_icon.png', // Fallback
    suggestedMotives: ['I want to explore', 'I want to find my path'],
    suggestedHabits: [
      ArchetypeHabitSuggestion(
        title: 'Walk',
        description: 'Go for a walk',
        anchor: 'After lunch',
        icon: Icons.directions_walk,
      ),
      ArchetypeHabitSuggestion(
        title: 'Morning Planning',
        description: 'Set top 3 priorities for today',
        anchor: 'After waking up',
        icon: Icons.checklist,
      ),
      ArchetypeHabitSuggestion(
        title: 'Breathing Exercise',
        description: '5 deep breaths to reset',
        anchor: 'Before meetings',
        icon: Icons.air,
      ),
    ],
    // Dark Mode
    darkColors: IdentityThemeExtension(
      primaryColor: EmergeColors.teal,
      accentColor: Color(0xFF64FFDA),
      backgroundGradient: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      surfaceColor: Color(0xFF24283b),
      textColor: Color(0xFFc0caf5),
      archetypeName: 'The Explorer',
    ),
    // Light Mode
    lightColors: IdentityThemeExtension(
      primaryColor: Color(0xFF118AB2),
      accentColor: Color(0xFF06D6A0),
      backgroundGradient: [Color(0xFFF0F4F8), Color(0xFFD9E2EC)],
      surfaceColor: Colors.white,
      textColor: Color(0xFF102A43),
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

  const ArchetypeHabitSuggestion({
    required this.title,
    required this.description,
    required this.anchor,
    required this.icon,
  });
}
