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

  // New affiliate/club fields
  final String? affiliatePartnerId;  // For brand clubs
  final String? brandLogoUrl;         // Separate brand logo
  final DateTime? brandSponsorshipStart;
  final DateTime? brandSponsorshipEnd;
  final bool isFeatured;              // For official club spotlight
  final int? maxMembers;              // For private clubs

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
    // New fields with defaults
    this.affiliatePartnerId,
    this.brandLogoUrl,
    this.brandSponsorshipStart,
    this.brandSponsorshipEnd,
    this.isFeatured = false,
    this.maxMembers,
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
      // New affiliate/club fields
      'affiliatePartnerId': affiliatePartnerId,
      'brandLogoUrl': brandLogoUrl,
      'brandSponsorshipStart': brandSponsorshipStart?.toIso8601String(),
      'brandSponsorshipEnd': brandSponsorshipEnd?.toIso8601String(),
      'isFeatured': isFeatured,
      'maxMembers': maxMembers,
    };
  }

  factory Tribe.fromMap(Map<String, dynamic> map) {
    // Parse sponsorship dates
    DateTime? brandSponsorshipStart;
    if (map['brandSponsorshipStart'] != null) {
      brandSponsorshipStart = DateTime.tryParse(map['brandSponsorshipStart'] as String);
    }

    DateTime? brandSponsorshipEnd;
    if (map['brandSponsorshipEnd'] != null) {
      brandSponsorshipEnd = DateTime.tryParse(map['brandSponsorshipEnd'] as String);
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
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
      // New affiliate/club fields
      affiliatePartnerId: map['affiliatePartnerId'],
      brandLogoUrl: map['brandLogoUrl'],
      brandSponsorshipStart: brandSponsorshipStart,
      brandSponsorshipEnd: brandSponsorshipEnd,
      isFeatured: map['isFeatured'] ?? false,
      maxMembers: map['maxMembers']?.toInt(),
    );
  }
}
