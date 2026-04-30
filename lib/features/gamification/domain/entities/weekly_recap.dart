import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:equatable/equatable.dart';

class UserWeeklyRecap extends Equatable {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalHabitsCompleted;
  final int perfectDays;
  final int totalXpEarned;
  final String topHabitName;
  final int currentLevel;
  final double
  worldGrowthPercentage; // 0.0 to 1.0 representation of entropy reduction or level gain

  final String? dominantIdentityThisWeek;
  final String? identityHeadline;
  final String? aiInsight;
  final HabitDifficulty? recommendedDifficultyAdjustment;
  final List<String> velocityInsights;

  const UserWeeklyRecap({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalHabitsCompleted,
    required this.perfectDays,
    required this.totalXpEarned,
    required this.topHabitName,
    required this.currentLevel,
    required this.worldGrowthPercentage,
    this.dominantIdentityThisWeek,
    this.identityHeadline,
    this.aiInsight,
    this.recommendedDifficultyAdjustment,
    this.velocityInsights = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalHabitsCompleted': totalHabitsCompleted,
      'perfectDays': perfectDays,
      'totalXpEarned': totalXpEarned,
      'topHabitName': topHabitName,
      'currentLevel': currentLevel,
      'worldGrowthPercentage': worldGrowthPercentage,
      'dominantIdentityThisWeek': dominantIdentityThisWeek,
      'identityHeadline': identityHeadline,
      'aiInsight': aiInsight,
      'recommendedDifficultyAdjustment': recommendedDifficultyAdjustment?.name,
      'velocityInsights': velocityInsights,
    };
  }

  factory UserWeeklyRecap.fromMap(Map<String, dynamic> map) {
    return UserWeeklyRecap(
      id: map['id'] as String,
      userId: map['userId'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      totalHabitsCompleted: map['totalHabitsCompleted'] as int,
      perfectDays: map['perfectDays'] as int,
      totalXpEarned: map['totalXpEarned'] as int,
      topHabitName: map['topHabitName'] as String,
      currentLevel: map['currentLevel'] as int,
      worldGrowthPercentage: (map['worldGrowthPercentage'] as num).toDouble(),
      dominantIdentityThisWeek: map['dominantIdentityThisWeek'] as String?,
      identityHeadline: map['identityHeadline'] as String?,
      aiInsight: map['aiInsight'] as String?,
      recommendedDifficultyAdjustment: map['recommendedDifficultyAdjustment'] != null
          ? HabitDifficulty.values.firstWhere(
              (e) => e.name == map['recommendedDifficultyAdjustment'],
              orElse: () => HabitDifficulty.medium,
            )
          : null,
      velocityInsights: List<String>.from(map['velocityInsights'] ?? []),
    );
  }


  @override
  List<Object> get props => [
    id,
    userId,
    startDate,
    endDate,
    totalHabitsCompleted,
  ];
}
