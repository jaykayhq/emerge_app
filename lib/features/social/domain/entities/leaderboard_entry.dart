import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Represents a single entry on a leaderboard
class LeaderboardEntry {
  /// User's unique identifier
  final String userId;

  /// User's display name
  final String userName;

  /// Total XP accumulated
  final int xp;

  /// User's current level
  final int level;

  /// User's archetype
  final UserArchetype archetype;

  /// Current rank on the leaderboard (1-based)
  final int rank;

  /// Last time this score was updated
  final DateTime? lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.xp,
    required this.level,
    required this.archetype,
    required this.rank,
    this.lastUpdated,
  });

  /// Serialize to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'xp': xp,
      'level': level,
      'archetype': archetype.name,
      'rank': rank,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Deserialize from Firestore document
  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == map['archetype'],
        orElse: () => UserArchetype.none,
      ),
      rank: map['rank'] as int? ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String)
          : null,
    );
  }

  /// Create a copy with modified fields
  LeaderboardEntry copyWith({
    String? userId,
    String? userName,
    int? xp,
    int? level,
    UserArchetype? archetype,
    int? rank,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      archetype: archetype ?? this.archetype,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(userId: $userId, userName: $userName, xp: $xp, level: $level, archetype: $archetype, rank: $rank, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.userName == userName &&
        other.xp == xp &&
        other.level == level &&
        other.archetype == archetype &&
        other.rank == rank &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        xp.hashCode ^
        level.hashCode ^
        archetype.hashCode ^
        rank.hashCode ^
        lastUpdated.hashCode;
  }
}
