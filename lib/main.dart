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

void main() async {
  await initApp();

  // Initialize Environment Variables
  await dotenv.load(fileName: ".env");

  // Initialize Remote Config
  final container = ProviderContainer();
  await container.read(remoteConfigServiceProvider).initialize();

  // Initialize Firebase AI (Gemini)
  // Note: Model initialization will happen in the AiService when needed.
  // We just ensure Firebase is ready (which initApp does).

  // Initialize Notification Service
  await container.read(notificationServiceProvider).initialize();

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

    return MaterialApp.router(
      title: 'Emerge',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
