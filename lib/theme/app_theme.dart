import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const List<ThemeOption> options = [
    ThemeOption(id: 'forest', label: 'Forest'),
    ThemeOption(id: 'midnight', label: 'Midnight Ink'),
    ThemeOption(id: 'ember', label: 'Ember Night'),
    ThemeOption(id: 'light', label: 'Light'),
    ThemeOption(id: 'dark', label: 'Dark'),
  ];

  static ThemeData themeForId(String id) {
    if (id == 'light') return standardLightTheme();
    if (id == 'dark') return standardDarkTheme();
    if (id == 'midnight') return darkTheme();
    if (id == 'ember') return emberTheme();
    return lightTheme();
  }

  static ThemeData standardLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    );
    return _buildTheme(
      scheme,
      const GameTokens(
        xpBadgeBg: Color(0xFFEAF2FF),
        xpBadgeText: Color(0xFF1D4ED8),
        urgentDot: Color(0xFFE35D2F),
        urgentText: Color(0xFF8A3016),
        habitWater: Color(0xFF2B8CFF),
        habitRead: Color(0xFF7C4D24),
        habitSleep: Color(0xFF6C4BB5),
        habitRun: Color(0xFF0E9F6E),
        habitLift: Color(0xFF8B5E34),
        habitDefault: Color(0xFF374151),
      ),
    );
  }

  static ThemeData standardDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF60A5FA),
      brightness: Brightness.dark,
    );
    return _buildTheme(
      scheme,
      const GameTokens(
        xpBadgeBg: Color(0xFF1E293B),
        xpBadgeText: Color(0xFF93C5FD),
        urgentDot: Color(0xFFFF9F4A),
        urgentText: Color(0xFFFFC38A),
        habitWater: Color(0xFF6FB6FF),
        habitRead: Color(0xFFFFB870),
        habitSleep: Color(0xFFB7A3FF),
        habitRun: Color(0xFF6BE7B4),
        habitLift: Color(0xFFDBA46A),
        habitDefault: Color(0xFFE5E7EB),
      ),
    );
  }

  static ThemeData lightTheme() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2BEE8C),
      onPrimary: Color(0xFF082015),
      primaryContainer: Color(0xFFB9F7DA),
      onPrimaryContainer: Color(0xFF0D3A27),
      secondary: Color(0xFF4A2C2A),
      onSecondary: Color(0xFFF9EFE6),
      secondaryContainer: Color(0xFFE9D9CC),
      onSecondaryContainer: Color(0xFF3B231F),
      tertiary: Color(0xFFB35C00),
      onTertiary: Color(0xFFFFF3E6),
      tertiaryContainer: Color(0xFFFFD7AE),
      onTertiaryContainer: Color(0xFF5A2D00),
      error: Color(0xFFB42318),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE4E2),
      onErrorContainer: Color(0xFF7A271A),
      surface: Color(0xFFFDF8EF),
      onSurface: Color(0xFF111814),
      surfaceContainerHigh: Color(0xFFF4E4BC),
      surfaceContainerHighest: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF5C5343),
      outline: Color(0xFFD4C194),
      shadow: Color(0x33000000),
      inverseSurface: Color(0xFF1C1C1C),
      onInverseSurface: Color(0xFFF5F5F5),
      inversePrimary: Color(0xFF2BEE8C),
      surfaceTint: Color(0xFF2BEE8C),
    );

    return _buildTheme(
      scheme,
      const GameTokens(
        xpBadgeBg: Color(0xFFE9F7F0),
        xpBadgeText: Color(0xFF1B7B4E),
        urgentDot: Color(0xFFFF8A3D),
        urgentText: Color(0xFFB4551E),
        habitWater: Color(0xFF2B8CFF),
        habitRead: Color(0xFFB35C00),
        habitSleep: Color(0xFF6C4BB5),
        habitRun: Color(0xFF1B9B6F),
        habitLift: Color(0xFF8B5E34),
        habitDefault: Color(0xFF4A2C2A),
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF34E3C3),
      onPrimary: Color(0xFF0B1D1A),
      primaryContainer: Color(0xFF144A43),
      onPrimaryContainer: Color(0xFFB8F4E8),
      secondary: Color(0xFF7EA2A4),
      onSecondary: Color(0xFF0F1B1C),
      secondaryContainer: Color(0xFF2A3B3C),
      onSecondaryContainer: Color(0xFFDCE6E6),
      tertiary: Color(0xFF8FD3FF),
      onTertiary: Color(0xFF0B1B26),
      tertiaryContainer: Color(0xFF1C3345),
      onTertiaryContainer: Color(0xFFCFE9FF),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF2B0A0A),
      errorContainer: Color(0xFF5C1E1E),
      onErrorContainer: Color(0xFFFFDADA),
      surface: Color(0xFF0F1418),
      onSurface: Color(0xFFE6F3F2),
      surfaceContainerHigh: Color(0xFF1B232B),
      surfaceContainerHighest: Color(0xFF222C35),
      onSurfaceVariant: Color(0xFFB6C2C4),
      outline: Color(0xFF2F3B44),
      shadow: Color(0x66000000),
      inverseSurface: Color(0xFFE6F3F2),
      onInverseSurface: Color(0xFF0F1418),
      inversePrimary: Color(0xFF34E3C3),
      surfaceTint: Color(0xFF34E3C3),
    );

    return _buildTheme(
      scheme,
      const GameTokens(
        xpBadgeBg: Color(0xFF1A2A2B),
        xpBadgeText: Color(0xFF8AF1DC),
        urgentDot: Color(0xFFFF9F4A),
        urgentText: Color(0xFFFFC38A),
        habitWater: Color(0xFF6FB6FF),
        habitRead: Color(0xFFFFB870),
        habitSleep: Color(0xFFB7A3FF),
        habitRun: Color(0xFF6BE7B4),
        habitLift: Color(0xFFDBA46A),
        habitDefault: Color(0xFFC7D5D4),
      ),
    );
  }

  static ThemeData emberTheme() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF8A3D),
      onPrimary: Color(0xFF2A1105),
      primaryContainer: Color(0xFF5C2A10),
      onPrimaryContainer: Color(0xFFFFD8B8),
      secondary: Color(0xFFFFB36B),
      onSecondary: Color(0xFF2E1A0C),
      secondaryContainer: Color(0xFF5A3B22),
      onSecondaryContainer: Color(0xFFFFE4CD),
      tertiary: Color(0xFFFFD1A1),
      onTertiary: Color(0xFF2B1A0E),
      tertiaryContainer: Color(0xFF5A3B22),
      onTertiaryContainer: Color(0xFFFFE4CD),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF2B0A0A),
      errorContainer: Color(0xFF5C1E1E),
      onErrorContainer: Color(0xFFFFDADA),
      surface: Color(0xFF0E0B0A),
      onSurface: Color(0xFFF5EFEA),
      surfaceContainerHigh: Color(0xFF1A1412),
      surfaceContainerHighest: Color(0xFF221A17),
      onSurfaceVariant: Color(0xFFB8AFA6),
      outline: Color(0xFF2C2420),
      shadow: Color(0x66000000),
      inverseSurface: Color(0xFFF5EFEA),
      onInverseSurface: Color(0xFF0E0B0A),
      inversePrimary: Color(0xFFFF8A3D),
      surfaceTint: Color(0xFFFF8A3D),
    );

    return _buildTheme(
      scheme,
      const GameTokens(
        xpBadgeBg: Color(0xFF2A1B14),
        xpBadgeText: Color(0xFFFFC38A),
        urgentDot: Color(0xFFFF8A3D),
        urgentText: Color(0xFFFFC38A),
        habitWater: Color(0xFF7CC6FF),
        habitRead: Color(0xFFFFC38A),
        habitSleep: Color(0xFFC4B5FF),
        habitRun: Color(0xFF7EE2B8),
        habitLift: Color(0xFFE0A97A),
        habitDefault: Color(0xFFF5EFEA),
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme scheme, GameTokens tokens) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: scheme.shadow.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        shadowColor: scheme.shadow.withValues(alpha: 0.35),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.3),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outline),
            ),
          ),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: WidgetStatePropertyAll(scheme.shadow),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 12,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: scheme.shadow.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
      ),
      extensions: [tokens],
    );
  }
}

