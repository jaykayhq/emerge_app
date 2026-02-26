library;

/// Firebase Analytics event constants for Emerge app
/// Defines all event names and parameter keys used throughout the application

class AnalyticsEvents {
  // Prevent instantiation
  AnalyticsEvents._();

  // ==================== CHALLENGE EVENTS ====================

  /// User viewed a challenge details screen
  static const String challengeViewed = 'challenge_viewed';

  /// User joined a challenge
  static const String challengeJoined = 'challenge_joined';

  /// User completed a challenge
  static const String challengeCompleted = 'challenge_completed';

  /// User redeemed a reward from a challenge
  static const String rewardRedeemed = 'reward_redeemed';

  /// User clicked on an affiliate link
  static const String affiliateLinkClicked = 'affiliate_link_clicked';

  // ==================== REFERRAL EVENTS ====================

  /// User sent a referral invitation
  static const String referralSent = 'referral_sent';

  /// New user signed up with referral code
  static const String referralAttribution = 'referral_attribution';

  /// Referral completed (new user finished onboarding)
  static const String referralCompleted = 'referral_completed';

  // ==================== SOCIAL EVENTS ====================

  /// User joined a club/tribe
  static const String clubJoined = 'club_joined';

  /// User created a club
  static const String clubCreated = 'club_created';

  /// User submitted a club for approval
  static const String clubSubmitted = 'club_submitted';

  // ==================== ENGAGEMENT EVENTS ====================

  /// User opened the app
  static const String appOpen = 'app_open';

  /// User completed onboarding
  static const String onboardingCompleted = 'onboarding_completed';

  /// User selected an archetype
  static const String archetypeSelected = 'archetype_selected';
}

/// Firebase Analytics parameter keys
class AnalyticsParameters {
  // Prevent instantiation
  AnalyticsParameters._();

  // Common parameters
  static const String userId = 'user_id';
  static const String timestamp = 'timestamp';
  static const String screenName = 'screen_name';

  // Challenge parameters
  static const String challengeId = 'challenge_id';
  static const String challengeName = 'challenge_name';
  static const String challengeCategory = 'challenge_category';
  static const String challengeType =
      'challenge_type'; // weekly, quarterly, custom
  static const String hasAffiliate = 'has_affiliate';
  static const String partnerId = 'partner_id';
  static const String partnerName = 'partner_name';
  static const String affiliateNetwork = 'affiliate_network';
  static const String rewardDescription = 'reward_description';
  static const String daysToComplete = 'days_to_complete';

  // Referral parameters
  static const String referralCode = 'referral_code';
  static const String referrerId = 'referrer_id';
  static const String referredUserId = 'referred_user_id';
  static const String xpAwarded = 'xp_awarded';
  static const String referralMethod = 'referral_method'; // copy, share, etc.

  // Club parameters
  static const String clubId = 'club_id';
  static const String clubName = 'club_name';
  static const String clubType = 'club_type'; // official, private, public
  static const String clubCategory = 'club_category';
  static const String isVerified = 'is_verified';

  // User parameters
  static const String userLevel = 'user_level';
  static const String currentXp = 'current_xp';
  static const String currentStreak = 'current_streak';
  static const String archetypeId = 'archetype_id';
  static const String totalReferrals = 'total_referrals';

  // Engagement parameters
  static const String itemCategory = 'item_category';
  static const String contentType = 'content_type';
  static const String engagementType = 'engagement_type';
}
