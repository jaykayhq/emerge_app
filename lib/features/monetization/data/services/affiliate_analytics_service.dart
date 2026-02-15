import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking affiliate partner performance,
/// challenge conversion funnels, and referral metrics.
class AffiliateAnalyticsService {
  final FirebaseFirestore _firestore;

  AffiliateAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets conversion funnel analytics for a specific challenge
  /// Tracks: impressions → joins → completions → redemptions
  Future<ConversionFunnel> getChallengeConversionFunnel(String challengeId) async {
    try {
      // In production, this should query pre-aggregated analytics collections
      // For now, we'll do a simplified query from challenge documents

      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        return ConversionFunnel(
          impressions: 0,
          joins: 0,
          completions: 0,
          redemptions: 0,
          joinRate: 0.0,
          completionRate: 0.0,
          redemptionRate: 0.0,
        );
      }

      final data = challengeDoc.data() as Map<String, dynamic>;
      final impressions = data['totalImpressions'] as int? ?? 0;
      final joins = data['totalJoins'] as int? ?? 0;
      final completions = data['totalCompletions'] as int? ?? 0;
      final redemptions = data['totalRedemptions'] as int? ?? 0;

      return ConversionFunnel(
        impressions: impressions,
        joins: joins,
        completions: completions,
        redemptions: redemptions,
        joinRate: impressions > 0 ? joins / impressions : 0.0,
        completionRate: joins > 0 ? completions / joins : 0.0,
        redemptionRate: completions > 0 ? redemptions / completions : 0.0,
      );
    } catch (e) {
      debugPrint('Error getting challenge funnel: $e');
      return ConversionFunnel(
        impressions: 0,
        joins: 0,
        completions: 0,
        redemptions: 0,
        joinRate: 0.0,
        completionRate: 0.0,
        redemptionRate: 0.0,
      );
    }
  }

  /// Gets revenue breakdown by affiliate partner for a date range
  Future<List<RevenueBreakdown>> getRevenueByPartner(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('affiliatePartnerAnalytics')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      // Group by partner
      final Map<String, RevenueBreakdown> partnerRevenue = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final partnerId = data['partnerId'] as String?;
        if (partnerId == null) continue;

        // Get partner details
        final partnerDoc = await _firestore
            .collection('affiliatePartners')
            .doc(partnerId)
            .get();

        if (!partnerDoc.exists) continue;

        final partnerData = partnerDoc.data() as Map<String, dynamic>;
        final partnerName = partnerData['name'] as String? ?? 'Unknown';
        final commissionRate = partnerData['commissionRate'] as double? ?? 0.0;

        if (!partnerRevenue.containsKey(partnerId)) {
          partnerRevenue[partnerId] = RevenueBreakdown(
            partnerId: partnerId,
            partnerName: partnerName,
            impressions: 0,
            clicks: 0,
            conversions: 0,
            revenue: 0.0,
            commissionRate: commissionRate,
          );
        }

        final breakdown = partnerRevenue[partnerId]!;
        partnerRevenue[partnerId] = RevenueBreakdown(
          partnerId: partnerId,
          partnerName: partnerName,
          impressions: breakdown.impressions + (data['impressions'] as int? ?? 0),
          clicks: breakdown.clicks + (data['clicks'] as int? ?? 0),
          conversions: breakdown.conversions + (data['conversions'] as int? ?? 0),
          revenue: breakdown.revenue + (data['revenue'] as double? ?? 0.0),
          commissionRate: commissionRate,
        );
      }

      return partnerRevenue.values.toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));
    } catch (e) {
      debugPrint('Error getting revenue by partner: $e');
      return [];
    }
  }

  /// Gets top performing challenges by completion rate
  Future<List<ChallengePerformance>> getTopPerformingChallenges({
    int limit = 10,
    String? category,
    DateTime? startDate,
  }) async {
    try {
      Query query = _firestore
          .collection('challenges')
          .where('status', isEqualTo: 'active')
          .orderBy('totalCompletions', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data()! as Map<String, dynamic>;
        final totalJoins = data['totalJoins'] as int? ?? 0;
        final totalCompletions = data['totalCompletions'] as int? ?? 0;

        return ChallengePerformance(
          challengeId: doc.id,
          title: data['title'] as String? ?? '',
          category: data['category'] as String? ?? '',
          totalJoins: totalJoins,
          totalCompletions: totalCompletions,
          completionRate: totalJoins > 0 ? totalCompletions / totalJoins : 0.0,
          xpAwarded: (data['totalXpAwarded'] as int? ?? 0),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting top performing challenges: $e');
      return [];
    }
  }

  /// Gets referral metrics for a date range
  Future<ReferralMetrics> getReferralMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalReferrals = 0;
      int completedReferrals = 0;
      int totalXpAwarded = 0;
      final List<String> referrerIds = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        if (status == 'completed') {
          completedReferrals++;
          totalXpAwarded += data['xpAwarded'] as int? ?? 0;

          final referrerId = data['referrerId'] as String?;
          if (referrerId != null && !referrerIds.contains(referrerId)) {
            referrerIds.add(referrerId);
          }
        }

        totalReferrals++;
      }

      return ReferralMetrics(
        totalReferrals: totalReferrals,
        completedReferrals: completedReferrals,
        pendingReferrals: totalReferrals - completedReferrals,
        totalXpAwarded: totalXpAwarded,
        uniqueReferrers: referrerIds.length,
        completionRate: totalReferrals > 0 ? completedReferrals / totalReferrals : 0.0,
      );
    } catch (e) {
      debugPrint('Error getting referral metrics: $e');
      return ReferralMetrics(
        totalReferrals: 0,
        completedReferrals: 0,
        pendingReferrals: 0,
        totalXpAwarded: 0,
        uniqueReferrers: 0,
        completionRate: 0.0,
      );
    }
  }

  /// Logs an analytics event for tracking
  Future<void> logAnalyticsEvent(AnalyticsEvent event) async {
    try {
      await _firestore.collection('analytics').add({
        'eventName': event.eventName,
        'parameters': event.parameters,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': event.userId,
      });

      debugPrint('Logged analytics event: ${event.eventName}');
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// Gets overall affiliate performance summary
  Future<AffiliateSummary> getAffiliateSummary(DateTime startDate) async {
    try {
      final endDate = DateTime(startDate.year, startDate.month + 1, 0);

      final revenueBreakdown = await getRevenueByPartner(startDate, endDate);
      final totalRevenue = revenueBreakdown.fold<double>(
        0.0,
        (total, item) => total + item.revenue,
      );

      final totalImpressions = revenueBreakdown.fold<int>(
        0,
        (total, item) => total + item.impressions,
      );

      final totalConversions = revenueBreakdown.fold<int>(
        0,
        (total, item) => total + item.conversions,
      );

      return AffiliateSummary(
        period: '${startDate.month}/${startDate.year}',
        totalRevenue: totalRevenue,
        totalImpressions: totalImpressions,
        totalConversions: totalConversions,
        conversionRate: totalImpressions > 0 ? totalConversions / totalImpressions : 0.0,
        topPartner: revenueBreakdown.isNotEmpty ? revenueBreakdown.first.partnerName : 'N/A',
        partnerCount: revenueBreakdown.length,
      );
    } catch (e) {
      debugPrint('Error getting affiliate summary: $e');
      return AffiliateSummary(
        period: '${startDate.month}/${startDate.year}',
        totalRevenue: 0.0,
        totalImpressions: 0,
        totalConversions: 0,
        conversionRate: 0.0,
        topPartner: 'N/A',
        partnerCount: 0,
      );
    }
  }
}

/// Conversion funnel metrics for a challenge
class ConversionFunnel {
  final int impressions;
  final int joins;
  final int completions;
  final int redemptions;
  final double joinRate;
  final double completionRate;
  final double redemptionRate;

  const ConversionFunnel({
    required this.impressions,
    required this.joins,
    required this.completions,
    required this.redemptions,
    required this.joinRate,
    required this.completionRate,
    required this.redemptionRate,
  });

  @override
  String toString() {
    return 'Funnel(impressions: $impressions, joins: $joins, completions: $completions, '
        'redemptions: $redemptions, joinRate: ${(joinRate * 100).toStringAsFixed(1)}%, '
        'completionRate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Revenue breakdown by partner
class RevenueBreakdown {
  final String partnerId;
  final String partnerName;
  final int impressions;
  final int clicks;
  final int conversions;
  final double revenue;
  final double commissionRate;

  const RevenueBreakdown({
    required this.partnerId,
    required this.partnerName,
    required this.impressions,
    required this.clicks,
    required this.conversions,
    required this.revenue,
    required this.commissionRate,
  });
}

/// Challenge performance metrics
class ChallengePerformance {
  final String challengeId;
  final String title;
  final String category;
  final int totalJoins;
  final int totalCompletions;
  final double completionRate;
  final int xpAwarded;

  const ChallengePerformance({
    required this.challengeId,
    required this.title,
    required this.category,
    required this.totalJoins,
    required this.totalCompletions,
    required this.completionRate,
    required this.xpAwarded,
  });
}

/// Referral metrics
class ReferralMetrics {
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final int totalXpAwarded;
  final int uniqueReferrers;
  final double completionRate;

  const ReferralMetrics({
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.totalXpAwarded,
    required this.uniqueReferrers,
    required this.completionRate,
  });
}

/// Affiliate summary for a time period
class AffiliateSummary {
  final String period;
  final double totalRevenue;
  final int totalImpressions;
  final int totalConversions;
  final double conversionRate;
  final String topPartner;
  final int partnerCount;

  const AffiliateSummary({
    required this.period,
    required this.totalRevenue,
    required this.totalImpressions,
    required this.totalConversions,
    required this.conversionRate,
    required this.topPartner,
    required this.partnerCount,
  });
}

/// Analytics event for logging
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> parameters;
  final String? userId;

  const AnalyticsEvent({
    required this.eventName,
    required this.parameters,
    this.userId,
  });
}
