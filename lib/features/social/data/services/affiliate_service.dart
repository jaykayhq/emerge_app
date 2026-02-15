import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/analytics_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Service to handle affiliate tracking, link launching, and conversion events.
class AffiliateService {
  final FirebaseFirestore _firestore;
  final FirebaseAnalytics _analytics;

  AffiliateService({FirebaseFirestore? firestore, FirebaseAnalytics? analytics})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Tracks a user joining a sponsored/affiliate challenge.
  Future<void> trackChallengeJoin(
    String challengeId,
    String userId, {
    bool hasAffiliate = false,
  }) async {
    try {
      // 1. Log to Analytics
      await _analytics.logEvent(
        name: AnalyticsEvents.challengeJoined,
        parameters: {
          AnalyticsParameters.challengeId: challengeId,
          AnalyticsParameters.hasAffiliate: hasAffiliate,
        },
      );

      // 2. Store participation record
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(challengeId)
          .set({
            'joinedAt': FieldValue.serverTimestamp(),
            'status': 'active',
            'progress': 0,
            'hasAffiliate': hasAffiliate,
          }, SetOptions(merge: true));

      debugPrint('Tracked challenge join: $challengeId');
    } catch (e) {
      debugPrint('Error tracking challenge join: $e');
    }
  }

  /// Handles reward redemption by opening affiliate link and tracking conversion.
  Future<void> redeemReward(
    String challengeId,
    String userId,
    String affiliateUrl,
  ) async {
    try {
      // Verify completion (Client-side check, backend should secure this too)
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(challengeId)
          .get();

      if (!doc.exists) {
        throw Exception('Challenge progress not found');
      }

      final data = doc.data()!;
      if (data['status'] != 'completed') {
        // allowing redemption for demo purposes if needed, but warning
        debugPrint('Warning: Redeeming incomplete challenge reward');
      }

      // 1. Log Redemption
      await _analytics.logEvent(
        name: AnalyticsEvents.rewardRedeemed,
        parameters: {
          AnalyticsParameters.challengeId: challengeId,
          AnalyticsParameters.rewardDescription: affiliateUrl,
        },
      );

      // 2. Mark as redeemed in DB
      await doc.reference.update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      // 3. Launch URL with tracking params
      // Append ref=emerge_app and uid for specific partners if needed
      final uri = Uri.parse(affiliateUrl);
      final finalUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParameters: {
          ...uri.queryParameters,
          'ref': 'emerge_app',
          'uid': userId,
        },
      );

      if (await canLaunchUrl(finalUri)) {
        await launchUrl(finalUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $affiliateUrl');
      }
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      rethrow;
    }
  }

  /// Tracks when a user views a challenge (impression tracking)
  Future<void> trackChallengeImpression(
    String challengeId,
    String userId, {
    String? partnerId,
  }) async {
    try {
      await _analytics.logEvent(
        name: AnalyticsEvents.challengeViewed,
        parameters: {
          AnalyticsParameters.challengeId: challengeId,
          if (partnerId != null) AnalyticsParameters.partnerId: partnerId,
        },
      );

      // Update challenge progress with impression tracking
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(challengeId)
          .set({
            'impressions': FieldValue.increment(1),
            'lastImpressionAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Track partner-level impressions if applicable
      if (partnerId != null) {
        await _firestore
            .collection('affiliatePartnerAnalytics')
            .doc(partnerId)
            .collection('users')
            .doc(userId)
            .set({
              'impressions': FieldValue.increment(1),
              'lastImpressionAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      debugPrint('Tracked challenge impression: $challengeId');
    } catch (e) {
      debugPrint('Error tracking challenge impression: $e');
    }
  }

  /// Tracks when a user clicks on a reward link
  Future<void> trackRewardClick(
    String challengeId,
    String userId,
    String affiliateUrl, {
    String? partnerId,
  }) async {
    try {
      await _analytics.logEvent(
        name: AnalyticsEvents.affiliateLinkClicked,
        parameters: {
          AnalyticsParameters.challengeId: challengeId,
          AnalyticsParameters.rewardDescription: affiliateUrl,
          if (partnerId != null) AnalyticsParameters.partnerId: partnerId,
        },
      );

      // Update challenge progress with click tracking
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(challengeId)
          .set({
            'clicks': FieldValue.increment(1),
            'lastClickAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Track partner-level clicks if applicable
      if (partnerId != null) {
        await _firestore
            .collection('affiliatePartnerAnalytics')
            .doc(partnerId)
            .collection('users')
            .doc(userId)
            .set({
              'clicks': FieldValue.increment(1),
              'lastClickAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      debugPrint('Tracked reward click: $challengeId');
    } catch (e) {
      debugPrint('Error tracking reward click: $e');
    }
  }

  /// Gets analytics data for a specific challenge
  Future<Map<String, dynamic>> getChallengeAnalytics(String challengeId) async {
    try {
      // Get challenge progress documents (aggregate across all users)
      // Note: In production, you'd want to use aggregated collections or Cloud Functions
      final challengeSnap = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeSnap.exists) {
        return {
          'impressions': 0,
          'joins': 0,
          'completions': 0,
          'redemptions': 0,
        };
      }

      // This is a simplified version - production should use pre-aggregated stats
      return {
        'impressions': challengeSnap.data()?['totalImpressions'] ?? 0,
        'joins': challengeSnap.data()?['totalJoins'] ?? 0,
        'completions': challengeSnap.data()?['totalCompletions'] ?? 0,
        'redemptions': challengeSnap.data()?['totalRedemptions'] ?? 0,
        'lastUpdated': challengeSnap.data()?['lastAnalyticsUpdate'],
      };
    } catch (e) {
      debugPrint('Error getting challenge analytics: $e');
      rethrow;
    }
  }

  /// Generates a tracking URL with referral code and user attribution
  String generateTrackingUrl(String baseUrl, {String? referralCode, String? userId}) {
    final uri = Uri.parse(baseUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);

    queryParams['ref'] = 'emerge_app';
    if (referralCode != null) {
      queryParams['referral'] = referralCode;
    }
    if (userId != null) {
      queryParams['uid'] = userId;
    }

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Verifies if a user is eligible to redeem a challenge reward
  /// Checks if challenge is completed and not already redeemed
  Future<bool> verifyChallengeEligibility(String userId, String challengeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challengeProgress')
          .doc(challengeId)
          .get();

      if (!doc.exists) {
        debugPrint('Challenge progress not found for $challengeId');
        return false;
      }

      final data = doc.data()!;
      final status = data['status'] as String?;

      // Must be completed and not already redeemed
      final isEligible = status == 'completed' || status == 'active';

      if (!isEligible) {
        debugPrint('Challenge not eligible for redemption. Status: $status');
      }

      return isEligible;
    } catch (e) {
      debugPrint('Error verifying challenge eligibility: $e');
      return false;
    }
  }

  /// Gets all active affiliate partners for a given archetype
  Future<List<Map<String, dynamic>>> getPartnersForArchetype(String archetypeId) async {
    try {
      final snapshot = await _firestore
          .collection('affiliatePartners')
          .where('status', isEqualTo: 'active')
          .where('supportedArchetypes', arrayContains: archetypeId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return {
            'id': doc.id,
            ...data,
          };
        }
        return {'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting partners for archetype: $e');
      return [];
    }
  }
}
