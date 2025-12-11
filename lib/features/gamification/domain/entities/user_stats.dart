import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final String userId;
  final int currentXp;
  final int currentLevel;
  final int currentStreak; // Global streak
  final List<String> unlockedBadges;

  const UserStats({
    required this.userId,
    this.currentXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.unlockedBadges = const [],
  });

  static const empty = UserStats(userId: '');

  UserStats copyWith({
    String? userId,
    int? currentXp,
    int? currentLevel,
    int? currentStreak,
    List<String>? unlockedBadges,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      currentXp: currentXp ?? this.currentXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    currentXp,
    currentLevel,
    currentStreak,
    unlockedBadges,
  ];
}
