import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'l10n/app_localizations.dart';

class AvijitSahyogApp extends StatelessWidget {
  const AvijitSahyogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
