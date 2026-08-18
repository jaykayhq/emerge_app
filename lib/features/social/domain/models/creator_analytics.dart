// lib/features/social/domain/models/creator_analytics.dart
import 'package:equatable/equatable.dart';

/// One day's snapshot of a tribe's aggregate stats (Firestore + Drift).
class TribeAnalyticsSnapshot extends Equatable {
  final String tribeId;
  final String date; // yyyy-MM-dd
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int activeMembers;
  final int newMembersThisWeek;

  const TribeAnalyticsSnapshot({
    required this.tribeId,
    required this.date,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
    this.activeMembers = 0,
    this.newMembersThisWeek = 0,
  });

  Map<String, dynamic> toMap() => {
    'tribeId': tribeId,
    'date': date,
    'memberCount': memberCount,
    'totalXp': totalXp,
    'totalHabitsCompleted': totalHabitsCompleted,
    'totalChallengesCompleted': totalChallengesCompleted,
    'activeMembers': activeMembers,
    'newMembersThisWeek': newMembersThisWeek,
  };

  factory TribeAnalyticsSnapshot.fromMap(Map<String, dynamic> map) =>
      TribeAnalyticsSnapshot(
        tribeId: map['tribeId'] as String,
        date: map['date'] as String,
        memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        totalHabitsCompleted: (map['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
        totalChallengesCompleted:
            (map['totalChallengesCompleted'] as num?)?.toInt() ?? 0,
        activeMembers: (map['activeMembers'] as num?)?.toInt() ?? 0,
        newMembersThisWeek: (map['newMembersThisWeek'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [
    tribeId, date, memberCount, totalXp, totalHabitsCompleted,
    totalChallengesCompleted, activeMembers, newMembersThisWeek,
  ];
}

/// A single blueprint's performance row.
class BlueprintStat extends Equatable {
  final String id;
  final String title;
  final int adoptionCount;
  final int habitCount;

  const BlueprintStat({
    required this.id,
    required this.title,
    this.adoptionCount = 0,
    this.habitCount = 0,
  });

  @override
  List<Object?> get props => [id, title, adoptionCount, habitCount];
}

/// A single tribe member's contribution row.
class MemberStat extends Equatable {
  final String userId;
  final String name;
  final int xp;
  final int habitsCompleted;

  const MemberStat({
    required this.userId,
    required this.name,
    this.xp = 0,
    this.habitsCompleted = 0,
  });

  @override
  List<Object?> get props => [userId, name, xp, habitsCompleted];
}

/// A creator-published challenge's health row.
class ChallengeStat extends Equatable {
  final String id;
  final String title;
  final int participants;
  final String status;
  final int xpReward;

  const ChallengeStat({
    required this.id,
    required this.title,
    this.participants = 0,
    this.status = 'active',
    this.xpReward = 0,
  });

  @override
  List<Object?> get props => [id, title, participants, status, xpReward];
}

/// One point on a trend chart (one daily snapshot).
class DailyTrend extends Equatable {
  final String date;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;

  const DailyTrend({
    required this.date,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
  });

  @override
  List<Object?> get props => [date, memberCount, totalXp, totalHabitsCompleted];
}

/// The full analytics payload the UI renders.
class CreatorAnalytics extends Equatable {
  final String tribeId;
  final String tribeName;
  final int memberCount;
  final int totalXp;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final int newMembersThisWeek;
  final int activeMembers;
  final double activeRate; // 0..1
  final List<BlueprintStat> blueprintStats;
  final List<MemberStat> topMembers;
  final List<ChallengeStat> challengeStats;
  final List<DailyTrend> trends;

  const CreatorAnalytics({
    required this.tribeId,
    required this.tribeName,
    this.memberCount = 0,
    this.totalXp = 0,
    this.totalHabitsCompleted = 0,
    this.totalChallengesCompleted = 0,
    this.newMembersThisWeek = 0,
    this.activeMembers = 0,
    this.activeRate = 0,
    this.blueprintStats = const [],
    this.topMembers = const [],
    this.challengeStats = const [],
    this.trends = const [],
  });

  @override
  List<Object?> get props => [
    tribeId, tribeName, memberCount, totalXp, totalHabitsCompleted,
    totalChallengesCompleted, newMembersThisWeek, activeMembers, activeRate,
    blueprintStats, topMembers, challengeStats, trends,
  ];
}
