import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/services/challenge_feed_merger.dart';
import 'package:flutter_test/flutter_test.dart';

Challenge _challenge(String id) {
  return Challenge(
    id: id,
    title: 'Challenge $id',
    description: 'desc',
    imageUrl: '',
    reward: 'Reward',
    participants: 0,
    daysLeft: 7,
    totalDays: 7,
    currentDay: 0,
    status: ChallengeStatus.featured,
    xpReward: 250,
    steps: const [],
    category: ChallengeCategory.fitness,
  );
}

void main() {
  test('server challenges come before catalog challenges', () {
    final merged = mergeChallengeSources(
      server: [_challenge('srv_1')],
      catalog: [_challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toList(), ['srv_1', 'cat_1']);
  });

  test('server wins on id collision', () {
    final server = _challenge('same');
    final catalog = _challenge('same');
    final merged = mergeChallengeSources(server: [server], catalog: [catalog]);
    expect(merged.length, 1);
    expect(identical(merged.single, server), isTrue);
  });

  test('catalog fills ids missing from server', () {
    final merged = mergeChallengeSources(
      server: [_challenge('srv_1')],
      catalog: [_challenge('srv_1'), _challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toSet(), {'srv_1', 'cat_1'});
  });

  test('blank server ids are ignored', () {
    final merged = mergeChallengeSources(
      server: [_challenge('')],
      catalog: [_challenge('cat_1')],
    );
    expect(merged.map((c) => c.id).toList(), ['cat_1']);
  });

  test('empty inputs produce empty output', () {
    expect(mergeChallengeSources(server: const [], catalog: const []), isEmpty);
  });
}
