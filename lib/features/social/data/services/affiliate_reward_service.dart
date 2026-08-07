import 'package:emerge_app/core/services/analytics_events.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/affiliate_reward.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);
typedef EventLogger = Future<void> Function(String name, Map<String, Object> parameters);

/// Opens a sponsored challenge's affiliate reward link and records the click.
///
/// Side effects are injected so the service is testable without Firebase or
/// the platform URL launcher.
class AffiliateRewardService {
  AffiliateRewardService({UrlOpener? openUrl, EventLogger? logEvent})
      : _openUrl = openUrl ?? _defaultOpenUrl,
        _logEvent = logEvent ?? _defaultLogEvent;

  final UrlOpener _openUrl;
  final EventLogger _logEvent;

  static Future<bool> _defaultOpenUrl(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> _defaultLogEvent(
    String name,
    Map<String, Object> parameters,
  ) =>
      FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);

  /// Validates the reward URL, records [AnalyticsEvents.affiliateLinkClicked],
  /// then opens the link. Returns whether the link was opened.
  Future<bool> claimReward({
    required Challenge challenge,
    required AffiliateReward reward,
    String? userId,
  }) async {
    try {
      final uri = Uri.tryParse(reward.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      await _logEvent(AnalyticsEvents.affiliateLinkClicked, {
        AnalyticsParameters.challengeId: challenge.id,
        AnalyticsParameters.challengeName: challenge.title,
        AnalyticsParameters.challengeCategory: challenge.category.name,
        AnalyticsParameters.partnerName: reward.sponsor,
        AnalyticsParameters.affiliateNetwork: reward.network.name,
        AnalyticsParameters.rewardDescription: reward.title,
        AnalyticsParameters.hasAffiliate: true,
        if (userId != null) AnalyticsParameters.userId: userId,
        if (challenge.affiliatePartnerId != null)
          AnalyticsParameters.partnerId: challenge.affiliatePartnerId!,
      });
      return _openUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
