import 'package:emerge_app/core/constants/gamification_constants.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/level_up_reward_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserProfile _createMockProfile({
  int level = 2,
  int streak = 0,
  UserArchetype archetype = UserArchetype.scholar,
}) {
  final totalXp = (level - 1) * GamificationConstants.xpPerLevel;
  return UserProfile(
    uid: 'test_uid',
    displayName: 'Test User',
    archetype: archetype,
    avatarStats: UserAvatarStats(
      level: level,
      streak: streak,
      strengthXp: totalXp ~/ 6,
      intellectXp: totalXp ~/ 6,
      vitalityXp: totalXp ~/ 6,
      creativityXp: totalXp ~/ 6,
      focusXp: totalXp ~/ 6,
      spiritXp: totalXp ~/ 6,
      lastCelebratedLevel: level - 1,
    ),
    worldState: const UserWorldState(),
  );
}

Widget _createTestWidget({int celebratedLevel = 2}) {
  final goRouter = GoRouter(
    initialLocation: '/level-up/$celebratedLevel',
    routes: [
      GoRoute(
        path: '/level-up/:level',
        builder: (_, state) {
          final level =
              int.tryParse(state.pathParameters['level'] ?? '2') ?? 2;
          return LevelUpRewardScreen(celebratedLevel: level);
        },
      ),
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
    ],
  );

  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(_createMockProfile(level: celebratedLevel)),
      ),
      worldThemeProvider.overrideWith(WorldThemeNotifier.new),
      worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
      worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
    ],
    child: MaterialApp.router(routerConfig: goRouter),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LevelUpRewardScreen', () {
    Future<void> pumpScreen(WidgetTester tester, {int level = 2}) async {
      await tester.pumpWidget(_createTestWidget(celebratedLevel: level));
      await tester.pump();
    }

    testWidgets('renders celebration screen with level and stats',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 2);

      expect(find.textContaining('Level 2'), findsWidgets);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Total XP Earned'), findsOneWidget);
    });

    testWidgets('renders next level unlocks section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 3);

      expect(find.text('Next Level Unlocks'), findsOneWidget);
      expect(find.text('Habit Slot Unlock'), findsOneWidget);
      expect(find.text('XP Boost'), findsOneWidget);
    });

    testWidgets('renders milestone unlocks for level 5 milestone',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 4);

      // Verify level 4 display
      expect(find.textContaining('Level 4'), findsWidgets);

      // Milestone: celebratedLevel=4 => nextLevel=5 => 5%5==0 => milestone
      expect(find.text('Next Level Unlocks'), findsOneWidget);
      expect(find.text('New Archetype Ability'), findsOneWidget);
      expect(find.text('Cosmetic Upgrade'), findsOneWidget);
      expect(find.text('Streak Bonus Multiplier'), findsOneWidget);
    });

    testWidgets('Customize Persona button is present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await pumpScreen(tester, level: 2);

      expect(find.text('Customize Persona'), findsOneWidget);
    });

    testWidgets('displays streak from stats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final goRouter = GoRouter(
        initialLocation: '/level-up/4',
        routes: [
          GoRoute(
            path: '/level-up/:level',
            builder: (_, state) => LevelUpRewardScreen(
              celebratedLevel: 4,
            ),
          ),
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_createMockProfile(level: 4, streak: 7)),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith(
                (ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith(
                (ref) => Stream.value(0.0)),
          ],
          child: MaterialApp.router(routerConfig: goRouter),
        ),
      );
      await tester.pump();

      expect(find.text('7 Days'), findsOneWidget);
    });
  });
}
