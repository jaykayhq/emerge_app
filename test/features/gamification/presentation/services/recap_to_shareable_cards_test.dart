// test/features/gamification/presentation/services/recap_to_shareable_cards_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/services/recap_to_shareable_cards.dart';

void main() {
  final recap = UserWeeklyRecap(
    id: 'r1',
    userId: 'u1',
    startDate: DateTime(2026, 8, 10),
    endDate: DateTime(2026, 8, 16),
    totalHabitsCompleted: 42,
    perfectDays: 5,
    totalXpEarned: 500,
    topHabitName: 'Read',
    currentLevel: 7,
    worldGrowthPercentage: 0.4,
    dominantIdentityThisWeek: 'Writer',
    identityHeadline: 'Consistent and focused',
  );

  test('produces stats, top habit, and identity cards', () {
    final cards = recapToShareableCards(recap);
    expect(cards, isNotEmpty);
    expect(cards.length, greaterThanOrEqualTo(3));

    final stats = cards.firstWhere((c) => c.headline.contains('NUMBERS'));
    expect(stats.stats.any((s) => s.value == '42'), isTrue);
    expect(stats.stats.any((s) => s.value == '+500'), isTrue);

    final mvp = cards.firstWhere((c) => c.headline.contains('MVP'));
    expect(mvp.stats.first.value, 'READ');
  });

  test('includes identity card only when identity present', () {
    final bare = UserWeeklyRecap(
      id: 'r2',
      userId: 'u1',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 16),
      totalHabitsCompleted: 1,
      perfectDays: 0,
      totalXpEarned: 10,
      topHabitName: 'Run',
      currentLevel: 1,
      worldGrowthPercentage: 0,
    );
    final cards = recapToShareableCards(bare);
    expect(cards.any((c) => c.headline.contains('IDENTITY')), isFalse);
  });
}