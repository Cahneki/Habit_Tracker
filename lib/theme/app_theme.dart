import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFFFDF8EF);
  static const Color parchment = Color(0xFFF4E4BC);
  static const Color ink = Color(0xFF111814);
  static const Color muted = Color(0xFF618975);
  static const Color wood = Color(0xFF4A2C2A);
  static const Color primary = Color(0xFF2BEE8C);
  static const Color cardBorder = Color(0xFFD4C194);
  static const Color cardShadow = Color(0xFFD4C194);
  static const Color goldCard = Color(0xFFFFF2D9);
  static const Color streakCard = Color(0xFFFFE9E9);

  static const Color midnightBackground = Color(0xFF0F1418);
  static const Color midnightSurface = Color(0xFF1B232B);
  static const Color midnightInk = Color(0xFFE6F3F2);
  static const Color midnightMuted = Color(0xFF91A3A7);
  static const Color midnightPrimary = Color(0xFF34E3C3);
  static const Color midnightBorder = Color(0xFF2F3B44);

  static const List<ThemeOption> options = [
    ThemeOption(id: 'forest', label: 'Forest'),
    ThemeOption(id: 'midnight', label: 'Midnight Ink'),
  ];

  static ThemeData themeForId(String id) {
    if (id == 'midnight') return midnightTheme();
    return lightTheme();
  }

  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x1A111814)),
    );
  }

  static ThemeData midnightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: midnightPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: midnightBackground,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: midnightInk,
      displayColor: midnightInk,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: midnightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: midnightInk),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: midnightInk,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: midnightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: midnightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: midnightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: midnightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: midnightPrimary, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: midnightMuted),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x332A3238)),
      cardTheme: CardTheme(
        color: midnightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ThemeOption {
  const ThemeOption({required this.id, required this.label});
  final String id;
  final String label;
}
