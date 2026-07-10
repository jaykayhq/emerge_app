// test/features/world_map/domain/world_type_config_test.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldTypeConfig', () {
    test('has exactly 6 world types, one per HabitAttribute', () {
      final attrs = HabitAttribute.values.toSet();
      final configAttrs = WorldTypeConfig.all.map((c) => c.attribute).toSet();
      expect(configAttrs, equals(attrs));
    });

    test('forAttribute returns the correct config', () {
      final cfg = WorldTypeConfig.forAttribute(HabitAttribute.strength);
      expect(cfg.worldName, 'Forest');
      expect(cfg.attribute, HabitAttribute.strength);
    });

    test('backgroundAssetPath is level-bound correctly', () {
      final cfg = WorldTypeConfig.forAttribute(HabitAttribute.vitality);
      expect(cfg.backgroundAssetPath(1), 'assets/worlds/vitality/level_1.jpg');
      expect(cfg.backgroundAssetPath(50), 'assets/worlds/vitality/level_50.jpg');
    });

    test('stageName returns a non-empty string for levels 1–50', () {
      final cfg = WorldTypeConfig.forAttribute(HabitAttribute.intellect);
      for (int lvl = 1; lvl <= 50; lvl++) {
        expect(cfg.stageName(lvl).isNotEmpty, isTrue,
            reason: 'No stage name at level $lvl');
      }
    });
  });
}
