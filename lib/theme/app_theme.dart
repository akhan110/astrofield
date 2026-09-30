import 'package:flutter/material.dart';

class AppColors {
  // AstroField Night UI Exact Palette
  static const Color background = Color(0xFF050A16); // Space Black
  static const Color midnightNavy = Color(0xFF081125); // Midnight Navy
  static const Color surface = Color(0xFF0E1830); // Deep Surface
  static const Color surface2 = Color(0xFF172342); // Raised Surface
  static const Color surface3 = Color(0xFF1F2E52);
  static const Color border = Color(0xFF364568); // Border Blue
  static const Color primary = Color(0xFF5A58D7); // Primary Indigo
  static const Color electricBlue = Color(0xFF344BCD); // Electric Blue
  static const Color violet = Color(0xFF7A55F7); // Nebula Violet
  static const Color secondary = Color(0xFF6C8FD7); // Moonlight Blue
  static const Color textPrimary = Color(0xFFF4F6FF); // Text Primary
  static const Color textSecondary = Color(0xFFB5C8E5); // Text Secondary
  static const Color textMuted = Color(0xFF7886A0); // Text Muted

  // Accents & Indicators
  static const Color amber = Color(0xFFFFC96B);
  static const Color danger = Color(0xFFFF7D8D);
  static const Color success = Color(0xFF6FE1A5);
}

class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0xFF243258),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
