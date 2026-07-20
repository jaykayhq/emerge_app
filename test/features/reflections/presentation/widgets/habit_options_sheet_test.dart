import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_local_datasource.dart';
import 'package:emerge_app/features/reflections/data/datasources/habit_reflection_remote_datasource.dart';
import 'package:emerge_app/features/reflections/data/repositories/habit_reflection_repository.dart';
import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/habit_reflection_providers.dart';
import 'package:emerge_app/features/reflections/presentation/widgets/habit_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements HabitReflectionRemoteDatasource {}

class _MockLocalDatasource extends Mock
    implements HabitReflectionLocalDatasource {}

/// Fake HabitRepository that captures the last updated habit.
class _FakeHabitRepo implements HabitRepository {
  Habit _updated = Habit.empty();
  Habit get updated => _updated;

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime completedAt, {
    String? activeTribeId,
  }) async =>
      const Right(true);

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async =>
      Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async =>
      const Right(unit);

  @override
  Future<Habit?> getHabit(String habitId) async => null;

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async => [];

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    _updated = habit;
    return const Right(unit);
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) => Stream.value([]);

  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async =>
      [];

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async =>
      const Right(unit);

  @override
  Future<Either<Failure, List<HabitCompletionEntity>>> getCompletionsBetweenDates(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Habit>>> createStarterPack({
    required String userId,
    required List<StarterHabitBlueprint> blueprints,
    String? archetypeName,
    List<String> interestIds = const [],
    String? clubId,
  }) async =>
      const Right([]);
}

/// Fake reflection repository that extends the real class with stub
/// datasources so it works in tests without Firebase or Drift.
class _FakeReflectionRepo extends HabitReflectionRepository {
  HabitReflection? _stored;

  _FakeReflectionRepo()
      : super(
          local: _MockLocalDatasource(),
          remote: _MockRemoteDatasource(),
        );

  @override
  Future<Either<Failure, HabitReflection?>> getForHabit({
    required String userId,
    required String habitId,
    required DateTime localDate,
  }) async =>
      Right(_stored);

  @override
  Future<Either<Failure, HabitReflection>> save({
    required String userId,
    required String habitId,
    required DateTime localDate,
    required Mood mood,
    required String note,
  }) async {
    _stored = HabitReflection(
      id: 'hr1',
      userId: userId,
      habitId: habitId,
      localDate: localDate,
      mood: mood,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return Right(_stored!);
  }
}

void main() {
  late _FakeHabitRepo habitRepo;
  late _FakeReflectionRepo reflectionRepo;

  setUp(() {
    habitRepo = _FakeHabitRepo();
    reflectionRepo = _FakeReflectionRepo();
  });

  Widget buildTestApp(Widget child) => ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(habitRepo),
          habitReflectionRepositoryProvider.overrideWithValue(reflectionRepo),
          authStateChangesProvider.overrideWithValue(
            const AsyncValue.data(
              AuthUser(id: 'u1', email: 'test@example.com'),
            ),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  final habit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Test Habit',
    createdAt: DateTime.now(),
    environmentPriming: ['Lay out clothes'],
    reward: 'Coffee',
    attribute: HabitAttribute.vitality,
  );

  group('HabitOptionsSheet', () {
    testWidgets('renders all five sections', (tester) async {
      // Use a taller surface so the sheet content is fully visible.
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          HabitOptionsSheet(habit: habit, selectedDate: DateTime.now()),
        ),
      );
      await tester.pump();
      expect(find.text('Start Timer'), findsOneWidget);
      expect(find.text('ENVIRONMENT PRIMING'), findsOneWidget);
      expect(find.text('SET REWARD'), findsOneWidget);
      expect(find.text('LOG REFLECTION'), findsOneWidget);
      expect(find.text('Delete Habit'), findsOneWidget);
    });

    testWidgets('adds priming rule via updateHabit', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          HabitOptionsSheet(habit: habit, selectedDate: DateTime.now()),
        ),
      );
      await tester.pump();
      // The first TextField is the priming input.
      await tester.enterText(find.byType(TextField).first, 'Pack water');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        habitRepo.updated.environmentPriming,
        containsAll(['Lay out clothes', 'Pack water']),
      );
    });

    testWidgets('delete shows confirmation dialog', (tester) async {
      // Use a taller surface so the delete button at the bottom is reachable.
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          HabitOptionsSheet(habit: habit, selectedDate: DateTime.now()),
        ),
      );
      await tester.pump();
      // Scroll down to reveal the Delete Habit button.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.tap(find.text('Delete Habit'));
      await tester.pump();
      expect(find.text('Delete Habit?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
