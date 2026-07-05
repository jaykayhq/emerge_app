// lib/features/social/domain/entities/creator_profile.dart
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class CreatorProfile {
  final String userId;

  /// Canonical role, mirrors the Firebase Auth custom claim and the
  /// `users/{uid}.role` field. Should always be 'creator' for docs in
  /// this collection, but kept nullable for defensive parsing of legacy
  /// or partially-written docs.
  final String? role;

  final String? displayName;
  final String? avatarUrl;
  final String? heroImageUrl;
  final String bio;
  final List<String> specialityTags;
  final bool isVerifiedCreator;
  final int blueprintCount;
  final String? blueprintId;
  final String? tribeId;

  /// Creator archetype (e.g. athlete, scholar, creator). Optional — only
  /// set after the creator has completed step 1 of onboarding. Stored as
  /// the enum's `name` string in Firestore.
  final UserArchetype archetype;

  /// 0-3 creator onboarding progress:
  ///   0 = brand-new creator, hasn't started onboarding
  ///   1 = chose archetype / creator identity
  ///   2 = filled bio + speciality tags
  ///   3 = saw the welcome / reveal screen (onboarding complete)
  final int creatorOnboardingProgress;

  /// Timestamp the creator completed onboarding. When set, the router
  /// allows them through to the dashboard without further redirects.
  final DateTime? creatorOnboardingCompletedAt;

  const CreatorProfile({
    required this.userId,
    this.role,
    this.displayName,
    this.avatarUrl,
    this.heroImageUrl,
    this.bio = '',
    this.specialityTags = const [],
    this.isVerifiedCreator = false,
    this.blueprintCount = 0,
    this.blueprintId,
    this.tribeId,
    this.creatorOnboardingProgress = 0,
    this.creatorOnboardingCompletedAt,
    this.archetype = UserArchetype.none,
  });

  CreatorProfile copyWith({
    String? userId,
    String? role,
    String? displayName,
    String? avatarUrl,
    String? heroImageUrl,
    String? bio,
    List<String>? specialityTags,
    bool? isVerifiedCreator,
    int? blueprintCount,
    String? blueprintId,
    String? tribeId,
    int? creatorOnboardingProgress,
    DateTime? creatorOnboardingCompletedAt,
    UserArchetype? archetype,
  }) {
    return CreatorProfile(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      bio: bio ?? this.bio,
      specialityTags: specialityTags ?? this.specialityTags,
      isVerifiedCreator: isVerifiedCreator ?? this.isVerifiedCreator,
      blueprintCount: blueprintCount ?? this.blueprintCount,
      blueprintId: blueprintId ?? this.blueprintId,
      tribeId: tribeId ?? this.tribeId,
      creatorOnboardingProgress:
          creatorOnboardingProgress ?? this.creatorOnboardingProgress,
      creatorOnboardingCompletedAt:
          creatorOnboardingCompletedAt ?? this.creatorOnboardingCompletedAt,
      archetype: archetype ?? this.archetype,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'heroImageUrl': heroImageUrl,
      'bio': bio,
      'specialityTags': specialityTags,
      'isVerifiedCreator': isVerifiedCreator,
      'blueprintCount': blueprintCount,
      'blueprintId': blueprintId,
      'tribeId': tribeId,
      'creatorOnboardingProgress': creatorOnboardingProgress,
      'creatorOnboardingCompletedAt':
          creatorOnboardingCompletedAt?.toIso8601String(),
      'archetype': archetype.name,
    };
  }

  factory CreatorProfile.fromMap(Map<String, dynamic> map) {
    final rawRole = map['role'] as String?;
    final role = (rawRole == 'user' || rawRole == 'creator') ? rawRole : null;

    final rawProgress = map['creatorOnboardingProgress'] as int?;
    final progress = (rawProgress != null && rawProgress >= 0 && rawProgress <= 3)
        ? rawProgress
        : 0;

    DateTime? completedAt;
    final rawCompleted = map['creatorOnboardingCompletedAt'];
    if (rawCompleted is String) {
      completedAt = DateTime.tryParse(rawCompleted);
    } else if (rawCompleted is Map && rawCompleted['_seconds'] is num) {
      // Firestore Timestamp JSON shape (from .data() server-side reads).
      completedAt = DateTime.fromMillisecondsSinceEpoch(
        (rawCompleted['_seconds'] as num).toInt() * 1000,
      );
    }

    return CreatorProfile(
      userId: map['userId'] ?? '',
      role: role,
      displayName: map['displayName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      heroImageUrl: map['heroImageUrl'] as String?,
      bio: map['bio'] ?? '',
      specialityTags: List<String>.from(map['specialityTags'] ?? []),
      isVerifiedCreator: map['isVerifiedCreator'] ?? false,
      blueprintCount: (map['blueprintCount'] as num?)?.toInt() ?? 0,
      blueprintId: map['blueprintId'],
      tribeId: map['tribeId'],
      creatorOnboardingProgress: progress,
      creatorOnboardingCompletedAt: completedAt,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => UserArchetype.none,
      ),
    );
  }
}
