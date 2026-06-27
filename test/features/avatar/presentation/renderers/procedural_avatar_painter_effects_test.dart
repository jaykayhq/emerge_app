import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_colors.dart';
import 'package:emerge_app/features/avatar/domain/models/equipment_data.dart';
import 'package:emerge_app/features/avatar/presentation/renderers/procedural_avatar_painter.dart';

void main() {
  group('ProceduralAvatarPainter evolution effects', () {
    test('paints radiant phase with kintsugi without throwing', () {
      const size = Size(100, 150);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
      final avatar = AvatarData.defaultAvatar().copyWith(level: 40);
      final painter = ProceduralAvatarPainter(avatarData: avatar);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('paints ascended phase with sparkles without throwing', () {
      const size = Size(100, 150);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
      final avatar = AvatarData.defaultAvatar().copyWith(level: 60);
      final painter = ProceduralAvatarPainter(avatarData: avatar);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('paints with hat equipment without throwing', () {
      const size = Size(100, 150);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
      const hat = ShopItem(id: 'hat', name: 'Hat', slot: EquipmentSlot.head);
      final avatar = AvatarData.defaultAvatar().equipItem(hat);
      final painter = ProceduralAvatarPainter(avatarData: avatar);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('paints with multiple equipment without throwing', () {
      const size = Size(100, 150);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 100, 150));
      const hat = ShopItem(id: 'hat', name: 'Hat', slot: EquipmentSlot.head);
      const cape = ShopItem(id: 'cape', name: 'Cape', slot: EquipmentSlot.back);
      const sword = ShopItem(
        id: 'sword', name: 'Sword', slot: EquipmentSlot.rightHand,
      );
      final avatar = AvatarData.defaultAvatar()
          .equipItem(hat)
          .equipItem(cape)
          .equipItem(sword);
      final painter = ProceduralAvatarPainter(avatarData: avatar);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
