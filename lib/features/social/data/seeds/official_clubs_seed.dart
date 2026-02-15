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
      'description': '5AM workouts to start your day with energy and discipline',
      'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['fitness', 'morning', 'workout', 'early-risers'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 1,
      'totalXp': 50000,
      'memberCount': 1250,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Plant-Based Tribe',
      'description': 'Nutrition challenges for plant-based athletes and wellness enthusiasts',
      'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['nutrition', 'plant-based', 'vegan', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 5,
      'totalXp': 28000,
      'memberCount': 890,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'HIIT Heroes',
      'description': 'High-intensity interval training challenges for maximum burn',
      'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
      'archetypeId': 'athlete',
      'type': 'official',
      'levelRequirement': 5,
      'tags': ['hiit', 'fitness', 'cardio', 'strength'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 3,
      'totalXp': 42000,
      'memberCount': 1560,
      'ownerId': 'emerge_official',
    },

    // SCHOLAR ARCHETYPE
    {
      'name': 'Deep Work Society',
      'description': '90-minute focus blocks for profound productivity',
      'imageUrl': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['productivity', 'focus', 'deep-work', 'study'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 2,
      'totalXp': 68000,
      'memberCount': 2100,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Night Owl Readers',
      'description': 'Reading habits and book discussions for late-night learners',
      'imageUrl': 'https://images.unsplash.com/photo-1476275466078-4007374efbbe?w=800',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['reading', 'books', 'learning', 'night-owl'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 7,
      'totalXp': 35000,
      'memberCount': 980,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Language Learners',
      'description': 'Daily language practice challenges with native speaker exchanges',
      'imageUrl': 'https://images.unsplash.com/photo-1543109740-4bdb38fda756?w=800',
      'archetypeId': 'scholar',
      'type': 'official',
      'levelRequirement': 3,
      'tags': ['language', 'learning', 'polyglot', 'education'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 4,
      'totalXp': 39000,
      'memberCount': 1450,
      'ownerId': 'emerge_official',
    },

    // STOIC ARCHETYPE
    {
      'name': 'Mindful Masters',
      'description': '21-day meditation challenges for inner peace and clarity',
      'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['meditation', 'mindfulness', 'calm', 'mental-health'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 1,
      'totalXp': 75000,
      'memberCount': 3200,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Digital Detox Weekend',
      'description': 'Weekly screen-free challenges to reconnect with reality',
      'imageUrl': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['digital-detox', 'mindfulness', 'balance', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 6,
      'totalXp': 31000,
      'memberCount': 1120,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Gratitude Circle',
      'description': 'Daily gratitude journaling for positive mindset shifts',
      'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      'archetypeId': 'stoic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['gratitude', 'journaling', 'positive', 'mindset'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 8,
      'totalXp': 24000,
      'memberCount': 870,
      'ownerId': 'emerge_official',
    },

    // CREATOR ARCHETYPE
    {
      'name': 'Creative Collective',
      'description': 'Ship something every day - build your creative muscle',
      'imageUrl': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
      'archetypeId': 'creator',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['creativity', 'art', 'create', 'daily-practice'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 3,
      'totalXp': 46000,
      'memberCount': 1650,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Music Practice 21',
      'description': '21-day instrument practice challenges for musicians',
      'imageUrl': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800',
      'archetypeId': 'creator',
      'type': 'official',
      'levelRequirement': 3,
      'tags': ['music', 'practice', 'instrument', 'musicians'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 9,
      'totalXp': 22000,
      'memberCount': 640,
      'ownerId': 'emerge_official',
    },

    // MYSTIC ARCHETYPE (Faith-Based)
    {
      'name': 'Lunar Seekers',
      'description': 'Scripture study and daily prayer for spiritual growth',
      'imageUrl': 'https://images.unsplash.com/photo-1507692049790-de58290a4334?w=800',
      'archetypeId': 'mystic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['faith', 'prayer', 'scripture', 'spiritual'],
      'isVerified': true,
      'isFeatured': true,
      'rank': 2,
      'totalXp': 58000,
      'memberCount': 1890,
      'ownerId': 'emerge_official',
    },
    {
      'name': 'Breathwork Circle',
      'description': 'Daily breathwork and meditation for spiritual connection',
      'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
      'archetypeId': 'mystic',
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['breathwork', 'meditation', 'spiritual', 'wellness'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 10,
      'totalXp': 19000,
      'memberCount': 520,
      'ownerId': 'emerge_official',
    },

    // MULTI-ARCHETYPE
    {
      'name': 'Financial Freedom',
      'description': 'Money habits, savings challenges, and wealth building',
      'imageUrl': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800',
      'archetypeId': null, // All archetypes
      'type': 'official',
      'levelRequirement': 1,
      'tags': ['finance', 'money', 'savings', 'wealth'],
      'isVerified': true,
      'isFeatured': false,
      'rank': 5,
      'totalXp': 33000,
      'memberCount': 2340,
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
    return clubName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll("'", '');
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
