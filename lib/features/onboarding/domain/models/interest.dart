import 'package:flutter/material.dart';

/// Top-level categorization of user-selected interests. Drives both the
/// onboarding picker UI and the cross-archetype habit lookup that the
/// personalization ranking uses.
enum InterestCategory {
  movement('movement.'),
  learning('learning.'),
  creativity('creativity.'),
  mindfulness('mindfulness.'),
  faith('faith.'),
  nutrition('nutrition.');

  final String idPrefix;
  const InterestCategory(this.idPrefix);

  String get displayName {
    switch (this) {
      case InterestCategory.movement:
        return 'Movement';
      case InterestCategory.learning:
        return 'Learning';
      case InterestCategory.creativity:
        return 'Creativity';
      case InterestCategory.mindfulness:
        return 'Mindfulness';
      case InterestCategory.faith:
        return 'Faith';
      case InterestCategory.nutrition:
        return 'Nutrition';
    }
  }
}

/// One selectable interest within a category. The `id` is namespaced
/// (`<categoryId>.<slug>`) so personalization joins stay stable across
/// catalog renames.
class Interest {
  final String id;
  final String label;
  final InterestCategory category;
  final IconData icon;

  const Interest({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
  });

  /// Curated starter catalog. ~24 entries, 3-5 per category.
  /// Hand-picked, not user-authored; new entries require code review.
  static const List<Interest> catalog = [
    // Movement (5)
    Interest(
      id: 'movement.walking',
      label: 'Walking',
      category: InterestCategory.movement,
      icon: Icons.directions_walk,
    ),
    Interest(
      id: 'movement.running',
      label: 'Running',
      category: InterestCategory.movement,
      icon: Icons.directions_run,
    ),
    Interest(
      id: 'movement.strength',
      label: 'Strength Training',
      category: InterestCategory.movement,
      icon: Icons.fitness_center,
    ),
    Interest(
      id: 'movement.yoga',
      label: 'Yoga & Mobility',
      category: InterestCategory.movement,
      icon: Icons.self_improvement,
    ),
    Interest(
      id: 'movement.outdoors',
      label: 'Outdoor Adventure',
      category: InterestCategory.movement,
      icon: Icons.terrain,
    ),

    // Learning (5)
    Interest(
      id: 'learning.reading',
      label: 'Reading',
      category: InterestCategory.learning,
      icon: Icons.menu_book,
    ),
    Interest(
      id: 'learning.languages',
      label: 'Languages',
      category: InterestCategory.learning,
      icon: Icons.translate,
    ),
    Interest(
      id: 'learning.skills',
      label: 'New Skills',
      category: InterestCategory.learning,
      icon: Icons.school,
    ),
    Interest(
      id: 'learning.focus',
      label: 'Deep Focus',
      category: InterestCategory.learning,
      icon: Icons.psychology,
    ),
    Interest(
      id: 'learning.curiosity',
      label: 'Curiosity & Discovery',
      category: InterestCategory.learning,
      icon: Icons.travel_explore,
    ),

    // Creativity (4)
    Interest(
      id: 'creativity.writing',
      label: 'Writing',
      category: InterestCategory.creativity,
      icon: Icons.edit_note,
    ),
    Interest(
      id: 'creativity.art',
      label: 'Visual Art',
      category: InterestCategory.creativity,
      icon: Icons.palette,
    ),
    Interest(
      id: 'creativity.music',
      label: 'Music',
      category: InterestCategory.creativity,
      icon: Icons.music_note,
    ),
    Interest(
      id: 'creativity.making',
      label: 'Building & Making',
      category: InterestCategory.creativity,
      icon: Icons.handyman,
    ),

    // Mindfulness (3)
    Interest(
      id: 'mindfulness.meditation',
      label: 'Meditation',
      category: InterestCategory.mindfulness,
      icon: Icons.spa,
    ),
    Interest(
      id: 'mindfulness.journaling',
      label: 'Journaling',
      category: InterestCategory.mindfulness,
      icon: Icons.book,
    ),
    Interest(
      id: 'mindfulness.breathwork',
      label: 'Breathwork',
      category: InterestCategory.mindfulness,
      icon: Icons.air,
    ),

    // Faith (4)
    Interest(
      id: 'faith.prayer',
      label: 'Prayer',
      category: InterestCategory.faith,
      icon: Icons.volunteer_activism,
    ),
    Interest(
      id: 'faith.scripture',
      label: 'Scripture Reading',
      category: InterestCategory.faith,
      icon: Icons.auto_stories,
    ),
    Interest(
      id: 'faith.devotional',
      label: 'Daily Devotional',
      category: InterestCategory.faith,
      icon: Icons.menu_book_outlined,
    ),
    Interest(
      id: 'faith.community',
      label: 'Faith Community',
      category: InterestCategory.faith,
      icon: Icons.diversity_3,
    ),

    // Nutrition (3)
    Interest(
      id: 'nutrition.hydration',
      label: 'Hydration',
      category: InterestCategory.nutrition,
      icon: Icons.water_drop,
    ),
    Interest(
      id: 'nutrition.cooking',
      label: 'Home Cooking',
      category: InterestCategory.nutrition,
      icon: Icons.restaurant,
    ),
    Interest(
      id: 'nutrition.wholefoods',
      label: 'Whole Foods',
      category: InterestCategory.nutrition,
      icon: Icons.eco,
    ),
  ];

  /// Lookup by namespaced id. Returns null if the id is unknown.
  static Interest? fromId(String id) {
    for (final interest in catalog) {
      if (interest.id == id) return interest;
    }
    return null;
  }
}
