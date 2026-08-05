import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/theme/theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/data/services/manage_premium_service.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class FakeDriftUserStatsRepository extends DriftUserStatsRepository {
  FakeDriftUserStatsRepository() : super(_MockAppDatabase(), _MockSyncEngine());
}

class FakeWorldThemeNotifier extends WorldThemeNotifier {
  final List<AppWorldTheme> setCalls = [];

  @override
  AppWorldTheme build() => AppWorldTheme.nebula;

  @override
  Future<void> setTheme(AppWorldTheme theme) async {
    setCalls.add(theme);
    await super.setTheme(theme); // real guard runs: locked calls no-op
  }
}

class FakeIsPremium extends IsPremium {
  final bool premium;
  FakeIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

class _FakeMonetizationRepository implements MonetizationRepository {
  int openManageCalls = 0;
  @override
  Future<Either<String, bool>> openManageSubscription() async {
    openManageCalls++;
    return const Right(true);
  }

  // Unused members — fail loudly if touched.
  @override
  Future<Either<String, Map<String, String>>> getConsumablePrices(
    List<String> productIds,
  ) async => const Left('unused');
  @override
  Future<Either<String, bool>> get isPremium async => const Right(true);
  @override
  Future<Either<String, Offerings>> getOfferings() async =>
      const Left('unused');
  @override
  Future<void> identify(String uid) async {}
  @override
  Future<void> initialize({String? uid}) async {}
  @override
  Future<Either<String, bool>> purchaseConsumable(String productId) async =>
      const Left('unused');
  @override
  Future<Either<String, bool>> purchasePremium([Package? package]) async =>
      const Right(true);
  @override
  Future<Either<String, bool>> restorePurchases() async => const Right(true);
  @override
  Future<String?> get premiumPriceString async => '\$4.99/mo';
  @override
  Stream<bool> get premiumStatusStream => const Stream.empty();
  @override
  Future<void> reset() async {}
}

class _FakeCaller implements ManagePremiumCaller {
  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    return {'ok': true};
  }
}

class _FakeManagePremiumService extends ManagePremiumService {
  _FakeManagePremiumService() : super(_FakeCaller());

  @override
  Future<Either<String, void>> cancel() async => const Right(null);

  @override
  Future<Either<String, void>> pause() async => const Right(null);
}

/// In-memory settings store for the Tutorials section tests (mirrors
/// test/features/narrator/presentation/widgets/narrator_guide_host_test.dart).
class FakeSettings extends LocalSettingsRepository {
  FakeSettings({required this.tutorialsEnabled});
  final bool tutorialsEnabled;
  final List<bool> recorded = [];

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<void> setTutorialsEnabled(bool enabled) async {
    recorded.add(enabled);
  }

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async => false;

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {}
}

class FakeCoachAskQuota extends CoachAskQuotaController {
  FakeCoachAskQuota(this.quota);
  final CoachAskQuota quota;

  @override
  Future<CoachAskQuota> build() async => quota;
}

final testUser = AuthUser(
  id: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
);

final testProfile = UserProfile(
  uid: 'test-uid',
  settings: const UserSettings(soundsEnabled: true),
);

