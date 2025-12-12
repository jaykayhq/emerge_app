import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final String userId;
  final int currentXp;
  final int currentLevel;
  final int currentStreak; // Global streak
  final List<String> unlockedBadges;
  final Map<String, int> identityVotes;

  const UserStats({
    required this.userId,
    this.currentXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.unlockedBadges = const [],
    this.identityVotes = const {},
  });

  static const empty = UserStats(userId: '');

  UserStats copyWith({
    String? userId,
    int? currentXp,
    int? currentLevel,
    int? currentStreak,
    List<String>? unlockedBadges,
    Map<String, int>? identityVotes,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      currentXp: currentXp ?? this.currentXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      identityVotes: identityVotes ?? this.identityVotes,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    currentXp,
    currentLevel,
    currentStreak,
    unlockedBadges,
    identityVotes,
  ];
}
