import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_page.dart';
import 'features/impact/presentation/impact_page.dart';

import 'l10n/app_localizations.dart';

class AvijitSahyogApp extends StatefulWidget {
  const AvijitSahyogApp({super.key});

  @override
  State<AvijitSahyogApp> createState() => _AvijitSahyogAppState();
}

class _AvijitSahyogAppState extends State<AvijitSahyogApp> {
  static const _localeKey = 'selected_locale';

  static const _maroon = Color(0xFF6E1A14);
  static const _maroonDark = Color(0xFF4C120D);
  static const _saffron = Color(0xFFF5A623);
  static const _cream = Color(0xFFFFF8ED);
  static const _text = Color(0xFF39271C);
  static const _textSoft = Color(0xFF6B4F36);
  static const _line = Color(0xFFE8DCC8);

  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);
    if (!mounted || languageCode == null) return;

    final supportedCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    if (supportedCodes.contains(languageCode)) {
      setState(() => _locale = Locale(languageCode));
    }
  }

  Future<void> setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _maroon,
      brightness: Brightness.light,
    ).copyWith(
      primary: _maroon,
      onPrimary: Colors.white,
      secondary: _saffron,
      onSecondary: _maroonDark,
      surface: Colors.white,
      onSurface: _text,
      outline: _line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _cream,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: _cream,
        foregroundColor: _maroon,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _maroon,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _maroon,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _maroon),
      ),
      dividerTheme: const DividerThemeData(color: _line, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _maroon),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: _maroon,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: _maroon,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: _text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: _text, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: _textSoft, fontSize: 14, height: 1.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
      locale: _locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildTheme(),
      home: HomePage(onLocaleChanged: setLocale),
      routes: {
        '/impact': (_) => const ImpactPage(),
      },
      ),
    );
  }
}
