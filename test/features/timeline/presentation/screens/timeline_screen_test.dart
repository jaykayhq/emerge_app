import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

final _emptyProfile = UserProfile(uid: 'test');
final _guideHabit = Habit(
  id: 'guide-habit',
  userId: 'test',
  title: 'Guide habit',
  createdAt: DateTime(2026, 1, 1),
);

class _TimelineGuideSettings extends LocalSettingsRepository {
  @override
  bool isTutorialsEnabled() => true;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async => false;
}

void main() {
  setUp(() async {
    // Seed the narrator-guide 'seen' flag (the timeline host checks
    // `hasSeenNarratorGuide_timeline`) so the first-visit coach mark never
    // overlays the timeline during the test.
    SharedPreferences.setMockInitialValues({
      'hasSeenNarratorGuide_timeline': true,
    });
    final repo = CompanionRepository();
    await repo.init();
    final settings = LocalSettingsRepository();
    await settings.init();
  });

  group('TimelineScreen', () {
    testWidgets('shows loading indicator when habits stream is pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith((ref) => const Stream.empty()),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_emptyProfile),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
    });

    testWidgets('shows create habit FAB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith((ref) => const Stream.empty()),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_emptyProfile),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // The floating action button should be present
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // The FAB should have an add icon
      expect(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );

      // The narrator first-visit guide must stay suppressed: the setUp seed
      // of `hasSeenNarratorGuide_timeline` is load-bearing — without it the
      // guide host would surface the card over the timeline.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(NarratorGuideCard), findsNothing);
    });

    testWidgets('guide advances to the ring without losing the overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsRepositoryProvider.overrideWithValue(
              _TimelineGuideSettings(),
            ),
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith((ref) => const Stream.empty()),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_emptyProfile),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Next →'));
      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NarratorGuideCard), findsOneWidget);
      expect(
        find.textContaining("The ring around it is today's score"),
        findsOneWidget,
      );
    });

    testWidgets('guide scrolls to the offscreen narrator card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localSettingsRepositoryProvider.overrideWithValue(
              _TimelineGuideSettings(),
            ),
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith((ref) => Stream.value([_guideHabit])),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_emptyProfile),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Next →'));
      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Next →'));
      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 2));

      final viewport = tester.getRect(find.byType(CustomScrollView));
      final narratorCard = tester.getRect(find.byType(NarratorCard));
      expect(viewport.overlaps(narratorCard), isTrue);
      expect(find.textContaining('This card is me'), findsOneWidget);
    });

    testWidgets(
      'pending milestone REPLACE: a second set swaps the line; clear() '
      'never re-shows a dismissed overlay',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardStateProvider.overrideWithValue(DashboardState()),
              habitsProvider.overrideWith((ref) => const Stream.empty()),
              userStatsStreamProvider.overrideWith(
                (ref) => Stream.value(_emptyProfile),
              ),
              worldThemeProvider.overrideWith(WorldThemeNotifier.new),
              worldHealthStreamProvider.overrideWith(
                (ref) => Stream.value(0.5),
              ),
              worldEntropyStreamProvider.overrideWith(
                (ref) => Stream.value(0.0),
              ),
              companionRepositoryProvider.overrideWith(
                (ref) => CompanionRepository(),
              ),
              isPremiumProvider.overrideWith(() => TestIsPremium(false)),
            ],
            child: const MaterialApp(home: TimelineScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(TimelineScreen)),
        );

        // First set: the card slides up with Line A.
        container
            .read(pendingMilestoneProvider.notifier)
            .set(
              PendingMilestoneLine(
                line: const GenericLine('Line A'),
                trigger: NarratorTrigger.streakBreakFirstMiss,
              ),
            );
        await tester.pump();
        // Let the typewriter finish typing Line A (~0.2s at 35 cps).
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(NarratorMilestoneCard), findsOneWidget);
        expect(find.text('Line A'), findsOneWidget);

        // REPLACE path: a second set while the card is up must swap the line
        // (the old show-once listener ignored any set after the first).
        container
            .read(pendingMilestoneProvider.notifier)
            .set(
              PendingMilestoneLine(
                line: const GenericLine('Line B'),
                trigger: NarratorTrigger.streakBreakFirstMiss,
              ),
            );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Line B'), findsOneWidget);
        expect(find.text('Line A'), findsNothing);

        // The overlay only goes away via dismissal: this trigger has no
        // action chips, so let the 6s auto-dismiss timer fire.
        await tester.pump(const Duration(seconds: 6));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(NarratorMilestoneCard), findsNothing);

        // clear() must never re-show a dismissed overlay.
        container.read(pendingMilestoneProvider.notifier).clear();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(NarratorMilestoneCard), findsNothing);
      },
    );

    testWidgets('evening reflection milestone offers Log Reflection / Skip and '
        'dismisses on Log Reflection', (tester) async {
      // In-memory Drift database for the note recorded by 'Log Reflection';
      // closed when the test ends so no handle leaks across tests.
      final db = AppDatabase.withExecutor(NativeDatabase.memory());
      addTearDown(() => db.close());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith((ref) => const Stream.empty()),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(_emptyProfile),
            ),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
            isPremiumProvider.overrideWith(() => TestIsPremium(false)),
            // 'Log Reflection' records a narrator note through Drift; an
            // in-memory database keeps that action off the filesystem in
            // tests (the LazyDatabase singleton would otherwise hit
            // getApplicationDocumentsDirectory -> MissingPluginException).
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Drive the pending milestone exactly like the evening check-in:
      // set the line on the same container the screen listens to.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TimelineScreen)),
      );
      container
          .read(pendingMilestoneProvider.notifier)
          .set(
            PendingMilestoneLine(
              line: const GenericLine(
                'Evening check-in. How did your habits serve you today?',
              ),
              trigger: NarratorTrigger.eveningReflection,
            ),
          );
      await tester.pump();
      // The milestone card types its line out (~1.5s at 35 cps); let the
      // typewriter finish before tapping the action chips.
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NarratorMilestoneCard), findsOneWidget);
      expect(find.text('Log Reflection'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Log Reflection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NarratorMilestoneCard), findsNothing);
      expect(find.text('Log Reflection'), findsNothing);

      // The tap must have recorded the reflection through Drift, and the
      // recorded note is the newest one.
      final notes = await container
          .read(narratorLocalDatasourceProvider)
          .getRecentNotes(limit: 10);
      expect(notes, isNotEmpty);
      expect(notes.first.type, NarratorNoteType.reflectionLogged);
    });
  });
}
