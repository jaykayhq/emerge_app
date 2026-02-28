import 'package:emerge_app/core/init/init_app.dart';
import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  await initApp();

  // Initialize Environment Variables (optional - continues if .env doesn't exist)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file not found - using default configuration');
  }

  // Initialize Remote Config
  final container = ProviderContainer();
  await container.read(remoteConfigServiceProvider).initialize();

  // Initialize Firebase AI (Gemini)
  // Note: Model initialization will happen in the AiService when needed.
  // We just ensure Firebase is ready (which initApp does).

  // Initialize Notification Service
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize();
  await notificationService.scheduleWeeklyRecap();

  // Seed data is now handled by Firebase Admin SDK (functions/src/seed.ts)
  // Run: cd functions && npm run seed

  // Initialize AdMob
  if (!kIsWeb) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['969B3D2A344E9087F453B5A0415B8136']),
    );
  }

  if (!kIsWeb) {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Ensure user is signed in anonymously if not already signed in
  // This is required for Firestore permission checks during onboarding
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('Signed in anonymously');
    }
  } catch (e) {
    debugPrint('Failed to sign in anonymously: $e');
  }

  // Register background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    UncontrolledProviderScope(container: container, child: const EmergeApp()),
  );
}

class EmergeApp extends ConsumerWidget {
  const EmergeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    // Default to Explorer if loading/error or no archetype
    final archetype = userStatsAsync.maybeWhen(
      data: (profile) => ArchetypeTheme.forArchetype(profile.archetype),
      orElse: () => ArchetypeTheme.forArchetype(UserArchetype.none),
    );

    return MaterialApp.router(
      title: 'Emerge',
      theme: AppTheme.lightTheme(archetype),
      darkTheme: AppTheme.darkTheme(archetype),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
