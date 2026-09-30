import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/home/presentation/brand_splash_page.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BrandSplashPage(duration: Duration(seconds: 5),),
    );
  }

  testWidgets('shows Avijit branding and guru names', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Avijit Samuh'), findsOneWidget);
    expect(find.text('Avijit Sahyog'), findsOneWidget);
    expect(find.text('Acharya Shri Vidyasagar Ji Maharaj'), findsOneWidget);
    expect(find.text('Muni Shri Ajitsagar Ji Maharaj'), findsOneWidget);
  });
}
