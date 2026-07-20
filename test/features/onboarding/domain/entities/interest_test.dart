import 'package:emerge_app/features/onboarding/domain/models/interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Interest', () {
    test('constructor with all fields sets correctly', () {
      const interest = Interest(
        id: 'movement.walking',
        label: 'Walking',
        category: InterestCategory.movement,
        icon: Icons.directions_walk,
      );

      expect(interest.id, 'movement.walking');
      expect(interest.label, 'Walking');
      expect(interest.category, InterestCategory.movement);
      expect(interest.icon, Icons.directions_walk);
    });

    test('catalog ids match category prefix invariant', () {
      for (final interest in Interest.catalog) {
        expect(interest.id.startsWith(interest.category.idPrefix), isTrue,
            reason: 'catalog id ${interest.id} must start with its category '
                'prefix for stable personalization joins');
      }
    });
  });

  group('Interest catalog', () {
    test('contains 3-5 entries per category', () {
      final catalog = Interest.catalog;
      for (final category in InterestCategory.values) {
        final count = catalog.where((i) => i.category == category).length;
        expect(count, greaterThanOrEqualTo(3),
            reason: '$category must have at least 3 entries');
        expect(count, lessThanOrEqualTo(5),
            reason: '$category must have at most 5 entries');
      }
    });

    test('all ids are unique', () {
      final ids = Interest.catalog.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'every interest must have a unique id');
    });

    test('no null labels or empty labels', () {
      for (final interest in Interest.catalog) {
        expect(interest.label.trim().isNotEmpty, isTrue,
            reason: 'interest ${interest.id} must have a non-empty label');
      }
    });

    test('catalog is exposed as List<Interest>', () {
      expect(Interest.catalog, isA<List<Interest>>());
      expect(Interest.catalog, isNotEmpty);
    });
  });

  group('InterestCategory.idPrefix', () {
    test('returns a non-empty stable prefix for every category', () {
      for (final category in InterestCategory.values) {
        expect(category.idPrefix, isNotEmpty);
        expect(category.idPrefix.contains('.'), isTrue,
            reason: 'prefix must end with a dot so slug concat works');
      }
    });
  });

  group('Interest.fromId', () {
    test('returns the matching interest when id exists', () {
      final result = Interest.fromId('movement.walking');
      expect(result, isNotNull);
      expect(result!.id, 'movement.walking');
    });

    test('returns null when id does not exist', () {
      expect(Interest.fromId('does.not.exist'), isNull);
    });
  });
}
