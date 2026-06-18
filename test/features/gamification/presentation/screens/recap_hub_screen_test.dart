import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/presentation/screens/recap_hub_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/recap_hub_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

Widget _createTestWidget({
  FutureOr<List<UserWeeklyRecap>>? recapsOverride,
}) {
  return ProviderScope(
    overrides: [
      if (recapsOverride != null)
        historicalRecapsProvider.overrideWith((ref) => recapsOverride),
      isPremiumProvider.overrideWith(() => TestIsPremium(false)),
    ],
    child: const MaterialApp(
      home: RecapHubScreen(),
    ),
  );
}

final _emptyRecaps = <UserWeeklyRecap>[];

final _testRecaps = [
  UserWeeklyRecap(
    id: '1',
    userId: 'user1',
    startDate: DateTime(2025, 1, 1),
    endDate: DateTime(2025, 1, 7),
    totalHabitsCompleted: 12,
    perfectDays: 5,
    totalXpEarned: 350,
    topHabitName: 'Meditation',
    currentLevel: 7,
    worldGrowthPercentage: 0.65,
  ),
];

void main() {
  group('RecapHubScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      final completer = Completer<List<UserWeeklyRecap>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historicalRecapsProvider.overrideWith(
              (ref) => completer.future,
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          ],
          child: const MaterialApp(
            home: RecapHubScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(_emptyRecaps);
    });

    testWidgets('shows empty state for no recaps', (tester) async {
      await tester.pumpWidget(_createTestWidget(recapsOverride: _emptyRecaps));
      await tester.pump();

      expect(
        find.textContaining('Your journey is just beginning'),
        findsOneWidget,
      );
    });

    testWidgets('renders recap entries', (tester) async {
      await tester.pumpWidget(_createTestWidget(recapsOverride: _testRecaps));
      await tester.pump();

      expect(find.textContaining('12 habits'), findsOneWidget);
      expect(find.textContaining('350 XP'), findsOneWidget);
      expect(find.textContaining('YOUR WEEK IN REVIEW'), findsOneWidget);
    });
  });
}
