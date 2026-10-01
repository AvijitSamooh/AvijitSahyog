import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/settings/settings_page.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  testWidgets('language selection stays compact and shows current locale', (tester) async {
    Locale? selected;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          showAppBar: false,
          onLocaleChanged: (locale) => selected = locale,
        ),
      ),
    );

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Marathi'), findsOneWidget);
    expect(find.text('Gujarati'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);

    await tester.tap(find.text('Hindi'));
    expect(selected, const Locale('hi'));
  });
}
