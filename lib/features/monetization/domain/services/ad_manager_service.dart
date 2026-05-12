import 'dart:io';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emerge_app/core/services/connectivity_service.dart';

final adManagerProvider = Provider<AdManagerService>((ref) {
  final isPremium = ref.watch(isPremiumProvider).value ?? false;
  final isConnected = ref.watch(isConnectedProvider);
  return AdManagerService(isPremium: isPremium, isConnected: isConnected);
});

class AdManagerService {
  final bool isPremium;
  final bool isConnected;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  static const String _lastInterstitialKey = 'last_interstitial_time';

  AdManagerService({required this.isPremium, required this.isConnected}) {
    if (!isPremium && isConnected) {
      _loadRewardedAd();
      _loadInterstitialAd();
    }
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConfig.getAdUnitId('rewarded', _platform),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConfig.getAdUnitId('interstitial', _platform),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showRewardedAd({required Function onRewarded, required Function onFailed}) async {
    if (isPremium) {
      onRewarded();
      return;
    }

    if (!isConnected) {
      onFailed();
      return;
    }

    if (_rewardedAd == null) {
      onFailed();
      _loadRewardedAd(); // Try loading for next time
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        onFailed();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onRewarded();
    });
    _rewardedAd = null;
  }

  Future<void> showInterstitialAd() async {
    if (isPremium) return;

    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastTimeMs = prefs.getInt(_lastInterstitialKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Rate limit: 1 per 12 hours (43200000 ms)
    if (now - lastTimeMs < 43200000 && AppConfig.isProduction) {
      debugPrint('Interstitial rate limited.');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
    await prefs.setInt(_lastInterstitialKey, now);
    _interstitialAd = null;
  }
}
