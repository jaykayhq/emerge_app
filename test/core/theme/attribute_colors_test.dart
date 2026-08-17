// test/core/theme/attribute_colors_test.dart
import 'package:emerge_app/core/theme/attribute_colors.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('attributeColor (canonical palette)', () {
    test('maps every HabitAttribute to its canonical identity color', () {
      const expected = {
        HabitAttribute.strength: Color(0xFFFF6B6B), // Coral red
        HabitAttribute.intellect: Color(0xFF6C63FF), // Indigo
        HabitAttribute.vitality: Color(0xFF2BEE79), // Emerge green
        HabitAttribute.creativity: Color(0xFFE040FB), // Magenta
        HabitAttribute.focus: Color(0xFFFFB74D), // Amber
        HabitAttribute.spirit: Color(0xFF4DD0E1), // Cyan
      };

      for (final entry in expected.entries) {
        expect(
          attributeColor(entry.key),
          entry.value,
          reason: '${entry.key.name} must map to ${entry.value}',
        );
      }
    });
  });
}
