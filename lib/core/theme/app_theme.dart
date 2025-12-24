import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // brand colors - Tokyo Night Inspired
  static const Color primary = Color(0xFF7aa2f7); // Tokyo Night Blue
  static const Color secondary = Color(0xFFbb9af7); // Tokyo Night Purple
  static const Color backgroundDark = Color(0xFF1a1b26); // Tokyo Night BG
  static const Color backgroundLight = Color(
    0xFFe1e2e7,
  ); // Tokyo Night Day BG (approx)
  static const Color surfaceDark = Color(0xFF24283b); // Tokyo Night Surface
  static const Color textMainDark = Color(0xFFc0caf5); // Tokyo Night FG
  static const Color textMainLight = Color(0xFF373b41); // Day FG
  static const Color textSecondaryDark = Color(0xFFa9b1d6); // Tokyo Night Muted
  static const Color textSecondaryLight = Color(0xFF565f89); // Day Muted
  static const Color accent = Color(0xFFe0af68); // Tokyo Night Orange/Gold
  static const Color errorColor = Color(0xFFf7768e); // Tokyo Night Red
  static const Color successColor = Color(0xFF9ece6a); // Tokyo Night Green

  // Border colors matching mockup design
  static const Color borderDark = Color(
    0xFF414868,
  ); // Toky Night Terminal Black/Gray

  // Aliases for video compatibility / backward compatibility
  static const Color deepSunriseOrange = accent;
  static const Color slateBlue = secondary;
  static const Color vitalityGreen = successColor;
  static const Color offWhite = backgroundLight;
  static const Color error = errorColor;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: backgroundDark,
        secondary: secondary,
        onSecondary: textMainDark,
        error: errorColor,
        onError: textMainDark,
        surface: backgroundLight,
        onSurface: textMainLight,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: backgroundDark,
        secondary: secondary,
        onSecondary: textMainDark,
        error: errorColor,
        onError: textMainDark,
        surface: surfaceDark,
        onSurface: textMainDark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
