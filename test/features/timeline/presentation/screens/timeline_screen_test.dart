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
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
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

void main() {
  setUp(() async {
    // Seed the narrator-guide 'seen' flag (the timeline host checks
    // `hasSeenNarratorGuide_timeline`; the legacy companion_visited_ flag no
    // longer suppresses it) so the first-visit coach mark never overlays the
    // timeline during the test.
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
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

    testWidgets('evening reflection milestone offers Log Reflection / Skip and '
        'dismisses on Log Reflection', (tester) async {
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
            appDatabaseProvider.overrideWithValue(
              AppDatabase.withExecutor(NativeDatabase.memory()),
            ),
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
    });
  });
}
