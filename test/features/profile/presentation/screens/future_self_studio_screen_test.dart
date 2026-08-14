import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_header.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/profile/presentation/screens/future_self_studio_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/spotlight_painter.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';

class _GuideSettings extends LocalSettingsRepository {
  @override
  bool isTutorialsEnabled() => true;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async => false;
}

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

Widget createTest({LocalSettingsRepository? settings}) {
  return ProviderScope(
    overrides: [
      if (settings != null)
        localSettingsRepositoryProvider.overrideWithValue(settings),
      userStatsStreamProvider.overrideWith((ref) => Stream.value(testProfile)),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      userProfileProvider.overrideWith((ref) => Stream.value(testProfile)),
      habitsProvider.overrideWith((ref) => Stream.value(<Habit>[])),
      isPremiumProvider.overrideWith(() => _MockIsPremium()),
      isVerifiedCreatorProvider.overrideWith((ref) => Future.value(false)),
    ],
    child: const MaterialApp(home: FutureSelfStudioScreen()),
  );
}

void main() {
  testWidgets('renders loading skeleton initially', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(home: FutureSelfStudioScreen()),
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

    // The redundant shared EmergeHeader was removed; the SliverAppBar with
    // its settings action remains the only top chrome.
    expect(find.byType(EmergeHeader), findsNothing);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('renders without crashing on stream error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.error(Exception('Test error')),
          ),
        ],
        child: const MaterialApp(home: FutureSelfStudioScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FutureSelfStudioScreen), findsOneWidget);
  });

  testWidgets('resolves the Future Self guide header as a spotlight target', (
    tester,
  ) async {
    await tester.pumpWidget(createTest(settings: _GuideSettings()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(NarratorGuideCard), findsOneWidget);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<SpotlightPainter>()
        .first;
    expect(painter.holeRect, isNotNull);
  });

  testWidgets('guide scrolls to the Future Self action on Next', (
    tester,
  ) async {
    await tester.pumpWidget(createTest(settings: _GuideSettings()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Next →'));
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));

    final viewport = tester.getRect(find.byType(CustomScrollView));
    final emergeButton = tester.getRect(find.text('EMERGE'));
    expect(viewport.overlaps(emergeButton), isTrue);
    expect(
      find.textContaining('Press this when the vision is ready'),
      findsOneWidget,
    );
  });
}
