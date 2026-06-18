import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/profile/presentation/screens/future_self_studio_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';

class _MockIsPremium extends IsPremium {
  @override
  Future<bool> build() async => false;
}

final testAvatarStats = UserAvatarStats(
  level: 3,
  streak: 5,
  strengthXp: 200,
  intellectXp: 300,
  vitalityXp: 150,
  creativityXp: 100,
  focusXp: 250,
  spiritXp: 50,
  challengeXp: 25,
);

final testProfile = UserProfile(
  uid: 'test-uid',
  displayName: 'Test User',
  archetype: UserArchetype.athlete,
  avatarStats: testAvatarStats,
  hasEmerged: false,
);

Widget createTest() {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(testProfile),
      ),
      authStateChangesProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(testProfile),
      ),
      habitsProvider.overrideWith((ref) => Stream.value(<Habit>[])),
      isPremiumProvider.overrideWith(() => _MockIsPremium()),
      isVerifiedCreatorProvider.overrideWith((ref) => Future.value(false)),
    ],
    child: const MaterialApp(
      home: FutureSelfStudioScreen(),
    ),
  );
}

void main() {
  testWidgets('renders loading skeleton initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: const MaterialApp(
          home: FutureSelfStudioScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Error:'), findsNothing);
  });

  testWidgets('renders profile data', (tester) async {
    await tester.pumpWidget(createTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('FUTURE SELF'), findsOneWidget);
    expect(find.textContaining('Archetype'), findsOneWidget);
    expect(find.textContaining('LVL'), findsWidgets);
    expect(find.textContaining('XP'), findsWidgets);
  });

  testWidgets('renders without crashing on stream error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.error(Exception('Test error')),
          ),
        ],
        child: const MaterialApp(
          home: FutureSelfStudioScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FutureSelfStudioScreen), findsOneWidget);
  });
}
