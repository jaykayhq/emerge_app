// lib/core/theme/attribute_colors.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Maps a [HabitAttribute] to its canonical identity color.
///
/// Single source of truth for attribute colors across the entire app —
/// habit creation, timeline, profile, and the world map all delegate here.
/// Each attribute gets a distinct, vibrant accent color for visual identity.
Color attributeColor(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return const Color(0xFFFF6B6B); // Coral red
    case HabitAttribute.intellect:
      return const Color(0xFF6C63FF); // Indigo purple
    case HabitAttribute.vitality:
      return const Color(0xFF2BEE79); // Emerge green
    case HabitAttribute.creativity:
      return const Color(0xFFE040FB); // Magenta pink
    case HabitAttribute.focus:
      return const Color(0xFFFFB74D); // Amber gold
    case HabitAttribute.spirit:
      return const Color(0xFF4DD0E1); // Cyan teal
  }
}
