import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_data.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_colors.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_proportions.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_pose.dart';
import 'package:emerge_app/features/avatar/domain/models/evolution_data.dart';
import 'package:emerge_app/features/avatar/domain/models/equipment_data.dart';

void main() {
  group('AvatarData', () {
    test('defaultAvatar creates hero, level 1 avatar', () {
      final avatar = AvatarData.defaultAvatar();
      expect(avatar.archetype, 'hero');
      expect(avatar.level, 1);
      expect(avatar.phase, EvolutionPhase.phantom);
      expect(avatar.colors, AvatarColors.hero());
      expect(avatar.proportions, AvatarProportions.hero());
      expect(avatar.pose, AvatarPose.idle());
    });

    test('phase is derived from level', () {
      final avatar = AvatarData.defaultAvatar().copyWith(level: 20);
      expect(avatar.phase, EvolutionPhase.incarnate);
    });

    test('equipItem sets item in correct slot', () {
      const hat = ShopItem(
        id: 'hat', name: 'Hat', slot: EquipmentSlot.head,
      );
      final avatar = AvatarData.defaultAvatar().equipItem(hat);
      expect(avatar.equipment[EquipmentSlot.head], hat);
    });

    test('unequipSlot removes item from slot', () {
      const hat = ShopItem(
        id: 'hat', name: 'Hat', slot: EquipmentSlot.head,
      );
      final avatar = AvatarData.defaultAvatar()
          .equipItem(hat)
          .unequipSlot(EquipmentSlot.head);
      expect(avatar.equipment[EquipmentSlot.head], isNull);
    });

    test('copyWith overrides specified fields', () {
      final base = AvatarData.defaultAvatar();
      final modified = base.copyWith(level: 50);
      expect(modified.level, 50);
      expect(modified.archetype, base.archetype);
    });

    test('equippedItems returns non-null items only', () {
      const hat = ShopItem(
        id: 'hat', name: 'Hat', slot: EquipmentSlot.head,
      );
      final avatar = AvatarData.defaultAvatar().equipItem(hat);
      expect(avatar.equippedItems.length, 1);
      expect(avatar.equippedItems.first, hat);
    });
  });
}
