import 'package:flutter/material.dart';
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
      ArchetypeHabitSuggestion(
        title: 'Morning Sprints',
        description: '3 high-intensity runs',
        anchor: 'After coffee',
        icon: Icons.run_circle,
      ),
      ArchetypeHabitSuggestion(
        title: 'Hydration Goal',
        description: '3L of water daily',
        anchor: 'Throughout the day',
        icon: Icons.water_drop,
      ),
      ArchetypeHabitSuggestion(
        title: 'Sleep Routine',
        description: '7-8 hours of rest',
        anchor: 'Before 11pm',
        icon: Icons.bedtime,
      ),
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
      ArchetypeHabitSuggestion(
        title: 'Deep Reading',
        description: '20 pages of a non-fiction book',
        anchor: 'Evening cool-down',
        icon: Icons.menu_book,
      ),
      ArchetypeHabitSuggestion(
        title: 'Daily Digest',
        description: 'Summarize one new concept',
        anchor: 'After lunch',
        icon: Icons.summarize,
      ),
      ArchetypeHabitSuggestion(
        title: 'Curiosity Log',
        description: 'Write down one question to research',
        anchor: 'During morning coffee',
        icon: Icons.psychology,
      ),
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
      ArchetypeHabitSuggestion(
        title: 'Daily Sketch/Draft',
        description: '15 mins of pure creation',
        anchor: 'First thing in morning',
        icon: Icons.edit,
      ),
      ArchetypeHabitSuggestion(
        title: 'Inspiration Walk',
        description: 'Observe patterns in nature',
        anchor: 'After work',
        icon: Icons.brush,
      ),
      ArchetypeHabitSuggestion(
        title: 'Portfolio Update',
        description: 'Document one small win',
        anchor: 'Friday afternoon',
        icon: Icons.auto_fix_high,
      ),
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
      ArchetypeHabitSuggestion(
        title: 'Negative Visualization',
        description: 'Meditate on potential obstacles',
        anchor: 'During commute',
        icon: Icons.self_improvement,
      ),
      ArchetypeHabitSuggestion(
        title: 'Discomfort Training',
        description: 'Take a cold shower',
        anchor: 'After gym',
        icon: Icons.ac_unit,
      ),
      ArchetypeHabitSuggestion(
        title: 'Evening Review',
        description: 'What did I do well? What could be better?',
        anchor: 'Before sleep',
        icon: Icons.event_note,
      ),
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
      ArchetypeHabitSuggestion(
        title: 'Morning Prayer',
        description: 'Communion before the world wakes',
        anchor: 'Sunrise',
        icon: Icons.wb_sunny,
      ),
      ArchetypeHabitSuggestion(
        title: 'Sacred Reading',
        description: 'Internalize the timeless wisdom',
        anchor: 'After morning coffee',
        icon: Icons.auto_stories,
      ),
      ArchetypeHabitSuggestion(
        title: 'Dhikr / Contemplation',
        description: 'Constant awareness of the Divine',
        anchor: 'Between tasks',
        icon: Icons.spa,
      ),
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
    assetPath: 'assets/images/emerge_icon.png',
    avatarBasePath: 'assets/images/avatars/base/athlete',
    avatarEvolvedPath: null,
    suggestedMotives: const ['I want to explore', 'I want to find my path'],
    suggestedHabits: const [
      ArchetypeHabitSuggestion(
        title: 'Walk',
        description: 'Go for a walk',
        anchor: 'After lunch',
        icon: Icons.directions_walk,
      ),
    ],
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

  const ArchetypeHabitSuggestion({
    required this.title,
    required this.description,
    required this.anchor,
    required this.icon,
  });
}

/// Unified color system for archetypes
/// Used across world map, profile, and synergy cards
class ArchetypeColors {
  const ArchetypeColors({
    required this.primary,
    required this.accent,
    required this.attributes,
  });

  final Color primary;
  final Color accent;
  final List<String> attributes; // Attribute names that use this archetype's theming

  static const Map<String, ArchetypeColors> all = {
    'athlete': ArchetypeColors(
      primary: Color(0xFFFF5252),
      accent: Color(0xFFFF8A80),
      attributes: ['strength', 'vitality'],
    ),
    'scholar': ArchetypeColors(
      primary: Color(0xFFE040FB),
      accent: Color(0xFFEA80FC),
      attributes: ['intellect', 'focus'],
    ),
    'creator': ArchetypeColors(
      primary: Color(0xFF76FF03),
      accent: Color(0xFFB0FF57),
      attributes: ['creativity', 'vitality'],
    ),
    'stoic': ArchetypeColors(
      primary: Color(0xFF00E5FF),
      accent: Color(0xFF80D8FF),
      attributes: ['focus', 'spirit'],
    ),
    'zealot': ArchetypeColors(
      primary: Color(0xFFFFAB00),
      accent: Color(0xFFFFD54F),
      attributes: ['spirit', 'strength'],
    ),
    'explorer': ArchetypeColors(
      primary: Color(0xFF2BEE79),
      accent: Color(0xFF7EFFAC),
      attributes: ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'],
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
