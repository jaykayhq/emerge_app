import 'package:equatable/equatable.dart';
import '../../domain/models/challenge.dart';

/// Template for auto-generating weekly challenges
/// These templates are used by Cloud Functions to create fresh challenges regularly
class ChallengeTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final ChallengeCategory category;
  final String? archetypeId;
  final int daysRequired;
  final String habitType; // e.g., 'exercise', 'meditation', 'reading'
  final int xpReward;
  final String? rewardDescription;
  final String? affiliatePartnerId;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final bool used;
  final DateTime createdAt;

  const ChallengeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.archetypeId,
    required this.daysRequired,
    required this.habitType,
    required this.xpReward,
    this.rewardDescription,
    this.affiliatePartnerId,
    required this.difficulty,
    this.used = false,
    required this.createdAt,
  });

  /// Converts template to a Challenge object
  Challenge toChallenge(String challengeId, {int? durationDays}) {
    return Challenge(
      id: challengeId,
      title: name,
      description: description,
      imageUrl: imageUrl,
      reward: rewardDescription ?? '+$xpReward XP',
      participants: 0,
      daysLeft: durationDays ?? daysRequired,
      totalDays: durationDays ?? daysRequired,
      currentDay: 0,
      status: ChallengeStatus.featured,
      affiliateUrl: affiliatePartnerId != null
          ? 'https://emerge.app/challenge/$challengeId?ref=emerge'
          : null,
      xpReward: xpReward,
      isFeatured: true,
      isTeamChallenge: false,
      buddyValidationRequired: false,
      steps: _generateSteps(daysRequired),
      category: category,
      sponsor: affiliatePartnerId,
      sponsorLogoUrl: affiliatePartnerId,
      isSponsored: affiliatePartnerId != null,
      affiliatePartnerId: affiliatePartnerId,
      rewardDescription: rewardDescription,
      archetypeId: archetypeId,
    );
  }

  /// Generates challenge steps based on days required
  List<ChallengeStep> _generateSteps(int days) {
    final steps = <ChallengeStep>[];

    // Add start step
    steps.add(
      ChallengeStep(
        day: 1,
        title: 'Start Your Journey',
        description: 'Complete your first $habitType session',
      ),
    );

    // Add milestone steps
    if (days >= 7) {
      steps.add(
        ChallengeStep(
          day: 7,
          title: 'One Week Strong',
          description: 'You\'ve built momentum! Keep going.',
        ),
      );
    }

    if (days >= 14) {
      steps.add(
        ChallengeStep(
          day: 14,
          title: 'Two Weeks Down',
          description: 'Halfway there! You\'re crushing it.',
        ),
      );
    }

    if (days >= 21) {
      steps.add(
        ChallengeStep(
          day: 21,
          title: 'Three Week Streak',
          description: 'Habit formation in progress!',
        ),
      );
    }

    if (days >= 30) {
      steps.add(
        ChallengeStep(
          day: 30,
          title: '30-Day Champion',
          description: 'You\'ve built a life-changing habit!',
        ),
      );
    }

    // Add final step
    if (!steps.any((s) => s.day == days)) {
      steps.add(
        ChallengeStep(
          day: days,
          title: 'Challenge Complete',
          description: 'Congratulations! You did it!',
        ),
      );
    }

    return steps;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.name,
      'archetypeId': archetypeId,
      'daysRequired': daysRequired,
      'habitType': habitType,
      'xpReward': xpReward,
      'rewardDescription': rewardDescription,
      'affiliatePartnerId': affiliatePartnerId,
      'difficulty': difficulty,
      'used': used,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChallengeTemplate.fromMap(Map<String, dynamic> map, {String? id}) {
    // Parse category string to enum
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

    return ChallengeTemplate(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: parsedCategory,
      archetypeId: map['archetypeId'],
      daysRequired: map['daysRequired']?.toInt() ?? 7,
      habitType: map['habitType'] ?? 'general',
      xpReward: map['xpReward']?.toInt() ?? 100,
      rewardDescription: map['rewardDescription'],
      affiliatePartnerId: map['affiliatePartnerId'],
      difficulty: map['difficulty'] ?? 'beginner',
      used: map['used'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    category,
    archetypeId,
    daysRequired,
    habitType,
    xpReward,
    rewardDescription,
    affiliatePartnerId,
    difficulty,
    used,
    createdAt,
  ];

  ChallengeTemplate copyWith({
    String? name,
    String? description,
    String? imageUrl,
    ChallengeCategory? category,
    String? archetypeId,
    int? daysRequired,
    String? habitType,
    int? xpReward,
    String? rewardDescription,
    String? affiliatePartnerId,
    String? difficulty,
    bool? used,
  }) {
    return ChallengeTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      archetypeId: archetypeId ?? this.archetypeId,
      daysRequired: daysRequired ?? this.daysRequired,
      habitType: habitType ?? this.habitType,
      xpReward: xpReward ?? this.xpReward,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      affiliatePartnerId: affiliatePartnerId ?? this.affiliatePartnerId,
      difficulty: difficulty ?? this.difficulty,
      used: used ?? this.used,
      createdAt: createdAt,
    );
  }
}
