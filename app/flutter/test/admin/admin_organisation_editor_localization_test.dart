import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/features/admin/presentation/admin_organisation_editor_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_causes_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  testWidgets('organisation editor uses the active locale for user-visible labels', (tester) async {
    const locales = [
      (
        Locale('en'),
        'Edit organisation',
        'Website',
        'Supported causes',
        'Translations',
        'Save changes',
      ),
      (
        Locale('hi'),
        'संस्था संपादित करें',
        'वेबसाइट',
        'समर्थित सेवा क्षेत्र',
        'अनुवाद',
        'परिवर्तन सहेजें',
      ),
      (
        Locale('mr'),
        'संस्था संपादित करा',
        'वेबसाइट',
        'समर्थित सेवा क्षेत्रे',
        'भाषांतर',
        'बदल जतन करा',
      ),
      (
        Locale('gu'),
        'સંસ્થા સંપાદિત કરો',
        'વેબસાઇટ',
        'સમર્થિત સેવા ક્ષેત્રો',
        'અનુવાદ',
        'ફેરફારો સાચવો',
      ),
    ];

    for (final item in locales) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminCausesProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: item.$1,
            home: const AdminOrganisationEditorPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(item.$2), findsOneWidget);
      expect(find.text(item.$3), findsOneWidget);
      expect(find.text(item.$4), findsOneWidget);
      expect(find.text(item.$5), findsOneWidget);
      expect(find.text(item.$6), findsOneWidget);
    }
  });
}
