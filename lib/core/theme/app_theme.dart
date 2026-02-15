import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Stitch-aligned App Theme
/// Design System: Cosmic purple gradients, Space Grotesk font, neon accents
class AppTheme {
  // ============ STITCH DESIGN SYSTEM COLORS ============

  // Cosmic Purple Gradient (Primary Background)
  static const Color cosmicPurpleDark = Color(0xFF1A0A2E);
  static const Color cosmicPurpleDeep = Color(0xFF0F0F23);
  static const Color cosmicPurpleMid = Color(0xFF150A25);

  // Neon Accents
  static const Color neonTeal = Color(0xFF00BFA5); // Primary accent
  static const Color neonTealBright = Color(0xFF00F0FF); // Highlight
  static const Color neonViolet = Color(0xFF7C4DFF); // Secondary accent
  static const Color neonVioletSoft = Color(0xFFbb9af7); // Muted violet

  // Glassmorphism Colors
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassWhiteLight = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white

  // ============ LEGACY TOKYO NIGHT (for compatibility) ============
  static const Color primary = Color(0xFF7aa2f7);
  static const Color secondary = Color(0xFFbb9af7);
  static const Color backgroundDark = cosmicPurpleDeep; // Updated!
  static const Color backgroundLight = Color(0xFFe1e2e7);
  static const Color surfaceDark = Color(0xFF1E1433); // Cosmic surface
  static const Color textMainDark = Color(0xFFc0caf5);
  static const Color textMainLight = Color(0xFF373b41);
  static const Color textSecondaryDark = Color(0xFFa9b1d6);
  static const Color textSecondaryLight = Color(0xFF565f89);
  static const Color accent = Color(0xFFe0af68);
  static const Color errorColor = Color(0xFFf7768e);
  static const Color successColor = Color(0xFF9ece6a);
  static const Color borderDark = Color(0xFF414868);

  // Aliases for backward compatibility
  static const Color deepSunriseOrange = accent;
  static const Color slateBlue = secondary;
  static const Color vitalityGreen = successColor;
  static const Color offWhite = backgroundLight;
  static const Color error = errorColor;

  // ============ COSMIC GRADIENTS ============

  /// Primary cosmic purple gradient for screen backgrounds
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cosmicPurpleDark, cosmicPurpleDeep],
  );

  /// Extended cosmic gradient with mid-tone
  static const LinearGradient cosmicGradientExtended = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cosmicPurpleDark, cosmicPurpleMid, cosmicPurpleDeep],
  );

  /// Neon accent gradient for buttons and highlights
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonTeal, neonViolet],
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
      // Space Grotesk for Stitch alignment
      textTheme: GoogleFonts.spaceGroteskTextTheme(
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
      scaffoldBackgroundColor: cosmicPurpleDeep, // Cosmic background
      extensions: [identity],
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: identity.primaryColor,
        onPrimary: cosmicPurpleDeep,
        secondary: identity.accentColor,
        onSecondary: textMainDark,
        error: errorColor,
        onError: textMainDark,
        surface: surfaceDark,
        onSurface: textMainDark,
      ),
      // Space Grotesk for Stitch alignment
      textTheme: GoogleFonts.spaceGroteskTextTheme(
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
