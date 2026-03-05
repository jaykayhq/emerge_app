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
