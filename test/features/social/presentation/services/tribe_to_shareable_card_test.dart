// test/features/social/presentation/services/tribe_to_shareable_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/social/presentation/services/tribe_to_shareable_card.dart';

void main() {
  test('maps tribe stats into a share card', () {
    final card = tribeToShareableCard(
      tribeName: 'The Forge',
      creatorName: 'Ada',
      memberCount: 25,
      totalXp: 120000,
      totalHabitsCompleted: 900,
      totalChallengesCompleted: 12,
    );
    expect(card.headline, 'THE FORGE');
    expect(card.subheadline, 'by Ada');
    final values = card.stats.map((s) => s.value).toList();
    expect(values, contains('25'));
    expect(values, contains('120.0K'));
    expect(values, contains('900'));
    expect(values, contains('12'));
    expect(card.footer, 'Join my tribe on Emerge');
  });
}