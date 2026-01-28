import 'package:flutter/material.dart';

/// Emerge Design Tokens
///
/// Centralized dimensions following Material Design 3 and WCAG accessibility standards.
/// All values are in logical pixels (dp).
class EmergeDimensions {
  EmergeDimensions._();

  // ==========================================================================
  // ACCESSIBILITY (WCAG AA Compliance)
  // ==========================================================================

  /// Minimum tap target size for touch interaction (WCAG AAA: 44x44px)
  static const double minTapTarget = 44.0;

  /// Minimum font size for body text (WCAG readability)
  static const double minFontSize = 12.0;

  /// Minimum font size for important labels
  static const double minLabelFontSize = 14.0;

  // ==========================================================================
  // NAVIGATION
  // ==========================================================================

  /// Bottom navigation bar height (excluding safe area)
  static const double navBarHeight = 70.0;

  /// FAB size (standard Material Design)
  static const double fabSize = 56.0;

  /// FAB elevation above navigation bar
  static const double fabElevation = 16.0;

  // ==========================================================================
  // LAYOUT SPACING
  // ==========================================================================

  /// Base spacing unit (4px grid system)
  static const double spacingUnit = 4.0;

  /// Small gap (8px)
  static const double gapSmall = spacingUnit * 2;

  /// Medium gap (16px)
  static const double gapMedium = spacingUnit * 4;

  /// Large gap (24px)
  static const double gapLarge = spacingUnit * 6;

  /// Extra large gap (32px)
  static const double gapXLarge = spacingUnit * 8;

  // ==========================================================================
  // CARDS & CONTAINERS
  // ==========================================================================

  /// Default card corner radius
  static const double cardRadius = 16.0;

  /// Small card corner radius
  static const double cardRadiusSmall = 12.0;

  /// Default card padding
  static const double cardPadding = 16.0;

  /// Card elevation
  static const double cardElevation = 2.0;

  // ==========================================================================
  // PROGRESS INDICATORS
  // ==========================================================================

  /// Progress bar height (linear)
  static const double progressHeight = 6.0;

  /// Progress bar minimum touch height (for interactive bars)
  static const double progressTouchHeight = 24.0;

  // ==========================================================================
  // AVATARS & ICONS
  // ==========================================================================

  /// Small avatar size
  static const double avatarSmall = 32.0;

  /// Medium avatar size
  static const double avatarMedium = 48.0;

  /// Large avatar size
  static const double avatarLarge = 64.0;

  /// Small icon size
  static const double iconSmall = 18.0;

  /// Medium icon size
  static const double iconMedium = 24.0;

  /// Large icon size
  static const double iconLarge = 32.0;

  // ==========================================================================
  // RESPONSIVE BREAKPOINTS
  // ==========================================================================

  /// Mobile breakpoint (width < 600px)
  static const double breakpointMobile = 0;

  /// Tablet breakpoint (600px <= width < 1200px)
  static const double breakpointTablet = 600;

  /// Desktop breakpoint (width >= 1200px)
  static const double breakpointDesktop = 1200;

  // ==========================================================================
  // SAFE AREAS
  // ==========================================================================

  /// Default horizontal padding for screen edges
  static const double screenPaddingHorizontal = 16.0;

  /// Default vertical padding for screen edges
  static const double screenPaddingVertical = 16.0;

  // ==========================================================================
  // ANIMATION
  // ==========================================================================

  /// Default animation duration for micro-interactions
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Default animation duration for standard transitions
  static const Duration animationMedium = Duration(milliseconds: 200);

  /// Default animation duration for complex transitions
  static const Duration animationSlow = Duration(milliseconds: 300);

  // ==========================================================================
  // BORDER RADII
  // ==========================================================================

  /// Fully rounded (circular)
  static const double radiusFull = 999.0;

  /// Small corner radius
  static const double radiusSmall = 8.0;

  /// Medium corner radius
  static const double radiusMedium = 12.0;

  /// Large corner radius
  static const double radiusLarge = 16.0;

  /// Extra large corner radius
  static const double radiusXLarge = 24.0;

  // ==========================================================================
  // SHADOWS
  // ==========================================================================

  /// Light elevation shadow
  static List<BoxShadow> shadowLight() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium elevation shadow
  static List<BoxShadow> shadowMedium() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// Heavy elevation shadow
  static List<BoxShadow> shadowHeavy() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Extension to easily check device type
extension ScreenSize on BoxConstraints {
  bool get isMobile => maxWidth < EmergeDimensions.breakpointTablet;
  bool get isTablet =>
      maxWidth >= EmergeDimensions.breakpointTablet &&
      maxWidth < EmergeDimensions.breakpointDesktop;
  bool get isDesktop => maxWidth >= EmergeDimensions.breakpointDesktop;
}

/// Extension to get responsive values
extension ResponsiveValue on BuildContext {
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(this).size.width;
    if (width >= EmergeDimensions.breakpointDesktop && desktop != null) {
      return desktop;
    }
    if (width >= EmergeDimensions.breakpointTablet && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}
