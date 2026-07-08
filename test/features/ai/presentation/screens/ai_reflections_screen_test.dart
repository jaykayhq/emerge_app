import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';

class MockAiPersonalizationService extends Mock
    implements AiPersonalizationService {}

class MockCompanionRepository extends Mock
    implements CompanionRepository {}

class FakeIsPremium extends IsPremium {
  final bool premium;
  FakeIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

Widget createTest({
  List<Habit> habits = const [],
  bool isPremium = false,
  List<AiInsight> insights = const [],
  List<GoldilocksAdjustment> adjustments = const [],
}) {
  final mockService = MockAiPersonalizationService();
  when(
    () => mockService.generateIdentityInsights(
      any(),
      dominantMotive: any(named: 'dominantMotive'),
      archetype: any(named: 'archetype'),
    ),
  ).thenAnswer((_) async => insights);
  when(
    () => mockService.analyzeHabitPerformance(
      any(),
      dominantMotive: any(named: 'dominantMotive'),
      archetype: any(named: 'archetype'),
    ),
  ).thenAnswer((_) async => adjustments);

  final mockCompanionRepo = MockCompanionRepository();
  when(() => mockCompanionRepo.hasVisited(any())).thenReturn(true);
  when(() => mockCompanionRepo.isCompanionEnabled()).thenReturn(true);

  return ProviderScope(
    overrides: [
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
      isPremiumProvider.overrideWith(() => FakeIsPremium(isPremium)),
      aiPersonalizationServiceProvider.overrideWith((ref) => mockService),
      companionRepositoryProvider.overrideWith((ref) => mockCompanionRepo),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(UserProfile(uid: 'test-uid')),
      ),
    ],
    child: const MaterialApp(
      home: AiReflectionsScreen(),
    ),
  );
}

void main() {
  testWidgets('renders loading skeleton', (tester) async {
    final mockCompanionRepo = MockCompanionRepository();
    when(() => mockCompanionRepo.hasVisited(any())).thenReturn(true);
    when(() => mockCompanionRepo.isCompanionEnabled()).thenReturn(true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => const Stream.empty()),
          isPremiumProvider.overrideWith(() => FakeIsPremium(false)),
          aiPersonalizationServiceProvider.overrideWith(
            (ref) => MockAiPersonalizationService(),
          ),
          companionRepositoryProvider.overrideWith(
            (ref) => mockCompanionRepo,
          ),
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(UserProfile(uid: 'test-uid')),
          ),
        ],
        child: const MaterialApp(
          home: AiReflectionsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ORACLE REFLECTIONS'), findsOneWidget);

    // Fire the 500ms delayed timer to prevent pending timer error
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('shows reflections with data for premium user',
      (tester) async {
    final insights = [
      AiInsight(
        type: InsightType.identity,
        title: 'Test Identity',
        description: 'A test insight',
        action: 'Take action',
      ),
    ];

    await tester.pumpWidget(
      createTest(
        habits: [
          Habit(
            id: 'h1',
            userId: 'test-uid',
            title: 'Test Habit',
            frequency: HabitFrequency.daily,
            attribute: HabitAttribute.focus,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
        isPremium: true,
        insights: insights,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ORACLE REFLECTIONS'), findsOneWidget);
    expect(find.text('Test Identity'), findsOneWidget);

    // Fire the 500ms delayed timer to prevent pending timer error
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('shows premium discovery banner for free users',
      (tester) async {
    await tester.pumpWidget(createTest(isPremium: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unlock Oracle Coach'), findsOneWidget);

    // Fire the 500ms delayed timer to prevent pending timer error
    await tester.pump(const Duration(milliseconds: 500));
  });
}
