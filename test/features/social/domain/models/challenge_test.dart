import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Challenge model - joinedAt', () {
    test('constructor accepts joinedAt', () {
      final now = DateTime.now();
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      expect(challenge.joinedAt, now);
    });

    test('joinedAt is null by default', () {
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
      );

      expect(challenge.joinedAt, isNull);
    });

    test('toMap includes joinedAt', () {
      final now = DateTime(2025, 1, 1);
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      final map = challenge.toMap();
      expect(map['joinedAt'], now.toIso8601String());
    });

    test('toMap excludes null joinedAt', () {
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
      );

      final map = challenge.toMap();
      expect(map['joinedAt'], isNull);
    });

    test('fromMap parses joinedAt', () {
      final now = DateTime(2025, 6, 1);
      final map = {
        'title': 'Test',
        'description': 'Desc',
        'imageUrl': 'img.png',
        'reward': '100xp',
        'participants': 0,
        'daysLeft': 7,
        'totalDays': 7,
        'currentDay': 0,
        'status': 'featured',
        'xpReward': 100,
        'category': 'fitness',
        'affiliateNetwork': 'none',
        'joinedAt': now.toIso8601String(),
        'steps': <Map<String, dynamic>>[],
      };

      final challenge = Challenge.fromMap(map, id: 'test');
      expect(challenge.joinedAt, now);
    });

    test('fromMap handles null joinedAt', () {
      final map = {
        'title': 'Test',
        'description': 'Desc',
        'imageUrl': 'img.png',
        'reward': '100xp',
        'participants': 0,
        'daysLeft': 7,
        'totalDays': 7,
        'currentDay': 0,
        'status': 'featured',
        'xpReward': 100,
        'category': 'fitness',
        'affiliateNetwork': 'none',
        'steps': <Map<String, dynamic>>[],
      };

      final challenge = Challenge.fromMap(map, id: 'test');
      expect(challenge.joinedAt, isNull);
    });

    test('copyWith updates joinedAt', () {
      final now = DateTime(2025, 1, 1);
      final later = DateTime(2025, 6, 1);
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      final updated = challenge.copyWith(joinedAt: later);
      expect(updated.joinedAt, later);
      expect(challenge.joinedAt, now); // original unchanged
    });

    test('copyWith preserves joinedAt when not specified', () {
      final now = DateTime.now();
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      final updated = challenge.copyWith(title: 'New Title');
      expect(updated.joinedAt, now);
    });

    test('props includes joinedAt', () {
      final now = DateTime.now();
      final challenge = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      expect(challenge.props, contains(now));
    });

    test('equality works with joinedAt', () {
      final now = DateTime.now();
      final a = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );
      final b = Challenge(
        id: 'test',
        title: 'Test',
        description: 'Desc',
        imageUrl: 'img.png',
        reward: '100xp',
        participants: 0,
        daysLeft: 7,
        totalDays: 7,
        currentDay: 0,
        status: ChallengeStatus.featured,
        xpReward: 100,
        steps: const [],
        joinedAt: now,
      );

      expect(a, equals(b));
    });
  });
}
