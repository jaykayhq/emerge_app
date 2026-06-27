import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_proportions.dart';

void main() {
  group('AvatarProportions', () {
    test('hero proportions have expected values', () {
      final p = AvatarProportions.hero();
      expect(p.torsoWidth, closeTo(1.0, 0.01));
      expect(p.armLength, closeTo(1.0, 0.01));
      expect(p.legLength, closeTo(1.0, 0.01));
      expect(p.headSize, closeTo(1.0, 0.01));
    });

    test('athlete has broader torso', () {
      final p = AvatarProportions.athlete();
      expect(p.torsoWidth, greaterThan(1.0));
    });

    test('scholar has larger head', () {
      final p = AvatarProportions.scholar();
      expect(p.headSize, greaterThan(1.0));
    });

    test('forArchetype returns correct proportions', () {
      expect(AvatarProportions.forArchetype('athlete').torsoWidth,
          greaterThan(1.0));
      expect(AvatarProportions.forArchetype('hero').torsoWidth,
          closeTo(1.0, 0.01));
    });

    test('all archetype proportions are defined', () {
      for (final archetype in ['hero', 'athlete', 'scholar',
                               'creator', 'stoic', 'zealot']) {
        expect(AvatarProportions.forArchetype(archetype).torsoWidth,
            greaterThan(0));
      }
    });
  });
}
