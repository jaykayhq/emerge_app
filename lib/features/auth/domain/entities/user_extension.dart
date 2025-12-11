import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/gamification/domain/models/avatar.dart';

enum UserArchetype { athlete, creator, scholar, stoic, none }

class UserAvatarStats {
  final int strengthXp;
  final int intellectXp;
  final int vitalityXp;
  final int creativityXp;
  final int focusXp;
  final int level;

  const UserAvatarStats({
    this.strengthXp = 0,
    this.intellectXp = 0,
    this.vitalityXp = 0,
    this.creativityXp = 0,
    this.focusXp = 0,
    this.level = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'strengthXp': strengthXp,
      'intellectXp': intellectXp,
      'vitalityXp': vitalityXp,
      'creativityXp': creativityXp,
      'focusXp': focusXp,
      'level': level,
    };
  }

  factory UserAvatarStats.fromMap(Map<String, dynamic> map) {
    return UserAvatarStats(
      strengthXp: map['strengthXp'] as int? ?? 0,
      intellectXp: map['intellectXp'] as int? ?? 0,
      vitalityXp: map['vitalityXp'] as int? ?? 0,
      creativityXp: map['creativityXp'] as int? ?? 0,
      focusXp: map['focusXp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
    );
  }
  int get totalXp =>
      strengthXp + intellectXp + vitalityXp + creativityXp + focusXp;
}

class UserWorldState {
  final int cityLevel;
  final int forestLevel;
  final double entropy; // 0.0 to 1.0 (0 = pristine, 1 = decayed)

  const UserWorldState({
    this.cityLevel = 1,
    this.forestLevel = 1,
    this.entropy = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'cityLevel': cityLevel,
      'forestLevel': forestLevel,
      'entropy': entropy,
    };
  }

