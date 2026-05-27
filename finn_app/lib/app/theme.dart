import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinanzasTheme {
  // Color tokens
  static const _primary = Color(0xFF006C49);
  static const _primaryContainer = Color(0xFF10B981);
  static const _secondary = Color(0xFF525F71);
  static const _error = Color(0xFFBA1A1A);
  static const _surfaceLight = Color(0xFFF4FBF4);
  static const _surfaceDark = Color(0xFF0D1B12);
  static const _cardDark = Color(0xFF1A2E22);

  static TextTheme _buildTextTheme(Color base) {
    return TextTheme(
      displayMedium: GoogleFonts.inter(
        fontSize: 40, fontWeight: FontWeight.w700,
        letterSpacing: -0.8, color: base,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w700, color: base,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600, color: base,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w400, color: base,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: base.withValues(alpha: 0.7),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: base.withValues(alpha: 0.6),
      ),
    );
  }

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      primaryContainer: _primaryContainer,
      secondary: _secondary,
      surface: _surfaceLight,
      error: _error,
    ).copyWith(surfaceContainerLowest: Colors.white);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _buildTextTheme(const Color(0xFF0D1B12)),
      scaffoldBackgroundColor: _surfaceLight,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: Color(0xFF525F71),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _primaryContainer,
      primaryContainer: _primary,
      secondary: const Color(0xFF9CAFC4),
      surface: _surfaceDark,
      error: const Color(0xFFFFB4AB),
    ).copyWith(surfaceContainerLowest: _cardDark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _buildTextTheme(const Color(0xFFE8F5EE)),
      scaffoldBackgroundColor: _surfaceDark,
      cardTheme: CardThemeData(
        elevation: 0,
        color: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _cardDark,
        selectedItemColor: _primaryContainer,
        unselectedItemColor: const Color(0xFF9CAFC4),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
