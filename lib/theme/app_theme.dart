import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF90CAF9); // Soft blue, anime sky
  static const Color backgroundColor = Color(0xFF0F172A); // Deep slate
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color textPrimaryColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryColor),
        bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimaryColor),
        bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textSecondaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
    );
  }
}
