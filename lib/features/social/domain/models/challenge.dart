import 'package:equatable/equatable.dart';

enum ChallengeStatus { featured, active, completed }

class ChallengeStep extends Equatable {
  final int day;
  final String title;
  final String description;
  final bool isCompleted;

  const ChallengeStep({
    required this.day,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [day, title, description, isCompleted];

  ChallengeStep copyWith({bool? isCompleted}) {
    return ChallengeStep(
      day: day,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Challenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String reward;
  final int participants;
  final int daysLeft;
  final int totalDays;
  final int currentDay;
  final ChallengeStatus status;
  final List<ChallengeStep> steps;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.reward,
    required this.participants,
    required this.daysLeft,
    required this.totalDays,
    required this.currentDay,
    required this.status,
    required this.steps,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    reward,
    participants,
    daysLeft,
    totalDays,
    currentDay,
    status,
    steps,
  ];

  Challenge copyWith({
    ChallengeStatus? status,
    int? currentDay,
    List<ChallengeStep>? steps,
  }) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      reward: reward,
      participants: participants,
      daysLeft: daysLeft,
      totalDays: totalDays,
      currentDay: currentDay ?? this.currentDay,
      status: status ?? this.status,
      steps: steps ?? this.steps,
    );
  }
}
