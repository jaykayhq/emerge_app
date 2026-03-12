import 'package:emerge_app/core/init/init_app.dart';
import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/providers/online_presence_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
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

  // Initialize ProviderContainer
  final container = ProviderContainer();

  // Remote Config and Notifications are now initialized in parallel within initApp()
  // We only schedule the weekly recap here (which is fast)
  if (!kIsWeb) {
    unawaited(
      container.read(notificationServiceProvider).scheduleWeeklyRecap(),
    );
  }

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

  // Anonymous sign-in code removed to prevent uncontrolled sign-in

  // Register background messaging handler (not supported on web)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const EmergeApp()),
  );
}

class EmergeApp extends ConsumerStatefulWidget {
  const EmergeApp({super.key});

  @override
  ConsumerState<EmergeApp> createState() => _EmergeAppState();
}

class _EmergeAppState extends ConsumerState<EmergeApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to start/stop heartbeat
    ref.listen(authStateChangesProvider, (previous, next) {
      final presenceService = ref.read(onlinePresenceServiceProvider);

      next.when(
        data: (user) {
          // User signed in - start heartbeat
          presenceService.startHeartbeat(user.id);
        },
        loading: () => null,
        error: (_, _) => presenceService.stopHeartbeat(),
      );
    });
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    // Defer user stats loading to avoid blocking initial render
    // Use a lazy load pattern - only load when auth state is available
    final authState = ref.watch(authStateChangesProvider);
    final isLoggedIn = authState.hasValue && authState.value != null;

    // Default to Explorer theme initially, will update when user stats load
    ArchetypeTheme archetype = ArchetypeTheme.forArchetype(UserArchetype.none);

    // Only watch userStatsStreamProvider if user is logged in
    // This prevents unnecessary Firestore reads on splash/login screens
    if (isLoggedIn) {
      final userStatsAsync = ref.watch(userStatsStreamProvider);
      archetype = userStatsAsync.maybeWhen(
        data: (profile) => ArchetypeTheme.forArchetype(profile.archetype),
        orElse: () => ArchetypeTheme.forArchetype(UserArchetype.none),
      );
    }

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
