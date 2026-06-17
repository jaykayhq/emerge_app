import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _makeContainer(DashboardState state) {
  return ProviderContainer(
    overrides: [
      dashboardStateProvider.overrideWithValue(state),
    ],
  );
}

void main() {
  group('todaysHabitsProvider', () {
    test('returns habits from dashboard state', () {
      final habits = [
        Habit(id: '1', userId: 'u1', title: 'Test', createdAt: DateTime.now()),
      ];
      final state = DashboardState(habits: habits);
      final container = _makeContainer(state);
      expect(container.read(todaysHabitsProvider), habits);
      container.dispose();
    });

    test('returns empty when dashboard has no habits', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(todaysHabitsProvider), []);
      container.dispose();
    });
  });

  group('todayCompletionRateProvider', () {
    test('returns 0.0 when no habits', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(todayCompletionRateProvider), 0.0);
      container.dispose();
    });

    test('returns 1.0 when all habits completed today', () {
      final now = DateTime.now();
      final habits = [
        Habit(id: '1', userId: 'u1', title: 'Habit 1', createdAt: now, lastCompletedDate: now),
        Habit(id: '2', userId: 'u1', title: 'Habit 2', createdAt: now, lastCompletedDate: now),
      ];
      final container = _makeContainer(DashboardState(habits: habits));
      expect(container.read(todayCompletionRateProvider), 1.0);
      container.dispose();
    });
  });

  group('isDashboardLoadingProvider', () {
    test('returns false when idle', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(isDashboardLoadingProvider), false);
      container.dispose();
    });

    test('returns true when creating habit', () {
      final container = _makeContainer(
        const DashboardState(isCreatingHabit: true),
      );
      expect(container.read(isDashboardLoadingProvider), true);
      container.dispose();
    });

    test('returns true when activating blueprint', () {
      final container = _makeContainer(
        const DashboardState(isActivatingBlueprint: true),
      );
      expect(container.read(isDashboardLoadingProvider), true);
      container.dispose();
    });
  });

  group('dashboardErrorProvider', () {
    test('returns null when no error', () {
      final container = _makeContainer(const DashboardState());
      expect(container.read(dashboardErrorProvider), isNull);
      container.dispose();
    });

    test('returns error string when present', () {
      final container = _makeContainer(
        const DashboardState(error: 'Something went wrong'),
      );
      expect(container.read(dashboardErrorProvider), 'Something went wrong');
      container.dispose();
    });
  });
}
