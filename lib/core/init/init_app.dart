import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/security/app_check_service.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

  // On web, call getRedirectResult() to consume any pending Google OAuth
  // credential after signInWithRedirect() completes. Firebase stores the
  // credential in IndexedDB across the page navigation; without this call
  // the auth state won't update after the OAuth redirect returns.
  // Also creates a Firestore user profile for first-time Google sign-ins,
  // since the signInWithGoogle() method cannot do this synchronously after
  // a redirect (the page navigates away before profile creation code runs).
  if (kIsWeb) {
    try {
      final redirectResult =
          await firebase_auth.FirebaseAuth.instance.getRedirectResult();
      final user = redirectResult.user;
      if (user != null) {
        debugPrint(
          '✅ Google redirect result captured: ${user.email}',
        );
        // Create Firestore profile if this is a first-time sign-in
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          final displayName = user.displayName?.isNotEmpty == true
              ? user.displayName!
              : user.email?.split('@').first ?? 'User';
          final profile = UserProfile(uid: user.uid, displayName: displayName);
          final profileMap = profile.toMap();
          profileMap['email'] = user.email ?? '';
          profileMap['createdAt'] = FieldValue.serverTimestamp();
          await firestore.collection('users').doc(user.uid).set(profileMap);
          await firestore
              .collection('user_stats')
              .doc(user.uid)
              .set(profileMap);
          debugPrint('✅ Firestore profile created for Google sign-in user');
        }
      }
    } catch (e) {
      debugPrint('⚠️ getRedirectResult error (non-fatal): $e');
    }
  }

  // On web, eagerly open the Drift WASM database so the LazyDatabase connection
  // is fully established before any Riverpod provider issues a synchronous DAO
  // access. Without this, the first provider to touch a DAO hits a null executor
  // inside the Drift internals (dart2js minified as '.a') and crashes.
  if (kIsWeb) {
    try {
      // A lightweight custom query forces the LazyDatabase to open the WASM
      // SQLite connection and makes the executor non-null for all future callers.
      await AppDatabase.instance.customSelect('SELECT 1').get();
      debugPrint('✅ Drift WASM database warmed up');
    } catch (e) {
      debugPrint('⚠️ Drift WASM warm-up failed: $e');
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
                    await MobileAds.instance
                        .initialize(); // Init anyway if error per AdMob docs
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

    // Local Settings
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
