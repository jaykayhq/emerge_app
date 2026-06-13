// lib/features/social/domain/entities/creator_profile.dart
class CreatorProfile {
  final String userId;
  final String bio;
  final List<String> specialityTags;
  final bool isVerifiedCreator;
  final String? blueprintId;
  final String? tribeId;

  const CreatorProfile({
    required this.userId,
    this.bio = '',
    this.specialityTags = const [],
    this.isVerifiedCreator = false,
    this.blueprintId,
    this.tribeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bio': bio,
      'specialityTags': specialityTags,
      'isVerifiedCreator': isVerifiedCreator,
      'blueprintId': blueprintId,
      'tribeId': tribeId,
    };
  }

  factory CreatorProfile.fromMap(Map<String, dynamic> map) {
    return CreatorProfile(
      userId: map['userId'] ?? '',
      bio: map['bio'] ?? '',
      specialityTags: List<String>.from(map['specialityTags'] ?? []),
      isVerifiedCreator: map['isVerifiedCreator'] ?? false,
      blueprintId: map['blueprintId'],
      tribeId: map['tribeId'],
    );
  }
}