class ThemeOption {
  const ThemeOption({required this.id, required this.label});
  final String id;
  final String label;
}

class GameTokens extends ThemeExtension<GameTokens> {
  const GameTokens({
    required this.xpBadgeBg,
    required this.xpBadgeText,
    required this.urgentDot,
    required this.urgentText,
    required this.habitWater,
    required this.habitRead,
    required this.habitSleep,
    required this.habitRun,
    required this.habitLift,
    required this.habitDefault,
  });

  final Color xpBadgeBg;
  final Color xpBadgeText;
  final Color urgentDot;
  final Color urgentText;
  final Color habitWater;
  final Color habitRead;
  final Color habitSleep;
  final Color habitRun;
  final Color habitLift;
  final Color habitDefault;

  @override
  GameTokens copyWith({
    Color? xpBadgeBg,
    Color? xpBadgeText,
    Color? urgentDot,
    Color? urgentText,
    Color? habitWater,
    Color? habitRead,
    Color? habitSleep,
    Color? habitRun,
    Color? habitLift,
    Color? habitDefault,
  }) {
    return GameTokens(
      xpBadgeBg: xpBadgeBg ?? this.xpBadgeBg,
      xpBadgeText: xpBadgeText ?? this.xpBadgeText,
      urgentDot: urgentDot ?? this.urgentDot,
      urgentText: urgentText ?? this.urgentText,
      habitWater: habitWater ?? this.habitWater,
      habitRead: habitRead ?? this.habitRead,
      habitSleep: habitSleep ?? this.habitSleep,
      habitRun: habitRun ?? this.habitRun,
      habitLift: habitLift ?? this.habitLift,
      habitDefault: habitDefault ?? this.habitDefault,
    );
  }

  @override
  GameTokens lerp(ThemeExtension<GameTokens>? other, double t) {
    if (other is! GameTokens) return this;
    return GameTokens(
      xpBadgeBg: Color.lerp(xpBadgeBg, other.xpBadgeBg, t)!,
      xpBadgeText: Color.lerp(xpBadgeText, other.xpBadgeText, t)!,
      urgentDot: Color.lerp(urgentDot, other.urgentDot, t)!,
      urgentText: Color.lerp(urgentText, other.urgentText, t)!,
      habitWater: Color.lerp(habitWater, other.habitWater, t)!,
      habitRead: Color.lerp(habitRead, other.habitRead, t)!,
      habitSleep: Color.lerp(habitSleep, other.habitSleep, t)!,
      habitRun: Color.lerp(habitRun, other.habitRun, t)!,
      habitLift: Color.lerp(habitLift, other.habitLift, t)!,
      habitDefault: Color.lerp(habitDefault, other.habitDefault, t)!,
    );
  }
}
