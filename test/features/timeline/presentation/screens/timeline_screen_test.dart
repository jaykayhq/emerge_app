import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

class TestIsPremium extends IsPremium {
  final bool premium;
  TestIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

final _emptyProfile = UserProfile(uid: 'test');

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/timeline': true,
    });
    final repo = CompanionRepository();
    await repo.init();
  });

  group('TimelineScreen', () {
    testWidgets('shows loading indicator when habits stream is pending',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardStateProvider.overrideWithValue(DashboardState()),
            habitsProvider.overrideWith(
              (ref) => const Stream.empty(),
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
          ],
          child: const MaterialApp(home: TimelineScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CircularProgressIndicator &&
              w.color?.toARGB32() == 0xFF2BEE79,
        ),
        findsOneWidget,
      );
    });
  });
}
