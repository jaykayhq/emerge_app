import 'package:emerge_app/core/init/init_app.dart';
import 'package:emerge_app/core/data/seed_runner.dart';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:sentry/sentry.dart';
import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/services/daily_insight_generator.dart';
import 'package:emerge_app/core/presentation/widgets/offline_banner.dart';
import 'package:emerge_app/core/presentation/widgets/email_verification_banner.dart';
import 'package:emerge_app/core/presentation/widgets/web_update_banner.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/providers/online_presence_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/data/services/habit_reminder_sync.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/core/drift_repositories/drift_tribe_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  await initApp();

  // Initialize ProviderContainer
  final container = ProviderContainer();

  // Start the sync trigger service (listens for connectivity changes)
  // Moved to _EmergeAppState.initState to avoid blocking startup

  // Seed local Drift tribe stats table so habit completions
  // before first tribe tab visit still update tribe stats
  // Moved to _EmergeAppState.initState to avoid blocking startup

  // Remote Config and Notifications are now initialized in parallel within initApp()
  // We only schedule the weekly recap here (which is fast)
  if (!kIsWeb) {
    unawaited(
      container.read(notificationServiceProvider).scheduleWeeklyRecap(),
    );
  }

  // Seed data is now handled by Firebase Admin SDK (functions/src/seed.ts)
  // Run: cd functions && npm run seed

  // Initialize AdMob test device configuration
  if (!kIsWeb) {
    // SECURITY: Only use test device IDs in debug builds.
    // In production, this will be an empty list, allowing real ads to show.
    //
    // To find your device's test ID, run the app in debug mode and look for:
    //   "Use RequestConfiguration.Builder().setTestDeviceIds(
    //     Arrays.asList("YOUR_DEVICE_HASH")) to get test ads"
    // in the terminal output. Add the hash below.
    if (!kIsWeb) {
      final testDeviceIds = kDebugMode
          ? ['31E09946B646AE0846AFCAB3B270684F']
          : const <String>[];
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
  }

  if (!kIsWeb) {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // Initialize Sentry for Web if a DSN is provided
    final sentryDsn = AppConfig.sentryDsn;
    if (sentryDsn.isNotEmpty) {
      await Sentry.init((options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
      });

      // Pass framework errors to Sentry
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        Sentry.captureException(details.exception, stackTrace: details.stack);
        if (originalOnError != null) {
          originalOnError(details);
        }
      };

      // Pass unhandled asynchronous errors to Sentry
      PlatformDispatcher.instance.onError = (error, stack) {
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };
    }
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

class _EmergeAppState extends ConsumerState<EmergeApp>
    with WidgetsBindingObserver {
  /// Last signed-in user id — used to refresh notification schedules (and
  /// thus the daily insight body) when the app returns to the foreground.
  String? _notificationsUserId;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heavyInitialization();
    });
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    super.dispose();
  }

  /// Listens for mobile deep links (emergeapp://verify-email?oobCode=...)
  /// and routes the user straight to the verification screen. On web the
  /// same flow works through the browser URL (query param on
  /// /verify-email) — no handler needed. Web builds of app_links return
  /// no links, so this is mobile-only in practice. Verification emails are
  /// sent natively by Firebase Auth (web action URL); this handler is a
  /// fallback for any future custom-scheme link.
  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (initial != null) _routeDeepLink(initial);
      _deepLinkSub = appLinks.uriLinkStream.listen(_routeDeepLink);
    } catch (e, s) {
      AppLogger.w('Deep link listener failed to start', error: e, stackTrace: s);
    }
  }

  void _routeDeepLink(Uri uri) {
    if (uri.host == 'verify-email') {
      final oobCode = uri.queryParameters['oobCode'];
      if (oobCode == null || oobCode.isEmpty) return;
      try {
        ref.read(routerProvider).push('/verify-email?oobCode=$oobCode');
      } catch (e) {
        AppLogger.w('Deep link routing failed', error: e);
      }
      return;
    }
    if (uri.host == 'reset-password') {
      final oobCode = uri.queryParameters['oobCode'];
      if (oobCode == null || oobCode.isEmpty) return;
      try {
        ref.read(routerProvider).push('/reset-password?oobCode=$oobCode');
      } catch (e) {
        AppLogger.w('Deep link routing failed', error: e);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resync on resume so the daily insight body reflects fresh stats
    // instead of replaying the message frozen at schedule time.
    if (state == AppLifecycleState.resumed) {
      final userId = _notificationsUserId;
      if (userId != null) {
        unawaited(_resyncNotifications(userId));
      }
    }
  }

  void _heavyInitialization() {
    // Start the sync trigger service (listens for connectivity changes)
    ref.read(syncTriggerServiceProvider);

    // Start incoming sync listener (pulls Firestore data into Drift on auth)
    ref.read(incomingSyncListenerProvider);

    // Seed local Drift tribe stats table so habit completions
    // before first tribe tab visit still update tribe stats
    final tribeRepo = ref.read(tribeRepositoryProvider);
    if (tribeRepo is DriftTribeRepository) {
      unawaited(tribeRepo.seedTribesIfEmpty());
    }
  }

  /// Resyncs client-managed notifications for [userId] on every login:
  /// - daily AI insight (idempotent same-id replace; cancelled when off)
  /// - recurring reminders for existing habits with a set reminder time
  /// Gated by the user's notification settings from Drift.
  Future<void> _resyncNotifications(String userId) async {
    if (kIsWeb) return;
    final profile = await ref.read(userStatsStreamProvider.future);
    if (profile.uid.isEmpty) return;
    final settings = profile.settings;
    final notificationService = ref.read(notificationServiceProvider);

    // 1. Daily AI insight
    if (settings.notificationsEnabled && settings.aiInsights) {
      final insight = generateDailyInsight(
        level: profile.avatarStats.level,
        streak: profile.avatarStats.streak,
        totalXp: profile.avatarStats.totalXp,
      );
      await notificationService.scheduleDailyInsight(
        userId,
        insight,
        profile.archetype,
      );
    } else {
      await notificationService.cancelDailyInsight(userId);
    }

    // 2. Habit reminders for existing habits (new habits are scheduled by
    // createHabit; this covers pre-existing habits and reinstalls).
    await resyncHabitReminders(
      notificationService: notificationService,
      habitRepository: ref.read(habitRepositoryProvider),
      profile: profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to start/stop heartbeat and sync monetization identity
    ref.listen(authStateChangesProvider, (previous, next) {
      final presenceService = ref.read(onlinePresenceServiceProvider);
      final monetizationRepo = ref.read(monetizationRepositoryProvider);

      next.when(
        data: (user) {
          if (user.id.isNotEmpty) {
            _notificationsUserId = user.id;
            // User signed in - start heartbeat and identify in RevenueCat
            presenceService.startHeartbeat(user.id);
            unawaited(monetizationRepo.identify(user.id));

            // Seed initial data once authenticated - safe as these check for existing data
            // (seedChallenges was removed: the client write is denied by the
            // admin-only Firestore rules and failed into a debugPrint catch;
            // challenges are seeded server-side and by verified creators).
            unawaited(seedBlueprints());

            // Client-managed notifications (replaces the Cloud Scheduler's
            // daily-insight push): resync on every login so schedules exist
            // after reinstall and reflect current settings.
            unawaited(_resyncNotifications(user.id));
          } else {
            _notificationsUserId = null;
            presenceService.stopHeartbeat();
            unawaited(monetizationRepo.reset());
          }
        },
        loading: () => null,
        error: (_, _) {
          presenceService.stopHeartbeat();
          unawaited(monetizationRepo.reset());
        },
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

    // Only watch currentArchetype if user is logged in
    // This prevents unnecessary rebuilds on XP/stat updates
    if (isLoggedIn) {
      final currentArchetype = ref.watch(currentArchetypeProvider);
      archetype = ArchetypeTheme.forArchetype(currentArchetype);
    }

    return MaterialApp.router(
      title: 'Emerge',
      theme: AppTheme.lightTheme(archetype),
      darkTheme: AppTheme.darkTheme(archetype),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return EmailVerificationBanner(
          child: WebUpdateBanner(
            child: OfflineBanner(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
