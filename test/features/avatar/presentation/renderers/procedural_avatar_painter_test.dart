import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_colors.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/presentation/renderers/procedural_avatar_painter.dart';

void main() {
  group('ProceduralAvatarPainter', () {
    test('paints without throwing', () {
      const size = Size(100, 150);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
      final painter = ProceduralAvatarPainter(
        avatarData: AvatarData.defaultAvatar(),
      );
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('shouldRepaint returns true for different data', () {
      final painter1 = ProceduralAvatarPainter(
        avatarData: AvatarData.defaultAvatar(),
      );
      final painter2 = ProceduralAvatarPainter(
        avatarData: AvatarData.defaultAvatar().copyWith(level: 50),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false for same data', () {
      final painter1 = ProceduralAvatarPainter(
        avatarData: AvatarData.defaultAvatar(),
      );
      final painter2 = ProceduralAvatarPainter(
        avatarData: AvatarData.defaultAvatar(),
      );
      expect(painter1.shouldRepaint(painter2), false);
    });

    test('paints all archetype colors without throwing', () {
      for (final colors in [
        AvatarColors.hero(),
        AvatarColors.athlete(),
        AvatarColors.scholar(),
        AvatarColors.creator(),
        AvatarColors.stoic(),
        AvatarColors.zealot(),
      ]) {
        const size = Size(100, 150);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
        final avatar = AvatarData.defaultAvatar().copyWith(colors: colors);
        final painter = ProceduralAvatarPainter(avatarData: avatar);
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      }
    });
  });
}
