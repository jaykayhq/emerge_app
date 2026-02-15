import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/analytics_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// Service for managing user referral codes and tracking
/// Implements the referral reward system for user growth
class ReferralService {
  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;
  final Random _random = Random.secure();

  static const String _baseUrl = 'https://emerge.app/referral';
  static const int _xpReward = 500; // XP for successful referral

  ReferralService({
    FirebaseFirestore? firestore,
    FirebaseAnalytics? analytics,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _analytics = analytics ?? FirebaseAnalytics.instance;

  CollectionReference _referralsCollection() =>
      _firestore.collection('referrals');

  DocumentReference _userStatsRef(String userId) =>
      _firestore.collection('user_stats').doc(userId);

  /// Generates a unique referral code for a user
  /// Format: EMERGE + 6 random alphanumeric characters
  /// Example: EMERGE_A3X7K9
  Future<String> generateReferralCode(String userId) async {
    try {
      // Check if user already has a referral code
      final userDoc = await _userStatsRef(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final existingCode = data?['referralCode'] as String?;
        if (existingCode != null && existingCode.isNotEmpty) {
          return existingCode;
        }
      }

      // Generate unique code
      String code;
      bool isUnique = false;
      int attempts = 0;

      do {
        code = _generateCode();
        // Check if code already exists
        final existingDoc = await _referralsCollection().doc(code).get();
        isUnique = !existingDoc.exists;
        attempts++;

        if (attempts > 10) {
          throw Exception('Unable to generate unique referral code');
        }
      } while (!isUnique);

      // Save code to user stats
      await _userStatsRef(userId).set({
        'referralCode': code,
      }, SetOptions(merge: true));

      // Create referral document
      await _referralsCollection().doc(code).set({
        'referrerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      debugPrint('Generated referral code for $userId: $code');
      return code;
    } catch (e) {
      debugPrint('Error generating referral code: $e');
      rethrow;
    }
  }

  /// Gets the user's referral code, generating one if it doesn't exist
  Future<String> getReferralCode(String userId) async {
    try {
      final userDoc = await _userStatsRef(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final code = data?['referralCode'] as String?;
        if (code != null && code.isNotEmpty) {
          return code;
        }
      }
      // Generate new code if none exists
      return await generateReferralCode(userId);
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      rethrow;
    }
  }

  /// Tracks a referral when a new user signs up with a referral code
  Future<void> trackReferral(String referralCode, String newUserId) async {
    try {
      // Get referral document
      final referralDoc = await _referralsCollection().doc(referralCode).get();
      if (!referralDoc.exists) {
        debugPrint('Invalid referral code: $referralCode');
        return;
      }

      final referralData = referralDoc.data() as Map<String, dynamic>;
      final referrerId = referralData['referrerId'] as String;

      // Update referral document
      await referralDoc.reference.update({
        'status': 'pending',
        'referredUserId': newUserId,
        'referredAt': FieldValue.serverTimestamp(),
      });

      // Update new user's stats
      await _userStatsRef(newUserId).set({
        'referredByCode': referralCode,
      }, SetOptions(merge: true));

      // Log analytics event
      await _analytics.logEvent(
        name: AnalyticsEvents.referralAttribution,
        parameters: {
          AnalyticsParameters.referrerId: referrerId,
          AnalyticsParameters.referralCode: referralCode,
          AnalyticsParameters.referredUserId: newUserId,
        },
      );

      debugPrint('Tracked referral: $referralCode -> $newUserId');
    } catch (e) {
      debugPrint('Error tracking referral: $e');
    }
  }

  /// Processes a successful referral when new user completes onboarding
  /// Awards XP to the referrer
  Future<void> processSuccessfulReferral(String newUserId) async {
    try {
      // Get new user's referral code
      final newUserDoc = await _userStatsRef(newUserId).get();
      if (!newUserDoc.exists) {
        debugPrint('New user not found: $newUserId');
        return;
      }

      final data = newUserDoc.data() as Map<String, dynamic>?;
      final referralCode = data?['referredByCode'] as String?;
      if (referralCode == null || referralCode.isEmpty) {
        debugPrint('No referral code found for user: $newUserId');
        return;
      }

      // Get referral document
      final referralDoc = await _referralsCollection().doc(referralCode).get();
      if (!referralDoc.exists) {
        debugPrint('Referral document not found: $referralCode');
        return;
      }

      final referralData = referralDoc.data() as Map<String, dynamic>;
      final referrerId = referralData['referrerId'] as String;
      final status = referralData['status'] as String?;

      // Check if already processed
      if (status == 'completed') {
        debugPrint('Referral already processed: $referralCode');
        return;
      }

      // Award XP to referrer
      await _awardReferralXp(referrerId, newUserId, referralCode);

      // Update referral document
      await referralDoc.reference.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'xpAwarded': _xpReward,
      });

      // Log analytics event
      await _analytics.logEvent(
        name: AnalyticsEvents.referralCompleted,
        parameters: {
          AnalyticsParameters.referrerId: referrerId,
          AnalyticsParameters.referredUserId: newUserId,
          AnalyticsParameters.xpAwarded: _xpReward,
        },
      );

      debugPrint('Processed successful referral: $referrerId -> $newUserId');
    } catch (e) {
      debugPrint('Error processing successful referral: $e');
    }
  }

  /// Gets referral stats for a user
  Future<ReferralStats> getReferralStats(String userId) async {
    try {
      final userDoc = await _userStatsRef(userId).get();
      if (!userDoc.exists) {
        return ReferralStats(
          totalReferrals: 0,
          pendingReferrals: 0,
          xpEarned: 0,
          referralCode: '',
        );
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final successfulReferrals = data['successfulReferrals'] as int? ?? 0;
      final totalXpEarned = data['totalReferralXpEarned'] as int? ?? 0;
      final referralCode = data['referralCode'] as String? ?? '';

      // Count pending referrals
      final pendingSnapshot = await _referralsCollection()
          .where('referrerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final pendingReferrals = pendingSnapshot.docs.length;

      return ReferralStats(
        totalReferrals: successfulReferrals,
        pendingReferrals: pendingReferrals,
        xpEarned: totalXpEarned,
        referralCode: referralCode,
        currentLevel: data['currentLevel'] as int? ?? 1,
      );
    } catch (e) {
      debugPrint('Error getting referral stats: $e');
      return ReferralStats(
        totalReferrals: 0,
        pendingReferrals: 0,
        xpEarned: 0,
        referralCode: '',
      );
    }
  }

  /// Generates a referral link with tracking parameters
  String generateReferralLink(String referralCode) {
    return '$_baseUrl?code=$referralCode';
  }

  /// Generates a random referral code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1 for clarity
    final code = List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
    return 'EMERGE_$code';
  }

  /// Awards XP to referrer for successful referral
  Future<void> _awardReferralXp(
    String referrerId,
    String referredUserId,
    String referralCode,
  ) async {
    try {
      // Update referrer's stats
      await _userStatsRef(referrerId).set({
        'successfulReferrals': FieldValue.increment(1),
        'totalReferralXpEarned': FieldValue.increment(_xpReward),
        'referredUserIds': FieldValue.arrayUnion([referredUserId]),
      }, SetOptions(merge: true));

      // Log activity for XP
      await _firestore
          .collection('user_activity')
          .doc('${referrerId}_referral_$referredUserId')
          .set({
        'userId': referrerId,
        'type': 'referred_user',
        'sourceId': referredUserId,
        'xpEarned': _xpReward,
        'date': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Awarded $_xpReward XP to $referrerId for referral');
    } catch (e) {
      debugPrint('Error awarding referral XP: $e');
    }
  }
}

/// Referral statistics for a user
class ReferralStats {
  final int totalReferrals;
  final int pendingReferrals;
  final int xpEarned;
  final String referralCode;
  final int currentLevel;

  const ReferralStats({
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.xpEarned,
    required this.referralCode,
    this.currentLevel = 1,
  });

  @override
  String toString() {
    return 'ReferralStats(total: $totalReferrals, pending: $pendingReferrals, xp: $xpEarned)';
  }
}
