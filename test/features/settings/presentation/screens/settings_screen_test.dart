import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}
class _MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class _MockCompanionRepository extends Mock implements CompanionRepository {}

class FakeDriftUserStatsRepository extends DriftUserStatsRepository {
  FakeDriftUserStatsRepository()
      : super(_MockAppDatabase(), _MockSyncEngine());
}

class FakeWorldThemeNotifier extends WorldThemeNotifier {
  @override
  AppWorldTheme build() => AppWorldTheme.nebula;
}

class FakeIsPremium extends IsPremium {
  final bool premium;
  FakeIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

final testUser = AuthUser(id: 'test-uid', email: 'test@example.com', displayName: 'Test User');

final testProfile = UserProfile(
  uid: 'test-uid',
  settings: const UserSettings(soundsEnabled: true),
);

Widget createTest() {
  final mockCompanionRepo = _MockCompanionRepository();
  when(() => mockCompanionRepo.migrateFromTutorials()).thenAnswer((_) async {});
  when(() => mockCompanionRepo.isCompanionEnabled()).thenReturn(true);
  when(() => mockCompanionRepo.hasVisited(any())).thenReturn(true);

  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(testProfile),
      ),
      userStatsRepositoryProvider.overrideWith(
        (ref) => FakeDriftUserStatsRepository(),
      ),
      themeControllerProvider.overrideWithValue(ThemeMode.dark),
      companionRepositoryProvider.overrideWith(
        (ref) => mockCompanionRepo,
      ),
      worldThemeProvider.overrideWith(() => FakeWorldThemeNotifier()),
      isPremiumProvider.overrideWith(() => FakeIsPremium(false)),
      worldHealthStreamProvider.overrideWith(
        (ref) => Stream.value(0.5),
      ),
      worldEntropyStreamProvider.overrideWith(
        (ref) => Stream.value(0.0),
      ),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
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
}
