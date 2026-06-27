/// Slot on the avatar body where equipment items can be placed.
enum EquipmentSlot {
  head,
  back,
  leftHand,
  rightHand,
  waist,
  feet,
  aura;

  String get displayName {
    switch (this) {
      case EquipmentSlot.head:
        return 'Head';
      case EquipmentSlot.back:
        return 'Back';
      case EquipmentSlot.leftHand:
        return 'Left Hand';
      case EquipmentSlot.rightHand:
        return 'Right Hand';
      case EquipmentSlot.waist:
        return 'Waist';
      case EquipmentSlot.feet:
        return 'Feet';
      case EquipmentSlot.aura:
        return 'Aura';
    }
  }
}

/// An item that can be equipped on an avatar.
class ShopItem {
  final String id;
  final String name;
  final EquipmentSlot slot;
  final int? priceXP;
  final int? priceGems;

  const ShopItem({
    required this.id,
    required this.name,
    required this.slot,
    this.priceXP,
    this.priceGems,
  });

  bool get isFree => priceXP == null && priceGems == null;
}

/// Map of equipped items per slot. Unused slots have null values.
typedef EquipmentMap = Map<EquipmentSlot, ShopItem?>;
