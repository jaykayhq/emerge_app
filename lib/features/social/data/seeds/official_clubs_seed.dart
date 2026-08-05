import '../../domain/models/tribe.dart';

/// Seed data for official Emerge clubs
/// These pre-defined clubs align with the affiliate strategy archetypes
/// and should be seeded during app initialization
class OfficialClubsSeed {
  /// List of official clubs to seed in Firestore
  static const List<Map<String, dynamic>> officialClubs = [
    // ATHLETE ARCHETYPE
    {
      'name': 'Morning Warriors',
      'description':
          '5AM workouts to start your day with energy and discipline',
      'imageUrl':
          'assets/images/clubs/morning_warriors.webp',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['fitness', 'morning', 'workout', 'early-risers'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 1,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'wb_sunny',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Plant-Based Tribe',
      'description':
          'Nutrition challenges for plant-based athletes and wellness enthusiasts',
      'imageUrl':
          'assets/images/clubs/plant_based_tribe.webp',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['nutrition', 'plant-based', 'vegan', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 5,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'eco',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'HIIT Heroes',
      'description':
          'High-intensity interval training challenges for maximum burn',
      'imageUrl':
          'assets/images/clubs/hiit_heroes.webp',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 5,
      'tags': ['hiit', 'fitness', 'cardio', 'strength'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 3,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'bolt',
      'ownerId': 'emerge_official',
    },

    // SCHOLAR ARCHETYPE
    {
      'name': 'Deep Work Society',
      'description': '90-minute focus blocks for profound productivity',
      'imageUrl':
          'assets/images/clubs/deep_work_society.webp',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['productivity', 'focus', 'deep-work', 'study'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 2,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'timer',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Night Owl Readers',
      'description':
          'Reading habits and book discussions for late-night learners',
      'imageUrl':
          'assets/images/clubs/night_owl_readers.webp',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['reading', 'books', 'learning', 'night-owl'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 7,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'nightlight',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Language Learners',
      'description':
          'Daily language practice challenges with native speaker exchanges',
      'imageUrl':
          'assets/images/clubs/language_learners.webp',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 3,
      'tags': ['language', 'learning', 'polyglot', 'education'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 4,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'translate',
      'ownerId': 'emerge_official',
    },

    // STOIC ARCHETYPE
    {
      'name': 'Mindful Masters',
      'description': '21-day meditation challenges for inner peace and clarity',
      'imageUrl':
          'assets/images/clubs/mindful_masters.webp',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['meditation', 'mindfulness', 'calm', 'mental-health'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 1,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'spa',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Digital Detox Weekend',
      'description': 'Weekly screen-free challenges to reconnect with reality',
      'imageUrl':
          'assets/images/clubs/digital_detox_weekend.webp',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['digital-detox', 'mindfulness', 'balance', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 6,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'phonelink_off',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Gratitude Circle',
      'description': 'Daily gratitude journaling for positive mindset shifts',
      'imageUrl':
          'assets/images/clubs/gratitude_circle.webp',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['gratitude', 'journaling', 'positive', 'mindset'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 8,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'favorite',
      'ownerId': 'emerge_official',
    },

    // CREATOR ARCHETYPE
    {
      'name': 'Creative Collective',
      'description': 'Ship something every day - build your creative muscle',
      'imageUrl':
          'assets/images/clubs/creative_collective.webp',
      'archetypeId': 'creator',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['creativity', 'art', 'create', 'daily-practice'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 3,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'brush',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Music Practice 21',
      'description': '21-day instrument practice challenges for musicians',
      'imageUrl':
          'assets/images/clubs/music_practice_21.webp',
      'archetypeId': 'creator',
      'type': 'official',
      'levelRequirement': 3,
      'tags': ['music', 'practice', 'instrument', 'musicians'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 9,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'music_note',
      'ownerId': 'emerge_official',
    },

    // ZEALOT ARCHETYPE (Faith-Based)
    {
      'name': 'Lunar Seekers',
      'description': 'Scripture study and daily prayer for spiritual growth',
      'imageUrl':
          'assets/images/clubs/lunar_seekers.webp',
      'archetypeId': 'zealot',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['faith', 'prayer', 'scripture', 'spiritual'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 2,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'brightness_3',
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Breathwork Circle',
      'description': 'Daily breathwork and meditation for spiritual connection',
      'imageUrl':
          'assets/images/clubs/breathwork_circle.webp',
      'archetypeId': 'zealot',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['breathwork', 'meditation', 'spiritual', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 10,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'air',
      'ownerId': 'emerge_official',
    },

    // MULTI-ARCHETYPE
    {
      'name': 'Financial Freedom',
      'description': 'Money habits, savings challenges, and wealth building',
      'imageUrl':
          'assets/images/clubs/financial_freedom.webp',
      'archetypeId': null, // All archetypes
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['finance', 'money', 'savings', 'wealth'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 5,
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
      'icon': 'payments',
      'ownerId': 'emerge_official',
    },
  ];

  /// Converts seed data to Tribe objects for Firestore insertion
  static List<Tribe> getOfficialClubs() {
    return officialClubs.map((clubData) {
      return Tribe.fromMap(clubData);
    }).toList();
  }

  /// Returns a map of club data ready for Firestore batch insert
  static Map<String, Map<String, dynamic>> getOfficialClubsMap() {
    final Map<String, Map<String, dynamic>> clubsMap = {};

    for (final club in officialClubs) {
      // Generate a consistent ID based on club name
      final id = _generateClubId(club['name'] as String);
      clubsMap[id] = {
        ...club,
        'id': id,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    return clubsMap;
  }

  /// Generates a consistent club ID from the club name
  static String _generateClubId(String clubName) {
    return clubName.toLowerCase().replaceAll(' ', '_').replaceAll("'", '');
  }

  /// Featured clubs that should appear in the spotlight carousel
  static const List<String> featuredClubIds = [
    'mindful_masters',
    'deep_work_society',
    'morning_warriors',
    'creative_collective',
    'lunar_seekers',
  ];
}
