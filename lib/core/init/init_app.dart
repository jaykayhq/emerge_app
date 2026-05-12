import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/security/app_check_service.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emerge_app/firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Environment Variables first so they are available to other services
  // On web, flutter_dotenv fetches .env via HTTP and throws if not served as an asset.
  // We skip loading on web and fall back to AppConfig defaults/hardcoded values.
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ .env loaded');
    } catch (e) {
      debugPrint('ℹ️ .env file not found - using defaults');
    }
  } else {
    debugPrint('ℹ️ Skipping .env load on web - using defaults');
  }

  // Set preferred orientations (no-op on web but guard for clarity)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Initialize Firebase (Required before all others)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Cache (Hive) eagerly so localCacheServiceProvider is
  // synchronous throughout the app. This MUST be called before runApp().
  if (!kIsWeb) {
    try {
      await LocalCacheService.initialize();
      debugPrint('✅ LocalCacheService (Hive) initialized');
    } catch (e) {
      debugPrint('⚠️ LocalCacheService initialization failed: $e');
    }
  }

  // Enable Firestore Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  debugPrint('✅ Firestore offline persistence enabled');

  // Initialize App Check immediately after Firebase and BEFORE any other Firebase service
  if (AppConfig.enableFirebaseAppCheck) {
    try {
      await AppCheckService.initialize();
      debugPrint('✅ App Check initialized');
    } catch (e) {
      debugPrint('⚠️ App Check initialization failed: $e');
    }
  } else {
    debugPrint('⚠️ Firebase App Check is disabled via config');
  }

  // Seed initial data (handled post-login or via admin script)
  // Seeding calls removed from here to prevent permission errors before authentication.

  // 1. Initialize Remote Config first (as other services may depend on its values)
  try {
    await AppConfig.initializeRemoteConfig();
    debugPrint('✅ Remote Config initialized');
  } catch (e) {
    debugPrint('⚠️ Remote Config initialization failed: $e');
  }

  // 2. Parallelize the remaining initializations to reduce startup time
  // Each task is wrapped in its own try-catch to ensure one failure doesn't block the others
  await Future.wait([
    // AdMob with UMP SDK Consent
    () async {
      if (!kIsWeb) {
        try {
          final params = ConsentRequestParameters();
          ConsentInformation.instance.requestConsentInfoUpdate(
            params,
            () async {
              if (await ConsentInformation.instance.isConsentFormAvailable()) {
                ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
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

    // Local Storage (Hive)
    () async {
      try {
        await LocalSettingsRepository().init();
        // LocalCacheService is already initialized above via LocalCacheService.initialize()
        debugPrint('✅ Local Storage (Hive) initialized');
      } catch (e) {
        debugPrint('⚠️ Local Storage initialization failed: $e');
      }
    }(),

    // Notifications & FCM
    () async {
      if (!kIsWeb) {
        try {
          await NotificationService().initialize();
          debugPrint('✅ Notifications initialized');
        } catch (e) {
          debugPrint('⚠️ Notification initialization failed: $e');
        }
      }
    }(),
  ]);
}
