// Regression tests for two timeline-breaking crashes:
//
// 1. MonthCalendarStrip used a horizontal ListView directly inside a
//    SliverToBoxAdapter. The sliver passes unbounded height down the main
//    axis, so the horizontal viewport asserted "unbounded height" on every
//    frame and the timeline was dead for every user with habits.
//    (Introduced in commit 94a61c4f "WIP: broad updates" — the old
//    `Container(height: 110)` wrapper was replaced with a `Padding`.)
// 2. Crashlytics fatal: "!semantics.parentDataDirty" thrown from
//    _RenderObjectSemantics.debugCheckForParentData during flushSemantics
//    when the semantics tree is enabled (TalkBack/VoiceOver/web a11y).
//
// This test pumps the full timeline with real habit data while semantics are
// on, then scrolls it — asserting the timeline renders and stays interactive
// without either exception.
import 'dart:async';

import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/all_done_celebration.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
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

Habit _habit({
  required String id,
  required String title,
  TimeOfDayPreference? section,
  DateTime? lastCompleted,
}) {
  return Habit(
    id: id,
    userId: 'test',
    title: title,
    createdAt: DateTime.now(),
    timeOfDayPreference: section,
    lastCompletedDate: lastCompleted,
    timerDurationMinutes: 2,
  );
}

void main() {
  setUp(() async {
    final now = DateTime.now();
    // Suppress the evening-reflection NarratorSheet (fires for hour >= 18)
    // so the modal doesn't cover the timeline during the test. Also seed the
    // node-guide 'seen' flag so the first-visit coach mark never overlays the
    // timeline and swallows the pointer events the scroll assertions need.
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
      'hasSeenNodeGuide_timeline': true,
      'evening_reflection_${now.year}_${now.month}_${now.day}': true,
    });
    final repo = CompanionRepository();
    await repo.init();
    final settings = LocalSettingsRepository();
    await settings.init();
  });

  testWidgets(
      'timeline with habits renders and scrolls under semantics '
      '(regressions: unbounded calendar height + parentDataDirty assert)', (tester) async {
    // Standard phone viewport — smaller than the timeline content so the
    // scroll path is exercised (sliver children churn in/out of the tree).
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final semanticsHandle = tester.ensureSemantics();

    final habits = [
      _habit(
        id: 'h1',
        title: 'Morning run',
        section: TimeOfDayPreference.morning,
      ),
      _habit(
        id: 'h2',
        title: 'Read a book',
        section: TimeOfDayPreference.evening,
        lastCompleted: DateTime.now(),
      ),
      _habit(
        id: 'h3',
        title: 'Journal',
        section: TimeOfDayPreference.anytime,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardStateProvider.overrideWithValue(
            DashboardState(habits: habits),
          ),
          habitsProvider.overrideWith(
            (ref) => Stream.value(habits),
          ),
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
          // Narrator summary card reads the local datasource (Drift); stub it
          // so the test never touches a database.
          latestNarratorInsightProvider.overrideWith(
            (ref) async => null,
          ),
        ],
        child: const MaterialApp(home: TimelineScreen()),
      ),
    );
    // Let the habits stream deliver and the first frames settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // The habit sections must actually be on screen.
    expect(find.byType(HierarchicalHabitTimeline), findsOneWidget);
    expect(find.text('Morning run'), findsOneWidget);

    // Exercise the scrollable + interactive paths with semantics on:
    // sliver children are created/disposed and the semantics tree reshapes.
    await tester.drag(find.text('Morning run'), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.text('Read a book'), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 100));

    // The CustomScrollView must actually scroll (i.e. pointer events reach
    // it and the slivers re-layout under an active semantics tree).
    final mainScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollOffset =
        tester.state<ScrollableState>(mainScrollable).position.pixels;
    expect(scrollOffset, greaterThan(0));

    semanticsHandle.dispose();
  });

  testWidgets(
      'all-done celebration fires only on the last-completion transition '
      '(not on first build, not on undo)', (tester) async {
    final controller = StreamController<List<Habit>>();
    addTearDown(controller.close);

    final h1 = _habit(
      id: 'c1',
      title: 'Celebrate me',
      section: TimeOfDayPreference.morning,
      lastCompleted: DateTime.now(),
    );
    final h2 = _habit(
      id: 'c2',
      title: 'Second habit',
      section: TimeOfDayPreference.morning,
    );
    final h2Completed = _habit(
      id: 'c2',
      title: 'Second habit',
      section: TimeOfDayPreference.morning,
      lastCompleted: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardStateProvider.overrideWithValue(
            DashboardState(habits: [h1, h2]),
          ),
          habitsProvider.overrideWith(
            (ref) => controller.stream,
          ),
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
          latestNarratorInsightProvider.overrideWith(
            (ref) async => null,
          ),
        ],
        child: const MaterialApp(home: TimelineScreen()),
      ),
    );
    await tester.pump();
    controller.add([h1, h2]); // baseline: 1 of 2 complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    FadeTransition celebrationFade() => tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(AllDoneCelebration),
                matching: find.byType(FadeTransition),
              )
              .first,
        );

    // No celebration while the last habit is still incomplete.
    expect(celebrationFade().opacity.value, 0.0);

    // Completing the final habit fires the celebration.
    controller.add([h1, h2Completed]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(celebrationFade().opacity.value, greaterThan(0.0));

    // Let the forward + reverse animation complete (1300ms each; the reverse
    // only starts on the tick after the forward finishes).
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
    expect(celebrationFade().opacity.value, 0.0);

    // Undoing the last habit must NOT re-fire the celebration.
    controller.add([h1, h2]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(celebrationFade().opacity.value, 0.0);
  });
}
