import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/security/app_check_service.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emerge_app/firebase_options.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (no-op on web but guard for clarity)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Remote Config (must be before RevenueCat for API key fetching)
  try {
    await AppConfig.initializeRemoteConfig();
    debugPrint('✅ Remote Config initialized');
  } catch (e) {
    debugPrint('⚠️ Remote Config initialization failed: $e');
    debugPrint('💡 Will use compile-time environment variables as fallback');
  }

  // Initialize Firebase App Check
  try {
    await AppCheckService.initialize();
  } catch (e) {
    debugPrint('⚠️ Continuing without App Check due to initialization error');
  }

  // Initialize Google Mobile Ads (AdMob) - not supported on web
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Initialize RevenueCat (not supported on web)
  if (!kIsWeb) {
    try {
      final revenueCatRepo = RevenueCatRepository();
      await revenueCatRepo.initialize();

      debugPrint('✅ RevenueCat initialized successfully');

      try {
        final customerInfo = await revenueCatRepo.getCustomerInfoRaw();
        if (customerInfo != null) {
          debugPrint('✅ RevenueCat API key verified - can fetch customer info');
          debugPrint('📊 Customer ID: ${customerInfo.originalAppUserId}');
        } else {
          debugPrint('ℹ️ RevenueCat not configured - monetization disabled');
        }
      } catch (e) {
        debugPrint('⚠️ RevenueCat initialized but API verification failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ RevenueCat initialization failed: $e');
      debugPrint(
        '💡 Set REVENUECAT_GOOGLE_API_KEY environment variable to enable monetization',
      );
      debugPrint(
        '🔧 The app will continue without RevenueCat. Premium features will be unavailable.',
      );
    }
  }

  // Initialize Hive and Local Settings
  await LocalSettingsRepository().init();

  // Initialize FCM (handled differently on web)
  if (!kIsWeb) {
    await NotificationService().initialize();
  }
}