Widget createTest({
  FakeSettings? settings,
  bool premium = false,
  CoachAskQuota? quota,
  FakeWorldThemeNotifier? worldTheme,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      userStatsStreamProvider.overrideWith((ref) => Stream.value(testProfile)),
      userStatsRepositoryProvider.overrideWith(
        (ref) => FakeDriftUserStatsRepository(),
      ),
      themeControllerProvider.overrideWithValue(ThemeMode.dark),
      worldThemeProvider.overrideWith(
        () => worldTheme ?? FakeWorldThemeNotifier(),
      ),
      isPremiumProvider.overrideWith(() => FakeIsPremium(premium)),
      habitsProvider.overrideWith((ref) => Stream.value(const [])),
      userStreakProvider.overrideWith((ref) => Stream.value(0)),
      monetizationRepositoryProvider.overrideWithValue(
        _FakeMonetizationRepository(),
      ),
      managePremiumServiceProvider.overrideWithValue(
        _FakeManagePremiumService(),
      ),
      worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
      worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
      if (settings != null)
        localSettingsRepositoryProvider.overrideWithValue(settings),
      coachAskQuotaControllerProvider.overrideWith(
        () => FakeCoachAskQuota(
          quota ??
              CoachAskQuota(
                dateKey: CoachAskQuota.dateKeyFor(DateTime.now()),
                usedToday: 1,
                isPremium: premium,
              ),
        ),
      ),
    ],
    child: router != null
        ? MaterialApp.router(routerConfig: router)
        : const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('renders settings screen', (tester) async {
    await tester.pumpWidget(createTest());
    await tester.pump();
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('GENERAL'), findsOneWidget);
  });

  testWidgets('dark mode toggle exists', (tester) async {
    await tester.pumpWidget(createTest());
    await tester.pump();
    await tester.pump();

    expect(find.text('Dark Mode'), findsOneWidget);
  });

  testWidgets('Manage Subscription tile navigates to manage premium', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/manage-premium',
          builder: (_, _) => const ManagePremiumScreen(),
        ),
      ],
    );

    await tester.pumpWidget(createTest(premium: true, router: router));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Manage Subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Manage Premium'), findsOneWidget);
  });

  group('Tutorials section', () {
    testWidgets('renders toggle, replay tiles and the coach quota row', (
      tester,
    ) async {
      final settings = FakeSettings(tutorialsEnabled: true);
      await tester.pumpWidget(createTest(settings: settings));
      await tester.pump();
      await tester.pump();

      // Toggle defaults on with the "shown once" subtitle.
      expect(find.text('Show coach guides'), findsOneWidget);
      expect(find.text('Guides shown once on each screen'), findsOneWidget);

      // Replay tiles.
      expect(find.text('Replay coach guides'), findsOneWidget);
      expect(find.text('Replay onboarding'), findsOneWidget);

      // Quota row: usedToday 1 of 3 free asks -> 2 left.
      expect(find.text('2 of 3 coach asks left today'), findsOneWidget);
    });

    testWidgets(
      'toggling the switch disables tutorials and flips the subtitle',
      (tester) async {
        final settings = FakeSettings(tutorialsEnabled: true);
        await tester.pumpWidget(createTest(settings: settings));
        await tester.pump();
        await tester.pump();

        await tester.ensureVisible(find.text('Show coach guides'));
        await tester.tap(find.text('Show coach guides'));
        await tester.pump();
        await tester.pump();

        expect(settings.recorded, [false]);
        expect(find.text('Guides hidden'), findsOneWidget);
      },
    );

    testWidgets('premium override shows the unlimited coach-ask quota', (
      tester,
    ) async {
      final settings = FakeSettings(tutorialsEnabled: true);
      await tester.pumpWidget(createTest(settings: settings, premium: true));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Coach asks'));
      expect(find.text('Unlimited coach asks'), findsOneWidget);
    });
  });

  group('World theme lock', () {
    testWidgets('locked tiles show a COMING SOON chip', (tester) async {
      await tester.pumpWidget(createTest());
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Cosmic'));
      await tester.pump();

      // nebula unlocked; the other five themes locked.
      expect(find.text('COMING SOON'), findsNWidgets(5));
    });

    testWidgets(
      'tapping a locked tile shows the snackbar and selects nothing',
      (tester) async {
        final worldTheme = FakeWorldThemeNotifier();
        await tester.pumpWidget(createTest(worldTheme: worldTheme));
        await tester.pump();
        await tester.pump();

        await tester.ensureVisible(find.text('Living'));
        await tester.pump();
        await tester.tap(find.text('Living'));
        await tester.pump();

        expect(find.text('Coming soon'), findsOneWidget);
        expect(worldTheme.setCalls, isEmpty);
      },
    );

    testWidgets('tapping the unlocked theme selects it without a snackbar', (
      tester,
    ) async {
      final worldTheme = FakeWorldThemeNotifier();
      await tester.pumpWidget(createTest(worldTheme: worldTheme));
      await tester.pump();
      await tester.pump();

      await tester.ensureVisible(find.text('Cosmic'));
      await tester.pump();
      await tester.tap(find.text('Cosmic'));
      await tester.pump();

      expect(find.text('Coming soon'), findsNothing);
      expect(worldTheme.setCalls, [AppWorldTheme.nebula]);
    });
  });
}
