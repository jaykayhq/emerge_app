class Tribe {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String imageUrl;

  const Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.imageUrl,
  });
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int participants;
  final int daysLeft;
  final String imageUrl;
  final int xpReward;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.daysLeft,
    required this.imageUrl,
    this.xpReward = 100,
  });
}

enum FriendArchetype { athlete, creator, scholar, stoic }

class Friend {
  final String id;
  final String name;
  final FriendArchetype archetype;
  final int level;
  final int streak;
  final bool isOnline;
  final String lastSeen;
  final String? avatarUrl;

  const Friend({
    required this.id,
    required this.name,
    required this.archetype,
    this.level = 1,
    this.streak = 0,
    this.isOnline = false,
    this.lastSeen = 'Just now',
    this.avatarUrl,
  });
  /* ... (existing fields) ... */

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      archetype: FriendArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => FriendArchetype.creator,
      ),
      level: map['level']?.toInt() ?? 1,
      streak: map['streak']?.toInt() ?? 0,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] ?? 'Just now',
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'archetype': archetype.name,
      'level': level,
      'streak': streak,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'avatarUrl': avatarUrl,
    };
  }
}
