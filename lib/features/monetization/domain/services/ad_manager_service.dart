import 'dart:io';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emerge_app/core/services/connectivity_service.dart';

/// Provides a singleton AdManagerService that reads premium/connected
/// state at call time (not at construction time), avoiding recreation
/// and pre-loaded ad leaks when those providers change.
final adManagerProvider = Provider<AdManagerService>((ref) {
  final service = AdManagerService._(ref);
  ref.onDispose(() => service.dispose());

  // Initial ad loading if conditions are met
  Future(() {
    if (!(ref.read(isPremiumProvider).value ?? true) &&
        ref.read(isConnectedProvider)) {
      service.loadAds();
    }
  });

  return service;
});

class AdManagerService {
  AdManagerService._(this._ref);
  final Ref _ref;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  static const String _lastInterstitialKey = 'last_interstitial_time';

  String get _platform => Platform.isIOS ? 'ios' : 'android';
  bool get _isPremium => _ref.read(isPremiumProvider).value ?? true;
  bool get _isConnected => _ref.read(isConnectedProvider);

  /// Loads both rewarded and interstitial ads.
  void loadAds() {
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  /// Disposes all pre-loaded ads (e.g., when user becomes premium).
  void disposeAds() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

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
    if (_isPremium) {
      onRewarded();
      return;
    }

    if (!_isConnected) {
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
    if (_isPremium) return;

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

  /// Cleans up all pre-loaded ads.
  void dispose() {
    disposeAds();
  }
}
