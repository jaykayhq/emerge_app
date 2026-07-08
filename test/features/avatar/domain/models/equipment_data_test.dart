import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/avatar/domain/models/equipment_data.dart';

void main() {
  group('EquipmentSlot', () {
    test('values contains all 7 slots', () {
      expect(EquipmentSlot.values.length, 7);
    });

    test('displayName returns human-readable names', () {
      expect(EquipmentSlot.head.displayName, 'Head');
      expect(EquipmentSlot.back.displayName, 'Back');
      expect(EquipmentSlot.leftHand.displayName, 'Left Hand');
      expect(EquipmentSlot.rightHand.displayName, 'Right Hand');
      expect(EquipmentSlot.waist.displayName, 'Waist');
      expect(EquipmentSlot.feet.displayName, 'Feet');
      expect(EquipmentSlot.aura.displayName, 'Aura');
    });
  });

  group('ShopItem', () {
    test('constructor sets all fields', () {
      final item = ShopItem(
        id: 'test_hat',
        name: 'Test Hat',
        slot: EquipmentSlot.head,
        priceXP: 500,
      );
      expect(item.id, 'test_hat');
      expect(item.name, 'Test Hat');
      expect(item.slot, EquipmentSlot.head);
      expect(item.priceXP, 500);
      expect(item.priceGems, isNull);
    });

    test('isFree returns true for items with no cost', () {
      const free = ShopItem(
        id: 'free_item', name: 'Free', slot: EquipmentSlot.head,
      );
      expect(free.isFree, true);

      const costs = ShopItem(
        id: 'costs', name: 'Costs', slot: EquipmentSlot.back, priceXP: 100,
      );
      expect(costs.isFree, false);
    });

    test('EquipmentMap type alias works', () {
      const hat = ShopItem(
        id: 'hat', name: 'Hat', slot: EquipmentSlot.head,
      );
      final map = EquipmentMap();
      map[EquipmentSlot.head] = hat;
      expect(map[EquipmentSlot.head], hat);
      expect(map[EquipmentSlot.back], isNull);
    });
  });
}