  factory UserWorldState.fromMap(Map<String, dynamic> map) {
    return UserWorldState(
      cityLevel: map['cityLevel'] as int? ?? 1,
      forestLevel: map['forestLevel'] as int? ?? 1,
      entropy: (map['entropy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

extension UserExtension on AuthUser {
  // Note: Since AuthUser is likely a simple wrapper around Firebase User or similar,
  // we might need a separate 'UserProfile' entity in Firestore to store this extra data.
  // For now, I'll define the data structures here, but they will likely need to be
  // fetched from a 'users' collection in Firestore.
}

class HabitStack {
  final String anchorId;
  final String habitId;

  const HabitStack({required this.anchorId, required this.habitId});

  Map<String, dynamic> toMap() {
    return {'anchorId': anchorId, 'habitId': habitId};
  }

  factory HabitStack.fromMap(Map<String, dynamic> map) {
    return HabitStack(
      anchorId: map['anchorId'] as String,
      habitId: map['habitId'] as String,
    );
  }
}

class UserProfile {
  final String uid;
  final UserArchetype archetype;
  final Map<String, int> identityVotes; // e.g., {'Runner': 10, 'Reader': 5}
  final UserAvatarStats avatarStats;
  final UserWorldState worldState;
  final bool reframeMode;
  final String? motive;
  final String? why;
  final List<String> anchors;
  final List<HabitStack> habitStacks;
  final int onboardingProgress; // 0-3
  final List<String>
  skippedOnboardingSteps; // ['archetype', 'anchors', 'stacking']
  final DateTime? onboardingStartedAt;
  final DateTime? onboardingCompletedAt;
  final List<String> equipment;
  final String? worldTheme; // 'forest', 'city', or null (default/archetype)
  final String? characterClass;
  final Avatar avatar;

  const UserProfile({
    required this.uid,
    this.archetype = UserArchetype.none,
    this.identityVotes = const {},
    this.avatarStats = const UserAvatarStats(),
    this.worldState = const UserWorldState(),
    this.reframeMode = false,
    this.motive,
    this.why,
    this.anchors = const [],
    this.habitStacks = const [],
    this.onboardingProgress = 0,
    this.skippedOnboardingSteps = const [],
    this.onboardingStartedAt,
    this.onboardingCompletedAt,
    this.equipment = const [],
    this.characterClass,
    this.avatar = const Avatar(),
    this.worldTheme,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'archetype': archetype.name,
      'identityVotes': identityVotes,
      'avatarStats': avatarStats.toMap(),
      'worldState': worldState.toMap(),
      'reframeMode': reframeMode,
      'motive': motive,
      'why': why,
      'anchors': anchors,
      'habitStacks': habitStacks.map((e) => e.toMap()).toList(),
      'onboardingProgress': onboardingProgress,
      'skippedOnboardingSteps': skippedOnboardingSteps,
      'onboardingStartedAt': onboardingStartedAt?.toIso8601String(),
      'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
      'equipment': equipment,
      'characterClass': characterClass,
      'avatar': avatar.toMap(),
      'worldTheme': worldTheme,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => UserArchetype.none,
      ),
      identityVotes: Map<String, int>.from(map['identityVotes'] ?? {}),
      avatarStats: UserAvatarStats.fromMap(map['avatarStats'] ?? {}),
      worldState: UserWorldState.fromMap(map['worldState'] ?? {}),
      reframeMode: map['reframeMode'] as bool? ?? false,
      motive: map['motive'] as String?,
      why: map['why'] as String?,
      anchors: List<String>.from(map['anchors'] ?? []),
      habitStacks:
          (map['habitStacks'] as List<dynamic>?)
              ?.map((e) => HabitStack.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      onboardingProgress: map['onboardingProgress'] as int? ?? 0,
      skippedOnboardingSteps: List<String>.from(
        map['skippedOnboardingSteps'] ?? [],
      ),
      onboardingStartedAt: map['onboardingStartedAt'] != null
          ? DateTime.tryParse(map['onboardingStartedAt'] as String)
          : null,
      onboardingCompletedAt: map['onboardingCompletedAt'] != null
          ? DateTime.tryParse(map['onboardingCompletedAt'] as String)
          : null,
      equipment: List<String>.from(map['equipment'] ?? []),
      characterClass: map['characterClass'] as String?,
      avatar: map['avatar'] is Map<String, dynamic>
          ? Avatar.fromMap(map['avatar'] as Map<String, dynamic>)
          : const Avatar(),
      worldTheme: map['worldTheme'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    UserArchetype? archetype,
    Map<String, int>? identityVotes,
    UserAvatarStats? avatarStats,
    UserWorldState? worldState,
    bool? reframeMode,
    String? motive,
    String? why,
    List<String>? anchors,
    List<HabitStack>? habitStacks,
    int? onboardingProgress,
    List<String>? skippedOnboardingSteps,
    DateTime? onboardingStartedAt,
    DateTime? onboardingCompletedAt,
    List<String>? equipment,
    String? characterClass,
    Avatar? avatar,
    String? worldTheme,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      archetype: archetype ?? this.archetype,
      identityVotes: identityVotes ?? this.identityVotes,
      avatarStats: avatarStats ?? this.avatarStats,
      worldState: worldState ?? this.worldState,
      reframeMode: reframeMode ?? this.reframeMode,
      motive: motive ?? this.motive,
      why: why ?? this.why,
      anchors: anchors ?? this.anchors,
      habitStacks: habitStacks ?? this.habitStacks,
      onboardingProgress: onboardingProgress ?? this.onboardingProgress,
      skippedOnboardingSteps:
          skippedOnboardingSteps ?? this.skippedOnboardingSteps,
      onboardingStartedAt: onboardingStartedAt ?? this.onboardingStartedAt,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      equipment: equipment ?? this.equipment,
      characterClass: characterClass ?? this.characterClass,
      avatar: avatar ?? this.avatar,
      worldTheme: worldTheme ?? this.worldTheme,
    );
  }
}
