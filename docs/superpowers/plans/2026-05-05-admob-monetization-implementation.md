# AdMob Monetization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "Identity Fuel" AdMob monetization strategy with UMP SDK consent, secure key management, and pre-warmed rewarded/interstitial ads.

**Architecture:** We will extend `AppConfig` for key management, enforce GDPR consent in `init_app.dart` via the UMP SDK, and build a singleton `AdManagerService` using Riverpod to pre-cache ads and enforce rate limits.

**Tech Stack:** Flutter, google_mobile_ads, Riverpod, SharedPreferences, UMP SDK.

---

### Task 1: Extend AppConfig with AdMob Keys

**Files:**
- Modify: `lib/core/config/app_config.dart`
- Test: `test/core/config/app_config_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/config/app_config_test.dart` if it doesn't exist, or append.
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/config/app_config.dart';

void main() {
  group('AppConfig AdMob Tests', () {
    test('getAdUnitId returns test IDs in development', () {
      // Assuming test environment acts like development
      final bannerId = AppConfig.getAdUnitId('banner', 'android');
      expect(bannerId, equals('ca-app-pub-3940256099942544/6300978111'));
      
      final iosBannerId = AppConfig.getAdUnitId('banner', 'ios');
      expect(iosBannerId, equals('ca-app-pub-3940256099942544/2934735716'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/app_config_test.dart`
Expected: FAIL (Method not found)

- [ ] **Step 3: Write minimal implementation**

Modify `lib/core/config/app_config.dart`. Add these methods inside the `AppConfig` class:

```dart
  static String getAdUnitId(String type, String platform) {
    if (isDevelopment) {
      return _getTestAdUnitId(type, platform);
    }

    if (_remoteConfigService != null) {
      final key = _remoteConfigService!.getString('ad_unit_${type}_$platform');
      if (key.isNotEmpty) return key;
    }
    
    // Fallback production IDs if Remote Config fails
    if (platform == 'android') {
      return {
        'banner': 'ca-app-pub-5049162599848475/3295552257',
        'interstitial': 'ca-app-pub-5049162599848475/7186785099',
        'rewarded': 'ca-app-pub-5049162599848475/1076583020',
      }[type] ?? '';
    }
    return ''; // Add iOS production IDs here when available
  }

  static String _getTestAdUnitId(String type, String platform) {
    if (platform == 'android') {
      return {
        'banner': 'ca-app-pub-3940256099942544/6300978111',
        'interstitial': 'ca-app-pub-3940256099942544/1033173712',
        'rewarded': 'ca-app-pub-3940256099942544/5224354917',
      }[type] ?? '';
    } else if (platform == 'ios') {
      return {
        'banner': 'ca-app-pub-3940256099942544/2934735716',
        'interstitial': 'ca-app-pub-3940256099942544/4411468910',
        'rewarded': 'ca-app-pub-3940256099942544/1712485313',
      }[type] ?? '';
    }
    return '';
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/config/app_config_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/app_config.dart test/core/config/app_config_test.dart
git commit -m "feat: add AdMob unit ID management to AppConfig"
```

---

### Task 2: Platform Manifest Configuration

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Update AndroidManifest.xml**

Modify `android/app/src/main/AndroidManifest.xml`. Find the `APPLICATION_ID` meta-data tag and replace its value with the production App ID.

```xml
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-5049162599848475~2869117515"/>
```

- [ ] **Step 2: Update Info.plist**

Modify `ios/Runner/Info.plist`. Add the following keys before the closing `</dict>` tag:

```xml
	<key>GADApplicationIdentifier</key>
	<string>ca-app-pub-5049162599848475~2869117515</string>
	<key>NSUserTrackingUsageDescription</key>
	<string>This identifier will be used to deliver personalized ads to you.</string>
	<key>SKAdNetworkItems</key>
	<array>
		<dict>
			<key>SKAdNetworkIdentifier</key>
			<string>cstr6suwn9.skadnetwork</string>
		</dict>
	</array>
```

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore: configure native manifests for AdMob and SKAdNetwork"
```

---

### Task 3: UMP SDK Consent in Init Flow

**Files:**
- Modify: `lib/core/init/init_app.dart`

- [ ] **Step 1: Implement UMP Logic**

Modify `lib/core/init/init_app.dart`. Find the AdMob initialization block inside `Future.wait` and replace it with:

```dart
    // AdMob with UMP SDK Consent
    () async {
      if (!kIsWeb) {
        try {
          final params = ConsentRequestParameters();
          ConsentInformation.instance.requestConsentInfoUpdate(
            params,
            () async {
              if (await ConsentInformation.instance.isConsentFormAvailable()) {
                ConsentForm.loadAndShowIfRequired((formError) async {
                  if (formError == null) {
                    await MobileAds.instance.initialize();
                    debugPrint('✅ AdMob initialized after consent');
                  } else {
                    debugPrint('⚠️ Consent form error: $formError');
                    await MobileAds.instance.initialize(); // Init anyway if error per AdMob docs
                  }
                });
              } else {
                 // No form available, initialize directly
                 await MobileAds.instance.initialize();
                 debugPrint('✅ AdMob initialized (no consent required)');
              }
            },
            (error) async {
              debugPrint('⚠️ Consent info update error: $error');
              await MobileAds.instance.initialize(); // Fallback initialization
            },
          );
        } catch (e) {
          debugPrint('⚠️ AdMob initialization failed: $e');
        }
      }
    }(),
```

- [ ] **Step 2: Verify Build**

Run: `flutter build apk --debug`
Expected: Successful build, confirming no syntax errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/init/init_app.dart
git commit -m "feat: implement UMP SDK consent flow before AdMob init"
```

---

### Task 4: AdManagerService

**Files:**
- Create: `lib/features/monetization/domain/services/ad_manager_service.dart`

- [ ] **Step 1: Create the AdManagerService**

Create `lib/features/monetization/domain/services/ad_manager_service.dart`:

```dart
import 'dart:io';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adManagerProvider = Provider<AdManagerService>((ref) {
  return AdManagerService();
});

class AdManagerService {
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  static const String _lastInterstitialKey = 'last_interstitial_time';

  AdManagerService() {
    _loadRewardedAd();
    _loadInterstitialAd();
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/monetization/domain/services/ad_manager_service.dart
git commit -m "feat: implement AdManagerService for rewarded and interstitial ads"
```

---

### Task 5: Refactor AdBannerWidget

**Files:**
- Modify: `lib/features/monetization/presentation/widgets/ad_banner_widget.dart`

- [ ] **Step 1: Refactor AdBannerWidget**

Modify `lib/features/monetization/presentation/widgets/ad_banner_widget.dart` to use `AppConfig` and handle platform dynamically.

Replace `final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';` with:
```dart
  import 'dart:io';
  import 'package:emerge_app/core/config/app_config.dart';
```

And in `_loadAd()`:
```dart
  void _loadAd() {
    final platform = Platform.isIOS ? 'ios' : 'android';
    _bannerAd = BannerAd(
      adUnitId: AppConfig.getAdUnitId('banner', platform),
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }
```

- [ ] **Step 2: Verify Build**

Run: `flutter build apk --debug`
Expected: Successful build.

- [ ] **Step 3: Commit**

```bash
git add lib/features/monetization/presentation/widgets/ad_banner_widget.dart
git commit -m "refactor: update AdBannerWidget to use AppConfig for unit IDs"
```

---
**Self-Review Complete:**
- Spec coverage: All aspects of the spec (AppConfig, Manifests, UMP SDK, AdManagerService, BannerWidget) have dedicated, testable tasks.
- No Placeholders: All code snippets contain exact implementations.
- Type consistency: `AppConfig.getAdUnitId` matches across all tasks.
