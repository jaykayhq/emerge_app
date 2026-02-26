import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Emerge App Theme
/// Design System: Cosmic purple-black background (Stitch World Map) + Green accents (#2BEE79)
/// Font: Spline Sans (from Stitch design)
class AppTheme {
  // ============ COSMIC BACKGROUND COLORS (Stitch World Map) ============

  // Cosmic Purple Gradient (Primary Background)
  static const Color cosmicVoidDark = Color(0xFF0A0A1A); // Near-black void
  static const Color cosmicVoidCenter = Color(0xFF1A0A2A); // Rich purple center
  static const Color cosmicMidPurple = Color(
    0xFF2A1A3A,
  ); // Mid-tone purple glow
  static const Color cosmicBlue = Color(0xFF0A1A3A); // Cosmic blue nebula

  // ============ GREEN ACCENT COLORS (Preserved) ============

  // Primary green ( Stitch green - kept for buttons, cards, highlights)
  static const Color neonGreen = Color(0xFF2BEE79); // Primary green
  static const Color neonGreenBright = Color(0xFF4ADE80); // Bright green
  static const Color mintMuted = Color(0xFF92C9A8); // Muted green

  // Legacy forest colors (kept for compatibility)
  static const Color forestDark = Color(0xFF112218);
  static const Color forestDeep = Color(0xFF0A1A10);
  static const Color forestMid = Color(0xFF142A1E);

  // Additional accent colors from World Map
  static const Color warmGold = Color(0xFFFFD700); // Gold for progress/rewards
  static const Color softGray = Color(0xFF333333); // UI elements

  // Legacy aliases for backward compatibility
  static const Color cosmicPurpleDark = cosmicVoidDark;
  static const Color cosmicPurpleDeep = cosmicVoidCenter;
  static const Color cosmicPurpleMid = cosmicMidPurple;
  static const Color neonTeal = neonGreen; // Alias to primary green
  static const Color neonViolet = neonGreen;
  static const Color neonVioletSoft = mintMuted;
  static const Color neonTealBright = neonGreenBright;

  // Glassmorphism Colors
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassWhiteLight = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white
  static const Color glassDark = Color(0x26000000); // Dark glass overlay

  // = PRIMARY PALETTE TOKENS ============

  static const Color primary = Color(0xFF2BEE79); // Green (kept)
  static const Color secondary = Color(0xFF92C9A8); // Muted green
  static const Color backgroundDark = cosmicVoidDark; // Cosmic background
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color surfaceDark = Color(0xFF222222); // Dark glass surface
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMainLight = Color(0xFF373b41);
  static const Color textSecondaryDark = Color(0xFFAACFFF); // Blue-tinted stars
  static const Color textSecondaryLight = Color(0xFF565f89);
  static const Color accent = Color(0xFFFFD700); // Gold
  static const Color errorColor = Color(0xFFf7768e);
  static const Color successColor = Color(0xFF2BEE79); // Green success
  static const Color borderDark = Color(0xFF3A3A5A);

  // Aliases for backward compatibility
  static const Color deepSunriseOrange = accent;
  static const Color slateBlue = secondary;
  static const Color vitalityGreen = successColor;
  static const Color offWhite = backgroundLight;
  static const Color error = errorColor;
  static const Color green = neonGreen;

  // ============ GRADIENTS ============

  /// Primary cosmic gradient for screen backgrounds (World Map design)
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cosmicVoidDark, cosmicVoidCenter, cosmicVoidDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Extended cosmic gradient with nebula colors
  static const LinearGradient cosmicGradientExtended = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cosmicVoidDark, cosmicMidPurple, cosmicBlue, cosmicVoidCenter],
  );

  /// Radial glow for central focus (Valley of New Beginnings)
  static const RadialGradient cosmicGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.6,
    colors: [
      Color(0xFF2A1A3A), // Mid-tone purple
      Color(0xFF1A0A2A), // Rich purple
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Green accent gradient for buttons and highlights (kept)
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonGreen, neonGreenBright],
  );

  /// Gold gradient for rewards and achievements
  static const LinearGradient goldGradient = LinearGradient(
    colors: [warmGold, Color(0xFFFFE066)],
  );

  // ============ THEMES ============

  static ThemeData lightTheme([ArchetypeTheme? archetype]) {
    final identity =
        archetype?.lightColors ??
        ArchetypeTheme.forArchetype(UserArchetype.none).lightColors;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: identity.primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      extensions: [identity],
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: identity.primaryColor,
        onPrimary: Colors.white,
        secondary: identity.accentColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: backgroundLight,
        onSurface: textMainLight,
      ),
      // Spline Sans font
      textTheme: GoogleFonts.splineSansTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: textMainLight,
          displayColor: textMainLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textMainLight),
        titleTextStyle: TextStyle(
          color: textMainLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: identity.primaryColor, width: 2),
        ),
      ),
    );
  }

  static ThemeData darkTheme([ArchetypeTheme? archetype]) {
    final identity =
        archetype?.darkColors ??
        ArchetypeTheme.forArchetype(UserArchetype.none).darkColors;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: identity.primaryColor,
      scaffoldBackgroundColor:
          cosmicVoidDark, // Plain dark purple background for most screens
      extensions: [identity],
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: identity.primaryColor,
        onPrimary: forestDeep,
        secondary: identity.accentColor,
        onSecondary: textMainDark,
        error: errorColor,
        onError: textMainDark,
        surface: surfaceDark,
        onSurface: textMainDark,
      ),
      // Spline Sans font (from Stitch design)
      textTheme: GoogleFonts.splineSansTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: textMainDark,
          displayColor: textMainDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textMainDark),
        titleTextStyle: TextStyle(
          color: textMainDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: identity.primaryColor, width: 2),
        ),
      ),
    );
  }
}
