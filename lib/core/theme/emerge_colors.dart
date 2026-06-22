import 'package:flutter/material.dart';

/// Emerge Color System
/// Background: Cosmic purple-black (Stitch World Map)
/// Accents: Green (#2BEE79) preserved for buttons, cards, highlights
class EmergeColors {
  // ============ COSMIC BACKGROUND COLORS (Stitch World Map) ============

  // Base void colors (deep space background)
  static const Color cosmicVoidDark = Color(0xFF0A0A1A); // Near-black edges
  static const Color cosmicVoidCenter = Color(0xFF1A0A2A); // Rich purple center

  // Nebula colors (cosmic clouds)
  static const Color cosmicMidPurple = Color(
    0xFF2A1A3A,
  ); // Mid-tone purple glow
  static const Color cosmicBlue = Color(0xFF0A1A3A); // Cosmic blue nebula

  // ============ GREEN ACCENT COLORS (Preserved) ============

  static const Color neonTeal = Color(
    0xFF2BEE79,
  ); // Primary green (kept for buttons/cards)
  static const Color neonGreen = Color(0xFF2BEE79); // Alias
  static const Color neonGreenBright = Color(0xFF4ADE80); // Bright green
  static const Color mintMuted = Color(0xFF92C9A8); // Muted green

  // Legacy forest colors (kept for compatibility)
  static const Color emeraldPrimary = Color(0xFF2BEE79);
  static const Color forestDark = Color(0xFF112218);
  static const Color forestSurface = Color(0xFF193324);
  static const Color forestBorder = Color(0xFF326747);

  // ============ NEBULA ODYSSEY COLORS (Social Hub Redesign) ============
  static const Color nebulaPrimary = Color(0xFFA5E7FF);
  static const Color nebulaPrimaryContainer = Color(0xFF00D2FF);
  static const Color nebulaSecondary = Color(0xFFEDB1FF);
  static const Color nebulaSecondaryContainer = Color(0xFF6E208C);
  static const Color nebulaBackground = Color(0xFF050505);
  static const Color nebulaSurface = Color(0xFF111415);
  static const Color nebulaTertiary = Color(0xFFDDDBF2);

  static const LinearGradient nebulaCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nebulaPrimaryContainer, nebulaSecondary],
  );

  static const LinearGradient nebulaNeonGradient = LinearGradient(
    colors: [nebulaPrimaryContainer, nebulaSecondaryContainer],
  );

  // ============ ADDITIONAL ACCENTS ============

  static const Color warmGold = Color(0xFFFFD700); // Gold for progress/rewards
  static const Color softGray = Color(0xFF333333); // UI elements

  // Star colors
  static const Color starWhite = Color(0xFFFFFFFF);
  static const Color starBlue = Color(0xFFAACFFF); // Blue-tinted stars
  static const Color starGold = Color(0xFFFFD700); // Gold-tinted stars

  // ============ COMMON COLORS ============

  static const Color teal = neonTeal; // Main green accent
  static const Color yellow = Color(0xFFFFD700);
  static const Color coral = Color(0xFFFF7F50);
  static const Color green = Color(0xFF2BEE79);
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;

  // ============ GRADIENTS ============

  /// Primary cosmic gradient (World Map background)
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cosmicVoidDark, cosmicVoidCenter, cosmicVoidDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Radial glow for central focus
  static const RadialGradient cosmicGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.6,
    colors: [cosmicMidPurple, cosmicVoidCenter, Colors.transparent],
    stops: [0.0, 0.5, 1.0],
  );

  /// Green accent gradient for buttons (kept)
  static const LinearGradient tealGradient = LinearGradient(
    colors: [neonTeal, neonGreenBright],
  );

  /// Gold gradient for rewards
  static const LinearGradient goldGradient = LinearGradient(
    colors: [warmGold, Color(0xFFFFE066)],
  );

  // ============ GLASSMORPHISM ============

  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassWhiteLight = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white
  static const Color glassDark = Color(0x26000000); // Dark overlay
  static const Color glassSurface = Color(
    0xDD222222,
  ); // Semi-transparent dark surface

  // ============ BACKGROUND ALIASES ============

  /// Main background color (cosmic void)
  static const Color background = cosmicVoidDark;

  /// Surface color for cards/panels
  static const Color surface = Color(0xFF222222);

  /// Border color
  static const Color border = Color(0xFF3A3A5A);
  static const Color hexLine = border;

  static const Color backgroundLight = cosmicVoidCenter;
  static const Color tealMuted = mintMuted;
  static const Color violet = Color(0xFF1DB954);
  static const Color violetSoft = neonGreenBright;
  static const Color lime = neonTeal;
  static const Color glassWhiteMed = glassWhiteLight;
  static const Color glassGreen = Color(0x142BEE79);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, background],
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [teal, violet],
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [coral, yellow],
  );
}
