import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/gamification/domain/models/avatar.dart';

enum UserArchetype { athlete, creator, scholar, stoic, zealot, none }

class UserAvatarStats {
  final int strengthXp;
  final int intellectXp;
  final int vitalityXp;
  final int creativityXp;
  final int focusXp;
  final int spiritXp;
  final int level;
  final int streak;
  final Map<String, int> attributeXp; // ADD THIS

  const UserAvatarStats({
    this.strengthXp = 0,
    this.intellectXp = 0,
    this.vitalityXp = 0,
    this.creativityXp = 0,
    this.focusXp = 0,
    this.spiritXp = 0,
    this.level = 1,
    this.streak = 0,
    this.attributeXp = const {}, // ADD THIS
  });

  Map<String, dynamic> toMap() {
    return {
      'strengthXp': strengthXp,
      'intellectXp': intellectXp,
      'vitalityXp': vitalityXp,
      'creativityXp': creativityXp,
      'focusXp': focusXp,
      'spiritXp': spiritXp,
      'level': level,
      'streak': streak,
      'attributeXp': attributeXp,
    };
  }

  factory UserAvatarStats.fromMap(Map<String, dynamic> map) {
    return UserAvatarStats(
      strengthXp: map['strengthXp'] as int? ?? 0,
      intellectXp: map['intellectXp'] as int? ?? 0,
      vitalityXp: map['vitalityXp'] as int? ?? 0,
      creativityXp: map['creativityXp'] as int? ?? 0,
      focusXp: map['focusXp'] as int? ?? 0,
      spiritXp: map['spiritXp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streak: map['streak'] as int? ?? 0,
      attributeXp: Map<String, dynamic>.from(
        map['attributeXp'] as Map? ?? {},
      ).map((key, value) => MapEntry(key, value as int? ?? 0)),
    );
  }
  int get totalXp =>
      strengthXp + intellectXp + vitalityXp + creativityXp + focusXp + spiritXp;

  UserAvatarStats copyWith({
    int? strengthXp,
    int? intellectXp,
    int? vitalityXp,
    int? creativityXp,
    int? focusXp,
    int? spiritXp,
    int? level,
    int? streak,
    Map<String, int>? attributeXp,
  }) {
    return UserAvatarStats(
      strengthXp: strengthXp ?? this.strengthXp,
      intellectXp: intellectXp ?? this.intellectXp,
      vitalityXp: vitalityXp ?? this.vitalityXp,
      creativityXp: creativityXp ?? this.creativityXp,
      focusXp: focusXp ?? this.focusXp,
      spiritXp: spiritXp ?? this.spiritXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      attributeXp: attributeXp ?? this.attributeXp,
    );
  }

  // ADD: Helper to get XP for specific attribute
  int getAttributeXp(String attribute) {
    return attributeXp[attribute.toLowerCase()] ?? 0;
  }

  // ADD: Add XP to specific attribute
  UserAvatarStats addAttributeXp(String attribute, int amount) {
    final key = attribute.toLowerCase();
    final currentXp = attributeXp[key] ?? 0;
    final newAttributeXp = Map<String, int>.from(attributeXp);
    newAttributeXp[key] = currentXp + amount;

    // Also update the individual attribute field so totalXp computes correctly
    switch (key) {
      case 'strength':
        return copyWith(
          attributeXp: newAttributeXp,
          strengthXp: strengthXp + amount,
        );
      case 'intellect':
        return copyWith(
          attributeXp: newAttributeXp,
          intellectXp: intellectXp + amount,
        );
      case 'vitality':
        return copyWith(
          attributeXp: newAttributeXp,
          vitalityXp: vitalityXp + amount,
        );
      case 'creativity':
        return copyWith(
          attributeXp: newAttributeXp,
          creativityXp: creativityXp + amount,
        );
      case 'focus':
        return copyWith(attributeXp: newAttributeXp, focusXp: focusXp + amount);
      case 'spirit':
        return copyWith(
          attributeXp: newAttributeXp,
          spiritXp: spiritXp + amount,
        );
      default:
        return copyWith(attributeXp: newAttributeXp);
    }
  }
}

/// Seasonal states for the world based on streak
enum WorldSeason { spring, summer, autumn, winter }

/// Available world themes
enum WorldTheme { sanctuary, island, settlement, floatingRealm }

class UserWorldState {
  final int cityLevel;
  final int forestLevel;
  final double entropy; // 0.0 to 1.0 (0 = pristine, 1 = decayed)

  // Growing World fields
  final int worldAge; // Days since world creation
  final Map<String, Map<String, dynamic>> zones; // Zone states by ID
  final List<String> unlockedBuildings; // Building IDs
  final List<Map<String, dynamic>> buildingPlacements; // Placement data
  final List<String> unlockedLandPlots; // Land expansion IDs
  final int totalBuildingsConstructed;
  final DateTime? lastActiveDate; // For decay calculation
  final WorldTheme worldTheme;
  final WorldSeason seasonalState;
  final List<String> claimedNodes; // ID of nodes claimed on the world map
  final List<String> activeNodes; // Nodes with missions in progress
  final int
  highestCompletedNodeLevel; // Highest requiredLevel among completed nodes

