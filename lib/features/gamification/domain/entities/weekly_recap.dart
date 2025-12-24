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
