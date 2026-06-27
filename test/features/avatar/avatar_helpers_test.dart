import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/avatar_helpers.dart';

void main() {
  group('avatarHelpers', () {
    test('generateDefaultAvatar returns hero, level 1', () {
      final avatar = generateDefaultAvatar();
      expect(avatar.archetype, 'hero');
      expect(avatar.level, 1);
    });

    test('colorToHex converts Color to correct hex string', () {
      const color = Color(0xFFFF6B35);
      expect(colorToHex(color), '#FF6B35');
    });

    test('colorToHex handles alpha 255 correctly', () {
      const color = Color(0xFF12161F);
      expect(colorToHex(color), '#12161F');
    });
  });
}
