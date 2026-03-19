import 'package:flutter/material.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// Earthy Warmth Theme for Emerge App
/// Design Philosophy: "Grounded Growth" - habits planted in earth, growing steadily
/// Color Palette: Terracotta, Sienna, Warm Browns, Cream, Sand
class EmergeEarthyColors {
  // ============ PRIMARY EARTHY TONES ============

  /// Terracotta - Primary accent color
  /// Usage: Primary buttons, active states, key highlights
  static const Color terracotta = Color(0xFFE07A5F);

  /// Sienna - Secondary accent color
  /// Usage: Badges, secondary buttons, warm highlights
  static const Color sienna = Color(0xFFA04000);

  /// Warm Brown - Dividers and borders
  /// Usage: Borders, dividers, subtle lines
  static const Color warmBrown = Color(0xFF6B4423);

  /// Cream - Text highlights
  /// Usage: Highlighted text, labels, emphasis
  static const Color cream = Color(0xFFF5F0E6);

  /// Sand - Subtle highlights
  /// Usage: Background highlights, subtle accents
  static const Color sand = Color(0xFFE8DFCA);

  // ============ BASE COLORS (Kept for consistency) ============

  /// Base background color (from existing theme)
  static const Color baseBackground = Color(0xFF1A1A2E);

  /// Surface color
  static const Color surface = Color(0xFF16213E);

  // ============ ATTRIBUTE COLORS (Earth-Toned) ============

  /// Map of earthy colors for each habit attribute
  static const Map<HabitAttribute, Color> attributeColors = {
    HabitAttribute.strength: Color(0xFFCC5500), // Burnt orange
    HabitAttribute.intellect: Color(0xFF8B4513), // Saddle brown
    HabitAttribute.vitality: Color(0xFF2E8B57), // Sea green
    HabitAttribute.creativity: Color(0xFFD2691E), // Chocolate
    HabitAttribute.focus: Color(0xFFB8860B), // Dark goldenrod
    HabitAttribute.spirit: Color(0xFFCD853F), // Peru
  };

  // ============ GRADIENTS ============

  /// Terracotta gradient for primary actions
  static const LinearGradient terracottaGradient = LinearGradient(
    colors: [terracotta, Color(0xFFF0937B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Sienna gradient for secondary actions
  static const LinearGradient siennaGradient = LinearGradient(
    colors: [sienna, Color(0xFFC05800)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============ HELPER METHODS ============

  /// Get earthy color for a specific attribute
  static Color getAttributeColor(HabitAttribute attribute) {
    return attributeColors[attribute] ?? terracotta;
  }

  /// Get attribute color by string name
  static Color getAttributeColorByName(String attributeName) {
    final attribute = HabitAttribute.values.firstWhere(
      (attr) => attr.name.toLowerCase() == attributeName.toLowerCase(),
      orElse: () => HabitAttribute.strength,
    );
    return getAttributeColor(attribute);
  }

  /// Apply opacity to color
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get glassmorphism color with opacity
  static Color glass(double opacity) {
    return Colors.white.withValues(alpha: opacity);
  }
}

/// Standard dialog configuration for consistent sizing
/// Matches node quest dialog with slight adjustments for readability
class EmergeDialogConfig {
  /// Horizontal inset padding (between habit creation: 16 and node quest: 28)
  static const double insetPaddingHorizontal = 24.0;

  /// Vertical inset padding (between habit creation: 24 and node quest: 48)
  static const double insetPaddingVertical = 40.0;

  /// Internal padding (between node quest: 20 and habit creation: 24)
  static const double internalPadding = 18.0;

  /// Border radius for dialogs
  static const double borderRadiusValue = 20.0;

  /// Border opacity
  static const double borderOpacity = 0.4;

  /// Background opacity (solid, no blur)
  static const double backgroundOpacity = 0.92;

  /// Blur sigma (not used for solid backgrounds)
  static const double blurSigma = 0.0;

  /// Get standard EdgeInsets for dialog insets
  static EdgeInsets get insetPadding => const EdgeInsets.symmetric(
    horizontal: insetPaddingHorizontal,
    vertical: insetPaddingVertical,
  );

  /// Get standard EdgeInsets for internal padding
  static EdgeInsets get padding => const EdgeInsets.all(internalPadding);

  /// Get standard BorderRadius
  static BorderRadius get borderRadius =>
      BorderRadius.circular(borderRadiusValue);

  /// Get border for dialog with primary color
  static Border getBorder(Color primaryColor) => Border.all(
    color: primaryColor.withValues(alpha: borderOpacity),
    width: 1.5,
  );

  /// Get box shadow for dialog
  static List<BoxShadow> getBoxShadow(Color primaryColor) => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.15),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];

  /// Get standard dialog decoration
  static BoxDecoration getDecoration(Color primaryColor) => BoxDecoration(
    color: EmergeEarthyColors.baseBackground.withValues(
      alpha: backgroundOpacity,
    ),
    borderRadius: borderRadius,
    border: getBorder(primaryColor),
    boxShadow: getBoxShadow(primaryColor),
  );
}

/// Extension methods for easy access to earthy theme
extension EmergeEarthyThemeExtension on BuildContext {
  /// Get earthy colors
  EmergeEarthyColors get earthyColors => EmergeEarthyColors();

  /// Get dialog config
  EmergeDialogConfig get dialogConfig => EmergeDialogConfig();
}
