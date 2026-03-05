import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final String userId;
  final int currentXp;
  final int currentLevel;
  final int currentStreak; // Global streak
  final List<String> unlockedBadges;
  final Map<String, int> identityVotes;

  // Referral tracking fields
  final String? referralCode; // Unique code for this user
  final String? referredByCode; // Who referred them
  final int successfulReferrals; // Count of successful referrals
  final int totalReferralXpEarned; // XP from referrals
  final List<String> referredUserIds; // Users they referred

  // Reward tracking fields
  final List<String> unlockedRewardIds; // All earned/purchased reward IDs
  final String? equippedTitleId; // Currently active title
  final String? equippedNameplateId; // Currently active nameplate
  final List<String> equippedEmblemIds; // Currently displayed emblems (max 3)
  final int completedChallenges; // For challenge-based reward unlocks
  final int completedContracts; // For contract-based reward unlocks

  const UserStats({
    required this.userId,
    this.currentXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.unlockedBadges = const [],
    this.identityVotes = const {},
    // Referral fields with defaults
    this.referralCode,
    this.referredByCode,
    this.successfulReferrals = 0,
    this.totalReferralXpEarned = 0,
    this.referredUserIds = const [],
    // Reward fields with defaults
    this.unlockedRewardIds = const [],
    this.equippedTitleId,
    this.equippedNameplateId,
    this.equippedEmblemIds = const [],
    this.completedChallenges = 0,
    this.completedContracts = 0,
  });

  static const empty = UserStats(userId: '');

  UserStats copyWith({
    String? userId,
    int? currentXp,
    int? currentLevel,
    int? currentStreak,
    List<String>? unlockedBadges,
    Map<String, int>? identityVotes,
    // Referral fields
    String? referralCode,
    String? referredByCode,
    int? successfulReferrals,
    int? totalReferralXpEarned,
    List<String>? referredUserIds,
    // Reward fields
    List<String>? unlockedRewardIds,
    String? equippedTitleId,
    String? equippedNameplateId,
    List<String>? equippedEmblemIds,
    int? completedChallenges,
    int? completedContracts,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      currentXp: currentXp ?? this.currentXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      identityVotes: identityVotes ?? this.identityVotes,
      // Referral fields
      referralCode: referralCode ?? this.referralCode,
      referredByCode: referredByCode ?? this.referredByCode,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      totalReferralXpEarned:
          totalReferralXpEarned ?? this.totalReferralXpEarned,
      referredUserIds: referredUserIds ?? this.referredUserIds,
      // Reward fields
      unlockedRewardIds: unlockedRewardIds ?? this.unlockedRewardIds,
      equippedTitleId: equippedTitleId ?? this.equippedTitleId,
      equippedNameplateId: equippedNameplateId ?? this.equippedNameplateId,
      equippedEmblemIds: equippedEmblemIds ?? this.equippedEmblemIds,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      completedContracts: completedContracts ?? this.completedContracts,
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
    // Referral fields
    referralCode,
    referredByCode,
    successfulReferrals,
    totalReferralXpEarned,
    referredUserIds,
    // Reward fields
    unlockedRewardIds,
    equippedTitleId,
    equippedNameplateId,
    equippedEmblemIds,
    completedChallenges,
    completedContracts,
  ];
}
