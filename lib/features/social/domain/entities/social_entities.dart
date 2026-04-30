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



enum FriendArchetype { athlete, creator, scholar, stoic, zealot }

class Friend {
  final String id;
  final String name;
  final FriendArchetype archetype;
  final int level;
  final int streak;
  final bool isOnline;
  final String lastSeen;
  final String? avatarUrl;
  final int xp;
  final String? equippedTitle;
  final String? equippedNameplate;
  final List<String> activeContractIds;
  final DateTime? lastActiveAt;

  const Friend({
    required this.id,
    required this.name,
    required this.archetype,
    this.level = 1,
    this.streak = 0,
    this.isOnline = false,
    this.lastSeen = 'Just now',
    this.avatarUrl,
    this.xp = 0,
    this.equippedTitle,
    this.equippedNameplate,
    this.activeContractIds = const [],
    this.lastActiveAt,
  });

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
      xp: map['xp']?.toInt() ?? 0,
      equippedTitle: map['equippedTitle'],
      equippedNameplate: map['equippedNameplate'],
      activeContractIds: List<String>.from(map['activeContractIds'] ?? []),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String)
          : null,
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
      'xp': xp,
      'equippedTitle': equippedTitle,
      'equippedNameplate': equippedNameplate,
      'activeContractIds': activeContractIds,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }
}

/// A partner request (friend request)
class PartnerRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderArchetype;
  final int senderLevel;
  final String recipientId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  const PartnerRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderArchetype,
    required this.senderLevel,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  factory PartnerRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    return PartnerRequest(
      id: id ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderArchetype: map['senderArchetype'] ?? 'creator',
      senderLevel: map['senderLevel']?.toInt() ?? 1,
      recipientId: map['recipientId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
                ? map['createdAt']
                : DateTime.tryParse(map['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderArchetype': senderArchetype,
      'senderLevel': senderLevel,
      'recipientId': recipientId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CreatorBlueprint {
  final String id;
  final String creatorUserId;
  final String creatorName;
  final String creatorArchetype; // e.g. 'Scholar'
  final String blueprintName; // e.g. 'Morning Deep Work Stack'
  final String description;
  final List<String> habitTitles; // Ordered habit stack to adopt
  final int adoptionCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String? category; // e.g. 'Productivity'

  const CreatorBlueprint({
    required this.id,
    required this.creatorUserId,
    required this.creatorName,
    required this.creatorArchetype,
    required this.blueprintName,
    required this.description,
    required this.habitTitles,
    this.adoptionCount = 0,
    required this.createdAt,
    this.imageUrl,
    this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorUserId': creatorUserId,
    'creatorName': creatorName,
    'creatorArchetype': creatorArchetype,
    'blueprintName': blueprintName,
    'description': description,
    'habitTitles': habitTitles,
    'adoptionCount': adoptionCount,
    'createdAt': createdAt.toIso8601String(),
    'imageUrl': imageUrl,
    'category': category,
  };

  factory CreatorBlueprint.fromMap(Map<String, dynamic> map) {
    // createdAt can be a Firestore Timestamp (from Firestore reads) or an ISO string (from toMap())
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      // Firestore Timestamp — has a toDate() method
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {}
      // ISO string fallback
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return CreatorBlueprint(
    id: map['id'] as String,
    creatorUserId: map['creatorUserId'] as String,
    creatorName: map['creatorName'] as String,
    creatorArchetype: map['creatorArchetype'] as String? ?? 'Unknown',
    blueprintName: map['blueprintName'] as String,
    description: map['description'] as String,
    habitTitles: List<String>.from(map['habitTitles'] as List? ?? []),
    adoptionCount: (map['adoptionCount'] as int?) ?? 0,
    createdAt: parseCreatedAt(map['createdAt']),
    imageUrl: map['imageUrl'] as String?,
    category: map['category'] as String?,
  );
  }
}
