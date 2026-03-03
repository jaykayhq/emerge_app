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

  // Initialize Firebase (Required before all others)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    // App Check
    () async {
      try {
        await AppCheckService.initialize();
      } catch (e) {
        debugPrint('⚠️ App Check initialization failed: $e');
      }
    }(),

    // AdMob
    () async {
      if (!kIsWeb) {
        try {
          await MobileAds.instance.initialize();
          debugPrint('✅ AdMob initialized');
        } catch (e) {
          debugPrint('⚠️ AdMob initialization failed: $e');
        }
      }
    }(),

    // RevenueCat
    () async {
      if (!kIsWeb) {
        try {
          final revenueCatRepo = RevenueCatRepository();
          await revenueCatRepo.initialize();
          debugPrint('✅ RevenueCat initialized');
          // Verification check is deferred/moved to internal repository logic or handled lazily
        } catch (e) {
          debugPrint('⚠️ RevenueCat initialization failed: $e');
        }
      }
    }(),

    // Local Storage (Hive)
    () async {
      try {
        await LocalSettingsRepository().init();
        debugPrint('✅ Local Settings initialized');
      } catch (e) {
        debugPrint('⚠️ Local Settings initialization failed: $e');
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
