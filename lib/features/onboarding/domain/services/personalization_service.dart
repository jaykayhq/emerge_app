import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

extension UserArchetypeExtension on UserArchetype {
  String get title {
    switch (this) {
      case UserArchetype.athlete:
        return 'The Athlete';
      case UserArchetype.creator:
        return 'The Creator';
      case UserArchetype.scholar:
        return 'The Scholar';
      case UserArchetype.stoic:
        return 'The Stoic';
      case UserArchetype.mystic:
        return 'The Mystic';
      case UserArchetype.none:
        return 'Undecided';
    }
  }

  String get description {
    switch (this) {
      case UserArchetype.athlete:
        return 'Physical discipline, resilience, and vitality.';
      case UserArchetype.creator:
        return 'Imagination, expression, and bringing ideas to life.';
      case UserArchetype.scholar:
        return 'Knowledge, curiosity, and intellectual growth.';
      case UserArchetype.stoic:
        return 'Mindfulness, emotional control, and inner peace.';
      case UserArchetype.mystic:
        return 'Spiritual connection, transcendence, and inner wisdom.';
      case UserArchetype.none:
        return 'Select an archetype to begin.';
    }
  }

  String get imageUrl {
    // Placeholder URLs or asset paths
    switch (this) {
      case UserArchetype.athlete:
        return 'assets/images/archetype_athlete.png';
      case UserArchetype.creator:
        return 'assets/images/archetype_creator.png';
      case UserArchetype.scholar:
        return 'assets/images/archetype_scholar.png';
      case UserArchetype.stoic:
        return 'assets/images/archetype_stoic.png';
      case UserArchetype.mystic:
        return 'assets/images/archetype_mystic.png';
      case UserArchetype.none:
        return 'assets/images/logo.png';
    }
  }
}

class PersonalizationService {
  List<String> getSuggestedHabits(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return [
          'Morning Stretch',
          'Drink 1L Water',
          '30 Min Workout',
          'Protein Breakfast',
        ];
      case UserArchetype.creator:
        return [
          'Morning Pages',
          'Deep Work Block',
          'Capture Ideas',
          'Read for Inspiration',
        ];
      case UserArchetype.scholar:
        return [
          'Read 10 Pages',
          'Learn New Word',
          'Study Session',
          'Review Notes',
        ];
      case UserArchetype.stoic:
        return [
          'Meditate 10 Mins',
          'Journal Reflection',
          'Cold Shower',
          'Gratitude Log',
        ];
      case UserArchetype.mystic:
        return [
          'Morning Prayer',
          'Sacred Reading',
          'Mindful Breathing',
          'Evening Reflection',
        ];
      case UserArchetype.none:
        return [];
    }
  }
}
