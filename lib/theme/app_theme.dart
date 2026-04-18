import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color primary = Color(0xFF90CAF9); // Soft blue, anime sky
  static const Color background = Color(0xFF0F172A); // Deep slate
  static const Color surface = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color seedColor = Color(0xFF6366F1);
}

class AppTheme {
  static ThemeData getDarkTheme({ColorScheme? colorScheme}) {
    final scheme = colorScheme ?? ColorScheme.fromSeed(
        seedColor: AppPalette.seedColor,
        brightness: Brightness.dark,
        surface: AppPalette.background,
    );
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: AppPalette.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppPalette.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.background.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        hintStyle: const TextStyle(color: AppPalette.textSecondary),
      ),
    );
  }
}
