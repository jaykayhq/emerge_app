import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_colors.dart';

void main() {
  group('AvatarColors', () {
    test('Default constructors sets all colors', () {
      final colors = AvatarColors(
        skin: const Color(0xFF12161F),
        outline: const Color(0xFF35E0FF),
        accent: const Color(0xFFBDF4FF),
        glow: const Color(0xFF35E0FF),
      );
      expect(colors.skin, const Color(0xFF12161F));
      expect(colors.outline, const Color(0xFF35E0FF));
      expect(colors.accent, const Color(0xFFBDF4FF));
      expect(colors.glow, const Color(0xFF35E0FF));
    });

    test('copyWith overrides specific fields', () {
      final base = AvatarColors.hero();
      final modified = base.copyWith(skin: const Color(0xFF000000));
      expect(modified.skin, const Color(0xFF000000));
      expect(modified.outline, base.outline);
      expect(modified.accent, base.accent);
      expect(modified.glow, base.glow);
    });

    test('hero returns expected default palette', () {
      final colors = AvatarColors.hero();
      expect(colors.skin, const Color(0xFF12161F));
      expect(colors.outline, const Color(0xFF35E0FF));
    });

    test('athlete returns expected default palette', () {
      final colors = AvatarColors.athlete();
      expect(colors.outline, const Color(0xFFFF6B35));
    });

    test('scholar returns expected default palette', () {
      final colors = AvatarColors.scholar();
      expect(colors.outline, const Color(0xFFB886FF));
    });

    test('creator returns expected default palette', () {
      final colors = AvatarColors.creator();
      expect(colors.outline, const Color(0xFFFFD600));
    });

    test('stoic returns expected default palette', () {
      final colors = AvatarColors.stoic();
      expect(colors.outline, const Color(0xFF00E5C7));
    });

    test('zealot returns expected default palette', () {
      final colors = AvatarColors.zealot();
      expect(colors.outline, const Color(0xFFE040FF));
    });

    test('forArchetype returns correct colors', () {
      expect(AvatarColors.forArchetype('athlete').outline, const Color(0xFFFF6B35));
      expect(AvatarColors.forArchetype('hero').outline, const Color(0xFF35E0FF));
      expect(AvatarColors.forArchetype('unknown').outline, const Color(0xFF35E0FF)); // falls back to hero
    });
  });
}
