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
  final int level; // Add level for ranking and display
  final DateTime? createdAt;
  final List<String> members; // List of user IDs

  // New affiliate/club fields
  final String? affiliatePartnerId; // For brand clubs
  final String? brandLogoUrl; // Separate brand logo
  final DateTime? brandSponsorshipStart;
  final DateTime? brandSponsorshipEnd;
  final bool isFeatured; // For official club spotlight
  final int? maxMembers; // For private clubs
  final int totalHabitsCompleted; // Added for stats accuracy
  final int totalChallengesCompleted; // Added for stats accuracy

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
    this.level = 1, // Default level
    this.createdAt,
    this.members = const [],
    // New fields with defaults
    this.affiliatePartnerId,
    this.brandLogoUrl,
    this.brandSponsorshipStart,
    this.brandSponsorshipEnd,
    this.isFeatured = false,
    this.maxMembers,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
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
      'level': level,
      'createdAt': createdAt?.toIso8601String(),
      'members': members,
      // New affiliate/club fields
      'affiliatePartnerId': affiliatePartnerId,
      'brandLogoUrl': brandLogoUrl,
      'brandSponsorshipStart': brandSponsorshipStart?.toIso8601String(),
      'brandSponsorshipEnd': brandSponsorshipEnd?.toIso8601String(),
      'isFeatured': isFeatured,
      'maxMembers': maxMembers,
      'totalHabitsCompleted': totalHabitsCompleted,
      'totalChallengesCompleted': totalChallengesCompleted,
    };
  }

  factory Tribe.fromMap(Map<String, dynamic> map) {
    // Parse sponsorship dates
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return (value as dynamic).toDate();
      } catch (_) {}
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    DateTime? brandSponsorshipStart;
    if (map['brandSponsorshipStart'] != null) {
      brandSponsorshipStart = parseDateTime(map['brandSponsorshipStart']);
    }

    DateTime? brandSponsorshipEnd;
    if (map['brandSponsorshipEnd'] != null) {
      brandSponsorshipEnd = parseDateTime(map['brandSponsorshipEnd']);
    }

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
      level: map['level']?.toInt() ?? 1,
      createdAt: parseDateTime(map['createdAt']),
      members: List<String>.from(map['members'] ?? []),
      // New affiliate/club fields
      affiliatePartnerId: map['affiliatePartnerId'],
      brandLogoUrl: map['brandLogoUrl'],
      brandSponsorshipStart: brandSponsorshipStart,
      brandSponsorshipEnd: brandSponsorshipEnd,
      isFeatured: map['isFeatured'] ?? false,
      maxMembers: map['maxMembers']?.toInt(),
      totalHabitsCompleted: map['totalHabitsCompleted']?.toInt() ?? 0,
      totalChallengesCompleted: map['totalChallengesCompleted']?.toInt() ?? 0,
    );
  }
}
