enum TribeType { official, brand, userPrivate, userPublic }

class Tribe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ownerId;
  final List<String> tags;
  final int levelRequirement;
  final int rank;
  final int totalXp;
  final int memberCount;
  final TribeType type;
  final String? archetypeId;
  final bool isVerified;
  final DateTime? createdAt;

  const Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.memberCount,
    required this.ownerId,
    required this.tags,
    required this.levelRequirement,
    required this.rank,
    required this.totalXp,
    this.type = TribeType.userPublic,
    this.archetypeId,
    this.isVerified = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'ownerId': ownerId,
      'tags': tags,
      'levelRequirement': levelRequirement,
      'rank': rank,
      'totalXp': totalXp,
      'type': type.name, // Enum to string
      'archetypeId': archetypeId,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Tribe.fromMap(Map<String, dynamic> map) {
    return Tribe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      memberCount: map['memberCount']?.toInt() ?? 0,
      ownerId: map['ownerId'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      levelRequirement: map['levelRequirement']?.toInt() ?? 0,
      rank: map['rank']?.toInt() ?? 0,
      totalXp: map['totalXp']?.toInt() ?? 0,
      type: TribeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TribeType.userPublic,
      ),
      archetypeId: map['archetypeId'],
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }
}
