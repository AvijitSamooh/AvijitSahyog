import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6E1A14);
  static const Color primaryDark = Color(0xFF4C120D);
  static const Color secondary = Color(0xFFF5A623);
  static const Color background = Color(0xFFFFF8ED);
  static const Color surface = Colors.white;
  static const Color softSurface = Color(0xFFFCE8C9);
  static const Color textPrimary = Color(0xFF39271C);
  static const Color textSecondary = Color(0xFF6B4F36);
  static const Color divider = Color(0xFFE8DCC8);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: primaryDark,
      surface: surface,
      onSurface: textPrimary,
      outline: divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamilyFallback: const ['Noto Sans Devanagari', 'Noto Sans Gujarati', 'Noto Sans', 'Roboto'],
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary)),
      dividerTheme: const DividerThemeData(color: divider, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: softSurface,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 15, height: 1.35, color: textPrimary),
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        titleLarge: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.55),
      ),
    );
  }
}