  const UserWorldState({
    this.cityLevel = 1,
    this.forestLevel = 1,
    this.entropy = 0.0,
    this.worldAge = 0,
    this.zones = const {},
    this.unlockedBuildings = const [],
    this.buildingPlacements = const [],
    this.unlockedLandPlots = const [],
    this.totalBuildingsConstructed = 0,
    this.lastActiveDate,
    this.worldTheme = WorldTheme.sanctuary,
    this.seasonalState = WorldSeason.spring,
    this.claimedNodes = const [],
    this.activeNodes = const [],
    this.highestCompletedNodeLevel = 0,
  });

  /// Calculate overall world health (inverse of entropy)
  double get worldHealth => 1.0 - entropy;

  /// Check if world is in decay state
  bool get isDecaying => entropy > 0.3;

  /// Check if world is thriving
  bool get isThriving => entropy < 0.1;

  Map<String, dynamic> toMap() {
    return {
      'cityLevel': cityLevel,
      'forestLevel': forestLevel,
      'entropy': entropy,
      'worldAge': worldAge,
      'zones': zones,
      'unlockedBuildings': unlockedBuildings,
      'buildingPlacements': buildingPlacements,
      'unlockedLandPlots': unlockedLandPlots,
      'totalBuildingsConstructed': totalBuildingsConstructed,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'worldTheme': worldTheme.name,
      'seasonalState': seasonalState.name,
      'claimedNodes': claimedNodes,
      'activeNodes': activeNodes,
      'highestCompletedNodeLevel': highestCompletedNodeLevel,
    };
  }

