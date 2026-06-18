import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import '../../../../helpers/mocks/gamification_mocks.dart';

const testUser = AuthUser(id: 'u1', email: 'test@test.com');

UserWeeklyRecap makeRecap() => UserWeeklyRecap(
  id: 'r1',
  userId: 'u1',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 7),
  totalHabitsCompleted: 10,
  perfectDays: 5,
  totalXpEarned: 250,
  topHabitName: 'Morning Run',
  currentLevel: 3,
  worldGrowthPercentage: 0.75,
);

Widget createTestWidget({
  required WeeklyRecapService recapService,
  Stream<AuthUser> authStream = const Stream<AuthUser>.empty(),
}) {
  return ProviderScope(
    overrides: [
      weeklyRecapServiceProvider.overrideWithValue(recapService),
      authStateChangesProvider.overrideWith((ref) => authStream),
    ],
    child: const MaterialApp(
      home: WeeklyRecapScreen(),
    ),
  );
}

void main() {
  late MockWeeklyRecapService mockService;

  setUp(() {
    mockService = MockWeeklyRecapService();
  });

  group('WeeklyRecapScreen', () {
    testWidgets('shows loading indicator while generating recap', (
      tester,
    ) async {
      final completer = Completer<UserWeeklyRecap?>();

      when(() => mockService.generateRecap(
        userId: any(named: 'userId'),
        recapId: any(named: 'recapId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget(
        recapService: mockService,
        authStream: Stream.value(testUser),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Unable to generate recap'), findsNothing);
      completer.complete(makeRecap());
    });

    testWidgets('shows error state when generation fails', (tester) async {
      when(() => mockService.generateRecap(
        userId: any(named: 'userId'),
        recapId: any(named: 'recapId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => Future.error(Exception('Generation failed')));

      await tester.pumpWidget(createTestWidget(
        recapService: mockService,
        authStream: Stream.value(testUser),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Unable to generate recap'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('loading disappears after future completes', (tester) async {
      when(() => mockService.generateRecap(
        userId: any(named: 'userId'),
        recapId: any(named: 'recapId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => makeRecap());

      await tester.pumpWidget(createTestWidget(
        recapService: mockService,
        authStream: Stream.value(testUser),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      // drain flutter_animate's zero-duration timer
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows loading when user auth stream is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(
        recapService: mockService,
        authStream: const Stream<AuthUser>.empty(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
