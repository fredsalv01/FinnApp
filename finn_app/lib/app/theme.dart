import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinanzasTheme {
  // Fintech Color Palette
  static const _primary = Color(0xFF00C896); // Mint / Emerald
  static const _secondary = Color(0xFF0A84FF); // Blue
  static const _background = Color(0xFF121212); // Fintech Deep Dark
  static const _card = Color(0xFF1E1E1E); // Elevated Card Dark
  static const _error = Color(0xFFFF453A); // Red
  static const _textLight = Color(0xFFE5E5EA); // Off-white text

  static TextTheme _buildTextTheme(Color base) {
    return TextTheme(
      displayMedium: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: base,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: base,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: base,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: base,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: base.withValues(alpha: 0.6),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: base.withValues(alpha: 0.5),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _primary,
      secondary: _secondary,
      surface: _background,
      error: _error,
    ).copyWith(
      surfaceContainerLowest: _card,
      onPrimary: Colors.black,
      primaryContainer: _primary.withValues(alpha: 0.15),
      secondaryContainer: _secondary.withValues(alpha: 0.15),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _buildTextTheme(_textLight),
      scaffoldBackgroundColor: _background,
      cardTheme: CardThemeData(
        elevation: 0,
        color: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _background,
        selectedItemColor: _primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }

  // We make light theme similar to dark or slightly cleaner dark to maintain the fintech dark aesthetics
  static ThemeData light() => dark();
}
