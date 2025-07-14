import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- New Dark & Vibrant Color Palette ---
  static const Color background = Color(0xFF000000); // Black background
  static const Color surface =
      Color(0xFF0A0F2C); // Deeper navy blue for cards/surfaces
  static const Color primary = Color(0xFF00A9B8); // Deep aqua ocean blue
  static const Color secondary = Color(0xFF00E5FF); // Lighter, shining blue
  static const Color onPrimary = Color(0xFFFFFFFF); // Text on primary color
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary =
      Color(0xFFB0B0B0); // Lighter grey for secondary text
  static const Color border =
      Color(0x4DFFFFFF); // Subtle white border for glass effect

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF00A9B8), Color(0xFF007A7C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Typography (Using Gruppo) ---
  static final TextTheme _textTheme = GoogleFonts.poppinsTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -1.5),
      displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5),
      displaySmall: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: TextStyle(
          fontSize: 18, color: textPrimary, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 16, color: textSecondary),
      labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
      bodySmall: TextStyle(fontSize: 14, color: textSecondary),
    ),
  );

  // --- Main Theme ---
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // To allow gradient background
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onBackground: textPrimary,
      onSurface: textPrimary,
      error: Colors.redAccent,
      onError: textPrimary,
    ),
    textTheme: _textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.transparent, // Making it transparent to use gradient
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _textTheme.labelLarge,
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: _textTheme.bodyMedium,
      labelStyle: _textTheme.bodyMedium,
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
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface.withOpacity(0.8), // Semi-transparent dark blue
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border.withOpacity(0.2)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
