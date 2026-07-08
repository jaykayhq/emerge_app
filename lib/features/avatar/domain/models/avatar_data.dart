import 'package:emerge_app/features/avatar/domain/models/avatar_colors.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_proportions.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_pose.dart';
import 'package:emerge_app/features/avatar/domain/models/evolution_data.dart';
import 'package:emerge_app/features/avatar/domain/models/equipment_data.dart';

const _emptyEquipment = <EquipmentSlot, ShopItem?>{};

/// Composite avatar state combining colors, proportions, pose, equipment,
/// and evolution phase. This is the primary data object consumed by the
/// procedural renderer and ThreeFlutter scene builder.
class AvatarData {
  final String archetype;
  final int level;
  final AvatarColors colors;
  final AvatarProportions proportions;
  final AvatarPose pose;
  final EquipmentMap equipment;

  const AvatarData({
    required this.archetype,
    required this.level,
    required this.colors,
    required this.proportions,
    required this.pose,
    required this.equipment,
  });

  /// Derive evolution phase from level.
  EvolutionPhase get phase => EvolutionPhase.fromLevel(level);

  /// Non-null equipped items only.
  List<ShopItem> get equippedItems =>
      equipment.values.whereType<ShopItem>().toList();

  factory AvatarData.defaultAvatar() => AvatarData(
        archetype: 'hero',
        level: 1,
        colors: AvatarColors.hero(),
        proportions: AvatarProportions.hero(),
        pose: AvatarPose.idle(),
        equipment: _emptyEquipment,
      );

  AvatarData copyWith({
    String? archetype,
    int? level,
    AvatarColors? colors,
    AvatarProportions? proportions,
    AvatarPose? pose,
    EquipmentMap? equipment,
  }) =>
      AvatarData(
        archetype: archetype ?? this.archetype,
        level: level ?? this.level,
        colors: colors ?? this.colors,
        proportions: proportions ?? this.proportions,
        pose: pose ?? this.pose,
        equipment: equipment ?? this.equipment,
      );

  AvatarData equipItem(ShopItem item) {
    final updated = Map<EquipmentSlot, ShopItem?>.from(equipment)
      ..[item.slot] = item;
    return copyWith(equipment: updated);
  }

  AvatarData unequipSlot(EquipmentSlot slot) {
    final updated = Map<EquipmentSlot, ShopItem?>.from(equipment)
      ..remove(slot);
    return copyWith(equipment: updated);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarData &&
          archetype == other.archetype &&
          level == other.level &&
          colors == other.colors &&
          proportions == other.proportions &&
          pose == other.pose &&
          equipment == other.equipment;

  @override
  int get hashCode => Object.hash(
      archetype, level, colors, proportions, pose, equipment);
}
