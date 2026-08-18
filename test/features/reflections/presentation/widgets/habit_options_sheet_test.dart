import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
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
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

class _SheetHost extends StatefulWidget {
  const _SheetHost({super.key, required this.habit});

  final Habit habit;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  bool _show = true;

  void hide() => setState(() => _show = false);

  @override
  Widget build(BuildContext context) {
    return _show
        ? HabitOptionsSheet(habit: widget.habit, selectedDate: DateTime.now())
        : const SizedBox.shrink();
  }
}

/// Hosts the sheet the way the app does: pushed onto its own route, so
/// `Navigator.pop` closes only the sheet's route and the harness page below
/// survives (mirrors the real modal-bottom-sheet presentation).
class _SheetRouteHost extends StatefulWidget {
  const _SheetRouteHost({required this.habit});

  final Habit habit;

  @override
  State<_SheetRouteHost> createState() => _SheetRouteHostState();
}

class _SheetRouteHostState extends State<_SheetRouteHost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => HabitOptionsSheet.show(context, widget.habit, DateTime.now()),
          child: const Text('open sheet'),
        ),
      ),
    );
  }
}

class _MockRemoteDatasource extends Mock
    implements HabitReflectionRemoteDatasource {}

class _MockLocalDatasource extends Mock
    implements HabitReflectionLocalDatasource {}

class _MockNotificationService extends Mock implements NotificationService {}

/// Minimal dashboard notifier so the successful delete path does not spin up
/// Firebase-backed providers (activeMilestones/userStats) under test.
class _FakeDashboardNotifier extends DashboardStateNotifier {
  @override
  DashboardState build() => const DashboardState();

  @override
  Future<void> deleteHabitOptimistic(String habitId) async {}
}

/// Fake HabitRepository that captures the last updated habit.
class _FakeHabitRepo implements HabitRepository {
  Habit _updated = Habit.empty();
  bool failDelete = false;
  String? deletedId;
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
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    deletedId = habitId;
    return failDelete
        ? const Left(ServerFailure('sync queue down'))
        : const Right(unit);
  }

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
  late _MockNotificationService notificationService;

  setUp(() {
    habitRepo = _FakeHabitRepo();
    reflectionRepo = _FakeReflectionRepo();
    notificationService = _MockNotificationService();
    when(
      () => notificationService.cancelHabitNotifications(any()),
    ).thenAnswer((_) async {});
  });

  Widget buildTestApp(Widget child) => ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(habitRepo),
          habitReflectionRepositoryProvider.overrideWithValue(reflectionRepo),
          notificationServiceProvider.overrideWithValue(notificationService),
          dashboardStateProvider.overrideWith(() => _FakeDashboardNotifier()),
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

    testWidgets('confirming delete removes the habit and reports success',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(_SheetRouteHost(habit: habit)),
      );
      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.tap(find.text('Delete Habit'));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(habitRepo.deletedId, 'h1');
      expect(find.byType(HabitOptionsSheet), findsNothing, reason: 'sheet closes');
      expect(find.text('Habit deleted'), findsOneWidget);
      verify(
        () => notificationService.cancelHabitNotifications('h1'),
      ).called(1);
    });

    testWidgets('failed delete keeps the sheet open and reports the error',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(() => tester.view.resetPhysicalSize());

      habitRepo.failDelete = true;
      await tester.pumpWidget(
        buildTestApp(_SheetRouteHost(habit: habit)),
      );
      await tester.tap(find.text('open sheet'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.tap(find.text('Delete Habit'));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(habitRepo.deletedId, 'h1');
      expect(find.byType(HabitOptionsSheet), findsOneWidget, reason: 'sheet stays open');
      expect(find.text('Habit deleted'), findsNothing);
      expect(find.textContaining('cloud sync failed'), findsOneWidget);
      // The habit is archived locally even when the remote enqueue fails, so
      // its notifications must be cancelled on the failure path too.
      verify(
        () => notificationService.cancelHabitNotifications('h1'),
      ).called(1);
    });

    testWidgets(
      'tapping Delete after the sheet was removed does not touch the dead State',
      (tester) async {
        // Regression: _confirmAndDelete's dialog used the sheet State's
        // context. If the sheet was removed from the tree while the dialog
        // was up (e.g. a sync removed the habit), the tap crashed with
        // "This widget has been unmounted, so the State no longer has a
        // context".
        tester.view.physicalSize = const Size(800, 1400);
        addTearDown(() => tester.view.resetPhysicalSize());

        final hostKey = GlobalKey<_SheetHostState>();
        await tester.pumpWidget(
          buildTestApp(_SheetHost(key: hostKey, habit: habit)),
        );
        await tester.pump();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pump();
        await tester.tap(find.text('Delete Habit'));
        await tester.pump();
        expect(find.text('Delete Habit?'), findsOneWidget);

        // The sheet is disposed while its dialog stays on screen.
        hostKey.currentState!.hide();
        await tester.pump();

        await tester.tap(find.text('Delete'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
