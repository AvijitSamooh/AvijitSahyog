import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'l10n/app_localizations.dart';

class AvijitSahyogApp extends StatefulWidget {
  const AvijitSahyogApp({super.key});

  @override
  State<AvijitSahyogApp> createState() => _AvijitSahyogAppState();
}

class _AvijitSahyogAppState extends State<AvijitSahyogApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avijit Sahyog',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),

      locale: _locale,

      supportedLocales: AppLocalizations.supportedLocales,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: HomePage(
        onLocaleChanged: setLocale,
      ),
    );
  }
}