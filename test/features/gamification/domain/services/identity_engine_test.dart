import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/services/identity_engine.dart';

void main() {
  group('IdentityEngine', () {
    test('calculateDominantArchetype returns none for empty map', () {
      final result = IdentityEngine.calculateDominantArchetype({});
      expect(result, UserArchetype.none);
    });

    test('calculateDominantArchetype returns correct archetype for single vote', () {
      final result = IdentityEngine.calculateDominantArchetype({'scholar': 5});
      expect(result, UserArchetype.scholar);
    });

    test('calculateDominantArchetype returns correct archetype for multiple votes', () {
      final result = IdentityEngine.calculateDominantArchetype({
        'athlete': 2,
        'creator': 10,
        'zealot': 5,
      });
      expect(result, UserArchetype.creator);
    });

    test('calculateDominantArchetype handles capitalized keys', () {
      final result = IdentityEngine.calculateDominantArchetype({
        'Stoic': 8,
        'Athlete': 2,
      });
      expect(result, UserArchetype.stoic);
    });

    test('calculateDominantArchetype resolves ties deterministically (alphabetical)', () {
      final result = IdentityEngine.calculateDominantArchetype({
        'scholar': 5,
        'athlete': 5,
      });
      // 'athlete' comes before 'scholar' alphabetically
      expect(result, UserArchetype.athlete);
    });

    test('calculateDominantArchetype returns none for invalid keys', () {
      final result = IdentityEngine.calculateDominantArchetype({
        'wizard': 10,
      });
      expect(result, UserArchetype.none);
    });
  });
}