  factory UserWorldState.fromMap(Map<String, dynamic> map) {
    return UserWorldState(
      cityLevel: map['cityLevel'] as int? ?? 1,
      forestLevel: map['forestLevel'] as int? ?? 1,
      entropy: (map['entropy'] as num?)?.toDouble() ?? 0.0,
      worldAge: map['worldAge'] as int? ?? 0,
      zones:
          (map['zones'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(key, Map<String, dynamic>.from(value as Map)),
          ) ??
          {},
      unlockedBuildings: List<String>.from(map['unlockedBuildings'] ?? []),
      buildingPlacements:
          (map['buildingPlacements'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      unlockedLandPlots: List<String>.from(map['unlockedLandPlots'] ?? []),
      totalBuildingsConstructed: map['totalBuildingsConstructed'] as int? ?? 0,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.tryParse(map['lastActiveDate'] as String)
          : null,
      worldTheme: WorldTheme.values.firstWhere(
        (t) => t.name == map['worldTheme'],
        orElse: () => WorldTheme.sanctuary,
      ),
      seasonalState: WorldSeason.values.firstWhere(
        (s) => s.name == map['seasonalState'],
        orElse: () => WorldSeason.spring,
      ),
      claimedNodes: List<String>.from(map['claimedNodes'] ?? []),
      activeNodes: List<String>.from(map['activeNodes'] ?? []),
      highestCompletedNodeLevel: map['highestCompletedNodeLevel'] as int? ?? 0,
    );
  }

  UserWorldState copyWith({
    int? cityLevel,
    int? forestLevel,
    double? entropy,
    int? worldAge,
    Map<String, Map<String, dynamic>>? zones,
    List<String>? unlockedBuildings,
    List<Map<String, dynamic>>? buildingPlacements,
    List<String>? unlockedLandPlots,
    int? totalBuildingsConstructed,
    DateTime? lastActiveDate,
    WorldTheme? worldTheme,
    WorldSeason? seasonalState,
    List<String>? claimedNodes,
    List<String>? activeNodes,
    int? highestCompletedNodeLevel,
  }) {
    return UserWorldState(
      cityLevel: cityLevel ?? this.cityLevel,
      forestLevel: forestLevel ?? this.forestLevel,
      entropy: entropy ?? this.entropy,
      worldAge: worldAge ?? this.worldAge,
      zones: zones ?? this.zones,
      unlockedBuildings: unlockedBuildings ?? this.unlockedBuildings,
      buildingPlacements: buildingPlacements ?? this.buildingPlacements,
      unlockedLandPlots: unlockedLandPlots ?? this.unlockedLandPlots,
      totalBuildingsConstructed:
          totalBuildingsConstructed ?? this.totalBuildingsConstructed,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      worldTheme: worldTheme ?? this.worldTheme,
      seasonalState: seasonalState ?? this.seasonalState,
      claimedNodes: claimedNodes ?? this.claimedNodes,
      activeNodes: activeNodes ?? this.activeNodes,
      highestCompletedNodeLevel:
          highestCompletedNodeLevel ?? this.highestCompletedNodeLevel,
    );
  }

  /// Create initial world state with default zones
  factory UserWorldState.initial() {
    return UserWorldState(
      zones: {
        'garden': {
          'zoneId': 'garden',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
        'library': {
          'zoneId': 'library',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
        'forge': {
          'zoneId': 'forge',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
        'studio': {
          'zoneId': 'studio',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
        'shrine': {
          'zoneId': 'shrine',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
        'temple': {
          'zoneId': 'temple',
          'level': 1,
          'health': 1.0,
          'milestone': 0,
          'activeElements': <String>[],
        },
      },
      lastActiveDate: DateTime.now(),
      claimedNodes: [],
      activeNodes: [],
      highestCompletedNodeLevel: 0,
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

  /// Effective level: min of XP-based level, node-gated level, and emerge gate.
  /// Users cannot progress past level 5 until they Emerge,
  /// and cannot progress past a node they haven't completed.
  int get effectiveLevel {
    final xpLevel = avatarStats.level;
    final nodeGate = worldState.highestCompletedNodeLevel + 1;
    final emergeGate = hasEmerged ? 999 : 5;
    final candidates = [xpLevel, nodeGate, emergeGate];
    return candidates.reduce((a, b) => a < b ? a : b);
  }

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
  final UserSettings settings;
  final DateTime? accountCreatedAt; // When the user account was created
  final bool hasEmerged; // Whether user has pressed Emerge at level 5

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
    this.settings = const UserSettings(),
    this.accountCreatedAt,
    this.hasEmerged = false,
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
      'settings': settings.toMap(),
      'accountCreatedAt': accountCreatedAt?.toIso8601String(),
      'hasEmerged': hasEmerged,
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
      settings: map['settings'] != null
          ? UserSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : const UserSettings(),
      accountCreatedAt: map['accountCreatedAt'] != null
          ? DateTime.tryParse(map['accountCreatedAt'] as String)
          : null,
      hasEmerged: map['hasEmerged'] as bool? ?? false,
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
    UserSettings? settings,
    DateTime? accountCreatedAt,
    bool? hasEmerged,
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
      settings: settings ?? this.settings,
      accountCreatedAt: accountCreatedAt ?? this.accountCreatedAt,
      hasEmerged: hasEmerged ?? this.hasEmerged,
    );
  }
}

class UserSettings {
  final bool notificationsEnabled;
  final bool healthKitConnected;
  final bool screenTimeConnected;
  final bool soundsEnabled;
  final bool hapticsEnabled;

  // Detailed Notification Settings
  final bool habitReminders;
  final bool streakWarnings;
  final bool aiInsights;
  final bool communityUpdates;
  final bool rewardsUpdates;
  final bool doNotDisturb;

  const UserSettings({
    this.notificationsEnabled = true,
    this.healthKitConnected = false,
    this.screenTimeConnected = false,
    this.soundsEnabled = true,
    this.hapticsEnabled = true,
    this.habitReminders = true,
    this.streakWarnings = true,
    this.aiInsights = true,
    this.communityUpdates = false,
    this.rewardsUpdates = true,
    this.doNotDisturb = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'healthKitConnected': healthKitConnected,
      'screenTimeConnected': screenTimeConnected,
      'soundsEnabled': soundsEnabled,
      'hapticsEnabled': hapticsEnabled,
      'habitReminders': habitReminders,
      'streakWarnings': streakWarnings,
      'aiInsights': aiInsights,
      'communityUpdates': communityUpdates,
      'rewardsUpdates': rewardsUpdates,
      'doNotDisturb': doNotDisturb,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      healthKitConnected: map['healthKitConnected'] as bool? ?? false,
      screenTimeConnected: map['screenTimeConnected'] as bool? ?? false,
      soundsEnabled: map['soundsEnabled'] as bool? ?? true,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      habitReminders: map['habitReminders'] as bool? ?? true,
      streakWarnings: map['streakWarnings'] as bool? ?? true,
      aiInsights: map['aiInsights'] as bool? ?? true,
      communityUpdates: map['communityUpdates'] as bool? ?? false,
      rewardsUpdates: map['rewardsUpdates'] as bool? ?? true,
      doNotDisturb: map['doNotDisturb'] as bool? ?? false,
    );
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? healthKitConnected,
    bool? screenTimeConnected,
    bool? soundsEnabled,
    bool? hapticsEnabled,
    bool? habitReminders,
    bool? streakWarnings,
    bool? aiInsights,
    bool? communityUpdates,
    bool? rewardsUpdates,
    bool? doNotDisturb,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      healthKitConnected: healthKitConnected ?? this.healthKitConnected,
      screenTimeConnected: screenTimeConnected ?? this.screenTimeConnected,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      habitReminders: habitReminders ?? this.habitReminders,
      streakWarnings: streakWarnings ?? this.streakWarnings,
      aiInsights: aiInsights ?? this.aiInsights,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      rewardsUpdates: rewardsUpdates ?? this.rewardsUpdates,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
    );
  }
}
