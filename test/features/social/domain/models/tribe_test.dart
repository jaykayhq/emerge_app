import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tribe model', () {
    final testMap = {
      'id': 'tribe_1',
      'name': 'Iron Legion',
      'description': 'A tribe for athletes',
      'imageUrl': 'https://example.com/tribe.png',
      'memberCount': 42,
      'ownerId': 'user_abc',
      'tags': <String>['fitness', 'discipline'],
      'levelRequirement': 5,
      'rank': 3,
      'totalXp': 15000,
      'type': 'official',
      'archetypeId': 'athlete',
      'isVerified': true,
      'level': 7,
      'createdAt': '2025-06-01T12:00:00.000Z',
      'members': <String>['user_abc', 'user_def'],
      'affiliatePartnerId': 'partner_gym',
      'brandLogoUrl': 'https://example.com/brand.png',
      'brandSponsorshipStart': '2025-06-01T00:00:00.000Z',
      'brandSponsorshipEnd': '2025-12-31T23:59:59.000Z',
      'isFeatured': true,
      'maxMembers': 100,
      'totalHabitsCompleted': 500,
      'totalChallengesCompleted': 25,
    };

    test('constructor sets all required fields', () {
      final tribe = Tribe(
        id: 'tribe_1',
        name: 'Iron Legion',
        description: 'A tribe for athletes',
        imageUrl: 'https://example.com/tribe.png',
        memberCount: 42,
        ownerId: 'user_abc',
        tags: ['fitness', 'discipline'],
        levelRequirement: 5,
        rank: 3,
        totalXp: 15000,
        type: TribeType.official,
        archetypeId: 'athlete',
        isVerified: true,
        level: 7,
        createdAt: DateTime(2025, 6, 1, 12, 0, 0),
        members: ['user_abc', 'user_def'],
        affiliatePartnerId: 'partner_gym',
        brandLogoUrl: 'https://example.com/brand.png',
        brandSponsorshipStart: DateTime(2025, 6, 1),
        brandSponsorshipEnd: DateTime(2025, 12, 31, 23, 59, 59),
        isFeatured: true,
        maxMembers: 100,
        totalHabitsCompleted: 500,
        totalChallengesCompleted: 25,
      );

      expect(tribe.id, 'tribe_1');
      expect(tribe.name, 'Iron Legion');
      expect(tribe.description, 'A tribe for athletes');
      expect(tribe.imageUrl, 'https://example.com/tribe.png');
      expect(tribe.memberCount, 42);
      expect(tribe.ownerId, 'user_abc');
      expect(tribe.tags, ['fitness', 'discipline']);
      expect(tribe.levelRequirement, 5);
      expect(tribe.rank, 3);
      expect(tribe.totalXp, 15000);
      expect(tribe.type, TribeType.official);
      expect(tribe.archetypeId, 'athlete');
      expect(tribe.isVerified, isTrue);
      expect(tribe.level, 7);
      expect(tribe.createdAt, DateTime(2025, 6, 1, 12, 0, 0));
      expect(tribe.members, ['user_abc', 'user_def']);
      expect(tribe.affiliatePartnerId, 'partner_gym');
      expect(tribe.brandLogoUrl, 'https://example.com/brand.png');
      expect(tribe.brandSponsorshipStart, DateTime(2025, 6, 1));
      expect(tribe.brandSponsorshipEnd, DateTime(2025, 12, 31, 23, 59, 59));
      expect(tribe.isFeatured, isTrue);
      expect(tribe.maxMembers, 100);
      expect(tribe.totalHabitsCompleted, 500);
      expect(tribe.totalChallengesCompleted, 25);
    });

    test('default values are applied correctly', () {
      final tribe = Tribe(
        id: 'tribe_1',
        name: 'Test Tribe',
        description: 'Desc',
        imageUrl: 'img.png',
        memberCount: 0,
        ownerId: 'owner',
        tags: [],
        levelRequirement: 0,
        rank: 0,
        totalXp: 0,
      );

      expect(tribe.type, TribeType.userPublic);
      expect(tribe.level, 1);
      expect(tribe.isVerified, isFalse);
      expect(tribe.isFeatured, isFalse);
      expect(tribe.members, isEmpty);
      expect(tribe.totalHabitsCompleted, 0);
      expect(tribe.totalChallengesCompleted, 0);
      expect(tribe.archetypeId, isNull);
      expect(tribe.createdAt, isNull);
      expect(tribe.affiliatePartnerId, isNull);
      expect(tribe.brandLogoUrl, isNull);
      expect(tribe.brandSponsorshipStart, isNull);
      expect(tribe.brandSponsorshipEnd, isNull);
      expect(tribe.maxMembers, isNull);
    });

    test('toMap and fromMap are symmetric', () {
      final original = Tribe(
        id: 'tribe_1',
        name: 'Iron Legion',
        description: 'A tribe for athletes',
        imageUrl: 'https://example.com/tribe.png',
        memberCount: 42,
        ownerId: 'user_abc',
        tags: ['fitness', 'discipline'],
        levelRequirement: 5,
        rank: 3,
        totalXp: 15000,
        type: TribeType.official,
        archetypeId: 'athlete',
        isVerified: true,
        level: 7,
        createdAt: DateTime(2025, 6, 1, 12, 0, 0),
        members: ['user_abc', 'user_def'],
        affiliatePartnerId: 'partner_gym',
        brandLogoUrl: 'https://example.com/brand.png',
        brandSponsorshipStart: DateTime(2025, 6, 1),
        brandSponsorshipEnd: DateTime(2025, 12, 31, 23, 59, 59),
        isFeatured: true,
        maxMembers: 100,
        totalHabitsCompleted: 500,
        totalChallengesCompleted: 25,
      );

      final map = original.toMap();
      final reconstructed = Tribe.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.description, original.description);
      expect(reconstructed.imageUrl, original.imageUrl);
      expect(reconstructed.memberCount, original.memberCount);
      expect(reconstructed.ownerId, original.ownerId);
      expect(reconstructed.tags, original.tags);
      expect(reconstructed.levelRequirement, original.levelRequirement);
      expect(reconstructed.rank, original.rank);
      expect(reconstructed.totalXp, original.totalXp);
      expect(reconstructed.type, original.type);
      expect(reconstructed.archetypeId, original.archetypeId);
      expect(reconstructed.isVerified, original.isVerified);
      expect(reconstructed.level, original.level);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.members, original.members);
      expect(reconstructed.affiliatePartnerId, original.affiliatePartnerId);
      expect(reconstructed.brandLogoUrl, original.brandLogoUrl);
      expect(reconstructed.brandSponsorshipStart, original.brandSponsorshipStart);
      expect(reconstructed.brandSponsorshipEnd, original.brandSponsorshipEnd);
      expect(reconstructed.isFeatured, original.isFeatured);
      expect(reconstructed.maxMembers, original.maxMembers);
      expect(reconstructed.totalHabitsCompleted, original.totalHabitsCompleted);
      expect(reconstructed.totalChallengesCompleted, original.totalChallengesCompleted);
    });

    test('fromMap handles null optional fields', () {
      final map = <String, dynamic>{
        'id': 'tribe_1',
        'name': 'Minimal Tribe',
        'description': 'Minimal',
        'imageUrl': '',
        'memberCount': 0,
        'ownerId': 'owner',
        'tags': [],
        'levelRequirement': 0,
        'rank': 0,
        'totalXp': 0,
      };

      final tribe = Tribe.fromMap(map);

      expect(tribe.archetypeId, isNull);
      expect(tribe.createdAt, isNull);
      expect(tribe.affiliatePartnerId, isNull);
      expect(tribe.brandLogoUrl, isNull);
      expect(tribe.brandSponsorshipStart, isNull);
      expect(tribe.brandSponsorshipEnd, isNull);
      expect(tribe.maxMembers, isNull);
      expect(tribe.isVerified, isFalse);
      expect(tribe.isFeatured, isFalse);
      expect(tribe.type, TribeType.userPublic);
      expect(tribe.level, 1);
    });

    test('fromMap handles TribeType enum parsing', () {
      for (final type in TribeType.values) {
        final map = <String, dynamic>{
          'id': 'tribe_1',
          'name': 'Test',
          'description': 'Test',
          'imageUrl': '',
          'memberCount': 0,
          'ownerId': 'owner',
          'tags': [],
          'levelRequirement': 0,
          'rank': 0,
          'totalXp': 0,
          'type': type.name,
        };

        final tribe = Tribe.fromMap(map);
        expect(tribe.type, type, reason: 'Failed for TribeType.${type.name}');
      }
    });

    test('fromMap handles memberCount as num type', () {
      final map = <String, dynamic>{
        'id': 'tribe_1',
        'name': 'Test',
        'description': 'Test',
        'imageUrl': '',
        'memberCount': 42.0,
        'ownerId': 'owner',
        'tags': [],
        'levelRequirement': 0,
        'rank': 0,
        'totalXp': 0,
      };

      final tribe = Tribe.fromMap(map);
      expect(tribe.memberCount, 42);
      expect(tribe.memberCount, isA<int>());
    });

    test('fromMap parses DateTime from String', () {
      final tribe = Tribe.fromMap(testMap);
      expect(tribe.createdAt!.isUtc, isTrue);
      expect(tribe.createdAt!.toIso8601String(), '2025-06-01T12:00:00.000Z');
    });

    test('fromMap handles null sponsorship dates', () {
      final map = <String, dynamic>{
        'id': 'tribe_1',
        'name': 'Test',
        'description': 'Test',
        'imageUrl': '',
        'memberCount': 0,
        'ownerId': 'owner',
        'tags': [],
        'levelRequirement': 0,
        'rank': 0,
        'totalXp': 0,
        'brandSponsorshipStart': null,
        'brandSponsorshipEnd': null,
      };

      final tribe = Tribe.fromMap(map);
      expect(tribe.brandSponsorshipStart, isNull);
      expect(tribe.brandSponsorshipEnd, isNull);
    });
  });
}
