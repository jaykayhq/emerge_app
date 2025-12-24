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
  final String? affiliateUrl;
  final int xpReward;
  final bool isFeatured;
  final bool isTeamChallenge;
  final bool buddyValidationRequired;
  final List<ChallengeStep> steps;
  final String category;
  final String? sponsor;
  final String? sponsorLogoUrl;

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
    this.affiliateUrl,
    required this.xpReward,
    this.isFeatured = false,
    this.isTeamChallenge = false,
    this.buddyValidationRequired = false,
    required this.steps,
    this.category = 'All',
    this.sponsor,
    this.sponsorLogoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'reward': reward,
      'participants': participants,
      'daysLeft': daysLeft,
      'totalDays': totalDays,
      'currentDay': currentDay,
      'status': status.name,
      'affiliateUrl': affiliateUrl,
      'xpReward': xpReward,
      'isFeatured': isFeatured,
      'isTeamChallenge': isTeamChallenge,
      'buddyValidationRequired': buddyValidationRequired,
      'category': category,
      'sponsor': sponsor,
      'sponsorLogoUrl': sponsorLogoUrl,
      // steps would be a sub-collection or array usually, simplifying for now
      'steps': steps
          .map(
            (s) => {
              'day': s.day,
              'title': s.title,
              'description': s.description,
              'isCompleted': s.isCompleted,
            },
          )
          .toList(),
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map, {String? id}) {
    return Challenge(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      reward: map['reward'] ?? '',
      participants: map['participants']?.toInt() ?? 0,
      daysLeft: map['daysLeft']?.toInt() ?? 0,
      totalDays: map['totalDays']?.toInt() ?? 0,
      currentDay: map['currentDay']?.toInt() ?? 0,
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChallengeStatus
            .featured, // Default to featured if unknown? Or active?
      ),
      affiliateUrl: map['affiliateUrl'],
      xpReward: map['xpReward']?.toInt() ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      isTeamChallenge: map['isTeamChallenge'] ?? false,
      buddyValidationRequired: map['buddyValidationRequired'] ?? false,
      category: map['category'] ?? 'All',
      sponsor: map['sponsor'],
      sponsorLogoUrl: map['sponsorLogoUrl'],
      steps:
          (map['steps'] as List<dynamic>?)
              ?.map(
                (s) => ChallengeStep(
                  day: s['day'],
                  title: s['title'],
                  description: s['description'],
                  isCompleted: s['isCompleted'] ?? false,
                ),
              )
              .toList() ??
          [],
    );
  }

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
    affiliateUrl,
    xpReward,
    isFeatured,
    isTeamChallenge,
    buddyValidationRequired,
    steps,
    category,
    sponsor,
    sponsorLogoUrl,
  ];

  Challenge copyWith({
    String? title,
    String? description,
    String? imageUrl,
    ChallengeStatus? status,
    int? currentDay,
    int? participants,
    List<ChallengeStep>? steps,
  }) {
    return Challenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      reward: reward,
      participants: participants ?? this.participants,
      daysLeft: daysLeft,
      totalDays: totalDays,
      currentDay: currentDay ?? this.currentDay,
      status: status ?? this.status,
      affiliateUrl: affiliateUrl,
      xpReward: xpReward,
      isFeatured: isFeatured,
      isTeamChallenge: isTeamChallenge,
      buddyValidationRequired: buddyValidationRequired,
      steps: steps ?? this.steps,
      category: category,
      sponsor: sponsor,
      sponsorLogoUrl: sponsorLogoUrl,
    );
  }
}
