import 'package:equatable/equatable.dart';

enum ChallengeStatus { featured, active, completed }

enum ChallengeCategory {
  all,
  fitness,
  mindfulness,
  learning,
  nutrition,
  productivity,
  creative,
  faith,
}

enum AffiliateNetwork {
  cj,
  impact,
  shareASale,
  amazon,
  direct,
  none,
}

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
  final ChallengeCategory category;
  final String? sponsor;
  final String? sponsorLogoUrl;

  // New affiliate fields
  final String? affiliatePartnerId;
  final AffiliateNetwork affiliateNetwork;
  final double? commissionRate;
  final String? rewardDescription;
  final bool isSponsored;
  final DateTime? sponsorshipStartDate;
  final DateTime? sponsorshipEndDate;
  final String? archetypeId;

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
    this.category = ChallengeCategory.all,
    this.sponsor,
    this.sponsorLogoUrl,
    // New affiliate fields with defaults
    this.affiliatePartnerId,
    this.affiliateNetwork = AffiliateNetwork.none,
    this.commissionRate,
    this.rewardDescription,
    this.isSponsored = false,
    this.sponsorshipStartDate,
    this.sponsorshipEndDate,
    this.archetypeId,
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
      'category': category.name,
      'sponsor': sponsor,
      'sponsorLogoUrl': sponsorLogoUrl,
      // New affiliate fields
      'affiliatePartnerId': affiliatePartnerId,
      'affiliateNetwork': affiliateNetwork.name,
      'commissionRate': commissionRate,
      'rewardDescription': rewardDescription,
      'isSponsored': isSponsored,
      'sponsorshipStartDate': sponsorshipStartDate?.toIso8601String(),
      'sponsorshipEndDate': sponsorshipEndDate?.toIso8601String(),
      'archetypeId': archetypeId,
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
    // Parse category string to enum, default to 'all'
    final categoryString = map['category'] as String?;
    ChallengeCategory parsedCategory = ChallengeCategory.all;
    if (categoryString != null) {
      try {
        parsedCategory = ChallengeCategory.values.firstWhere(
          (e) => e.name == categoryString,
          orElse: () => ChallengeCategory.all,
        );
      } catch (_) {
        parsedCategory = ChallengeCategory.all;
      }
    }

    // Parse affiliate network string to enum, default to 'none'
    final networkString = map['affiliateNetwork'] as String?;
    AffiliateNetwork parsedNetwork = AffiliateNetwork.none;
    if (networkString != null) {
      try {
        parsedNetwork = AffiliateNetwork.values.firstWhere(
          (e) => e.name == networkString,
          orElse: () => AffiliateNetwork.none,
        );
      } catch (_) {
        parsedNetwork = AffiliateNetwork.none;
      }
    }

    // Parse dates
    DateTime? startDate;
    if (map['sponsorshipStartDate'] != null) {
      startDate = DateTime.tryParse(map['sponsorshipStartDate'] as String);
    }

    DateTime? endDate;
    if (map['sponsorshipEndDate'] != null) {
      endDate = DateTime.tryParse(map['sponsorshipEndDate'] as String);
    }

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
        orElse: () => ChallengeStatus.featured,
      ),
      affiliateUrl: map['affiliateUrl'],
      xpReward: map['xpReward']?.toInt() ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      isTeamChallenge: map['isTeamChallenge'] ?? false,
      buddyValidationRequired: map['buddyValidationRequired'] ?? false,
      category: parsedCategory,
      sponsor: map['sponsor'],
      sponsorLogoUrl: map['sponsorLogoUrl'],
      // New affiliate fields
      affiliatePartnerId: map['affiliatePartnerId'],
      affiliateNetwork: parsedNetwork,
      commissionRate: map['commissionRate']?.toDouble(),
      rewardDescription: map['rewardDescription'],
      isSponsored: map['isSponsored'] ?? false,
      sponsorshipStartDate: startDate,
      sponsorshipEndDate: endDate,
      archetypeId: map['archetypeId'],
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
    // New affiliate fields
    affiliatePartnerId,
    affiliateNetwork,
    commissionRate,
    rewardDescription,
    isSponsored,
    sponsorshipStartDate,
    sponsorshipEndDate,
    archetypeId,
  ];

  Challenge copyWith({
    String? title,
    String? description,
    String? imageUrl,
    ChallengeStatus? status,
    int? currentDay,
    int? participants,
    List<ChallengeStep>? steps,
    ChallengeCategory? category,
    String? sponsor,
    String? sponsorLogoUrl,
    // New affiliate fields
    String? affiliatePartnerId,
    AffiliateNetwork? affiliateNetwork,
    double? commissionRate,
    String? rewardDescription,
    bool? isSponsored,
    DateTime? sponsorshipStartDate,
    DateTime? sponsorshipEndDate,
    String? archetypeId,
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
      category: category ?? this.category,
      sponsor: sponsor ?? this.sponsor,
      sponsorLogoUrl: sponsorLogoUrl ?? this.sponsorLogoUrl,
      // New affiliate fields
      affiliatePartnerId: affiliatePartnerId ?? this.affiliatePartnerId,
      affiliateNetwork: affiliateNetwork ?? this.affiliateNetwork,
      commissionRate: commissionRate ?? this.commissionRate,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      isSponsored: isSponsored ?? this.isSponsored,
      sponsorshipStartDate: sponsorshipStartDate ?? this.sponsorshipStartDate,
      sponsorshipEndDate: sponsorshipEndDate ?? this.sponsorshipEndDate,
      archetypeId: archetypeId ?? this.archetypeId,
    );
  }
}
