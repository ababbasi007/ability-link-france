import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return _withText(base, AppColors.textPrimary).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
    );
    return _withText(base, Colors.white).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  /// WCAG AAA-oriented yellow-on-black palette for low vision.
  static ThemeData get highContrast {
    const yellow = Color(0xFFFFF59D);
    const bg = Color(0xFF000000);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: yellow,
        onPrimary: bg,
        surface: bg,
        onSurface: yellow,
        error: Color(0xFFFF6B6B),
      ),
      scaffoldBackgroundColor: bg,
    );
    return _withText(base, yellow).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: yellow,
        elevation: 0,
        centerTitle: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(yellow),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? yellow.withValues(alpha: 0.5)
              : const Color(0xFF333333),
        ),
      ),
    );
  }

  static ThemeData forPrefs({
    required bool darkMode,
    required bool highContrast,
  }) {
    if (highContrast) return AppTheme.highContrast;
    if (darkMode) return AppTheme.dark;
    return AppTheme.light;
  }

  static ThemeData _withText(ThemeData base, Color color) {
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: color, displayColor: color),
    );
  }
}
