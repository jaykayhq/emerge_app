// lib/features/social/domain/entities/tribe_membership.dart
enum MembershipType { archetype, creator }

class TribeMembership {
  final String userId;
  final String tribeId;
  final MembershipType type;
  final DateTime joinedAt;
  final int streak;

  const TribeMembership({
    required this.userId,
    required this.tribeId,
    required this.type,
    required this.joinedAt,
    this.streak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tribeId': tribeId,
      'type': type.name,
      'joinedAt': joinedAt.toIso8601String(),
      'streak': streak,
    };
  }

  factory TribeMembership.fromMap(Map<String, dynamic> map) {
    return TribeMembership(
      userId: map['userId'] ?? '',
      tribeId: map['tribeId'] ?? '',
      type: MembershipType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MembershipType.archetype,
      ),
      joinedAt: map['joinedAt'] != null 
          ? DateTime.tryParse(map['joinedAt']) ?? DateTime.now()
          : DateTime.now(),
      streak: map['streak']?.toInt() ?? 0,
    );
  }
}
