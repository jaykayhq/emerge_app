import 'dart:async';
import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _createMockProfile({int level = 1}) {
  final totalXp = (level - 1) * GamificationConstants.xpPerLevel;
  return UserProfile(
    uid: 'test_uid',
    displayName: 'Test User',
    avatarStats: UserAvatarStats(
      level: level,
      strengthXp: totalXp ~/ 6,
      intellectXp: totalXp ~/ 6,
      vitalityXp: totalXp ~/ 6,
      creativityXp: totalXp ~/ 6,
      focusXp: totalXp ~/ 6,
      spiritXp: totalXp ~/ 6,
    ),
    worldState: const UserWorldState(),
  );
}

final _goRouter = GoRouter(
  initialLocation: '/leveling',
  routes: [
    GoRoute(path: '/leveling', builder: (_, _) => const LevelingScreen()),
    GoRoute(path: '/', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
    GoRoute(path: '/profile/settings', builder: (_, _) => const SizedBox()),
  ],
);

Widget _createTestWidget({int level = 1}) {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(_createMockProfile(level: level)),
      ),
      worldThemeProvider.overrideWith(WorldThemeNotifier.new),
      worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
      worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
      companionRepositoryProvider.overrideWith((ref) => CompanionRepository()),
    ],
    child: MaterialApp.router(routerConfig: _goRouter),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/gamification': true,
    });
    final repo = CompanionRepository();
    await repo.init();
  });

  group('LevelingScreen', () {
    Future<void> pumpScreen(WidgetTester tester, {int level = 1}) async {
      await tester.pumpWidget(_createTestWidget(level: level));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: _goRouter),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders level circle with correct level number',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 3);

      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows progress text to next level', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 1);

      expect(find.textContaining('Progress to Level 2'), findsOneWidget);
    });

    testWidgets('shows rewards section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 5);

      expect(find.text('Next Level Rewards'), findsOneWidget);
    });

    testWidgets('renders the Continue Journey CTA button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 2);

      expect(find.text('CONTINUE JOURNEY'), findsOneWidget);
    });

    testWidgets('displays first level for new user', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 1);

      expect(find.text('1'), findsOneWidget);
    });
  });
}
