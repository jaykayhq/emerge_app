import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChallengeCatalog', () {
    test('getFeatured returns only featured challenges', () {
      final featured = ChallengeCatalog.getFeatured();

      expect(featured, isNotEmpty);
      for (final challenge in featured) {
        expect(challenge.status, ChallengeStatus.featured);
      }
    });

    test('getDailyQuest returns a single-day challenge with correct archetype', () {
      final daily = ChallengeCatalog.getDailyQuest('athlete');

      expect(daily.id, contains('athlete'));
      expect(daily.totalDays, 1);
      expect(daily.steps, hasLength(1));
      expect(daily.archetypeId, 'athlete');
    });

    test('getWeeklySpotlight returns a challenge with matching archetypeId', () {
      final spotlight = ChallengeCatalog.getWeeklySpotlight('scholar');

      expect(spotlight.archetypeId, 'scholar');
    });

    test('getWeeklySpotlight returns deterministic result for same archetype', () {
      final first = ChallengeCatalog.getWeeklySpotlight('scholar');
      final second = ChallengeCatalog.getWeeklySpotlight('scholar');

      expect(first.id, second.id);
    });

    test('getChallengeById returns correct challenge', () {
      final challenge = ChallengeCatalog.getChallengeById('quest_deep_work_protocol');

      expect(challenge, isNotNull);
      expect(challenge!.title, 'The Deep Work Protocol');
    });

    test('getChallengeById returns null for unknown id', () {
      final challenge = ChallengeCatalog.getChallengeById('non_existent');

      expect(challenge, isNull);
    });

    test('getAvailableChallenges includes both featured and daily', () {
      final challenges = ChallengeCatalog.getAvailableChallenges('creator');

      expect(challenges.length, greaterThanOrEqualTo(2));
      expect(challenges.where((c) => c.id.startsWith('daily_')), hasLength(1));
      expect(challenges.where((c) => c.archetypeId == 'creator'), hasLength(greaterThanOrEqualTo(1)));
    });
  });
}
