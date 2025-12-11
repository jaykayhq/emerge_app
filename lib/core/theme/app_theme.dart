import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF2BEE79); // Neon Green
  static const Color secondary = Color(0xFF135BEC); // Magic Blue
  static const Color backgroundDark = Color(0xFF101622); // Deep Dark
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color surfaceDark = Color(0xFF192233);
  static const Color textMainDark = Color(0xFFFFFFFF);
  static const Color textMainLight = Color(0xFF101622);
  static const Color textSecondaryDark = Color(0xFF92A4C9);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color accent = Color(0xFFFFC700); // Gold/Amber

  // Border colors matching mockup design
  static const Color borderDark = Color(
    0xFF326747,
  ); // Green-tinted border for dark mode

  // Aliases for backward compatibility
  static const Color deepSunriseOrange = accent;
  static const Color slateBlue = secondary;
  static const Color vitalityGreen = primary;
  static const Color offWhite = backgroundLight;
  static const Color error = Color(0xFFD63031);

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.splineSans(
        textStyle: base.bodyLarge,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.splineSans(
        textStyle: base.bodyMedium,
        fontSize: 14,
      ),
      labelLarge: GoogleFonts.splineSans(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: Colors.white,
        error: Color(0xFFD63031),
        onPrimary: backgroundDark,
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
      ).apply(bodyColor: textMainLight, displayColor: textMainLight),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMainLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textMainLight),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surfaceDark,
        error: Color(0xFFFF7675),
        onPrimary: backgroundDark,
      ),
      textTheme: _buildTextTheme(
        base.textTheme,
      ).apply(bodyColor: textMainDark, displayColor: textMainDark),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMainDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textMainDark),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
