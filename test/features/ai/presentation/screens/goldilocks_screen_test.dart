import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/ai/presentation/screens/goldilocks_screen.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

class MockAiPersonalizationService extends Mock
    implements AiPersonalizationService {}

Widget createTest({
  List<Habit> habits = const [],
  List<GoldilocksAdjustment> adjustments = const [],
}) {
  final mockService = MockAiPersonalizationService();
  when(
    () => mockService.analyzeHabitPerformance(
      any(),
      dominantMotive: any(named: 'dominantMotive'),
      archetype: any(named: 'archetype'),
    ),
  ).thenAnswer((_) async => adjustments);

  return ProviderScope(
    overrides: [
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
      aiPersonalizationServiceProvider.overrideWith((ref) => mockService),
      userStatsStreamProvider.overrideWith(
        (ref) => Stream.value(UserProfile(uid: 'test-uid')),
      ),
    ],
    child: const MaterialApp(
      home: GoldilocksScreen(),
    ),
  );
}

void main() {
  testWidgets('renders loading state for habits', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => const Stream.empty()),
          aiPersonalizationServiceProvider.overrideWith(
            (ref) => MockAiPersonalizationService(),
          ),
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(UserProfile(uid: 'test-uid')),
          ),
        ],
        child: const MaterialApp(
          home: GoldilocksScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Goldilocks Engine'), findsOneWidget);
  });

  testWidgets('shows empty state when no habits', (tester) async {
    await tester.pumpWidget(createTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No habits to analyze yet.'), findsOneWidget);
  });

  testWidgets('shows empty state when no adjustments needed', (tester) async {
    final habits = [
      Habit(
        id: 'h1',
        userId: 'test-uid',
        title: 'Test Habit',
        frequency: HabitFrequency.daily,
        attribute: HabitAttribute.focus,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    await tester.pumpWidget(createTest(habits: habits));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Goldilocks says: Everything is just right!'),
      findsOneWidget,
    );
  });
}
