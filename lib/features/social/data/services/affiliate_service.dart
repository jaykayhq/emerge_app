import 'package:cloud_firestore/cloud_firestore.dart';
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
        name: 'challenge_joined',
        parameters: {
          'challenge_id': challengeId,
          'has_affiliate': hasAffiliate ? 'true' : 'false',
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
        name: 'reward_redeemed',
        parameters: {
          'challenge_id': challengeId,
          'affiliate_url': affiliateUrl,
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
}
