import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/monetization/data/repositories/revenue_cat_repository.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emerge_app/firebase_options.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Mobile Ads (AdMob)
  await MobileAds.instance.initialize();

  // Initialize RevenueCat
  await RevenueCatRepository().initialize();

  // Initialize Hive and Local Settings
  await LocalSettingsRepository().init();

  // Initialize FCM
  await NotificationService().initialize();
}
