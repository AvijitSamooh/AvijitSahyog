import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  test('organisation editor strings are translated for every supported locale', () async {
    final expectations = <String, Map<String, String>>{
      'en': {
        'edit': 'Edit organisation',
        'website': 'Website',
        'supportedCauses': 'Supported causes',
        'translations': 'Translations',
        'save': 'Save changes',
      },
      'hi': {
        'edit': 'संस्था संपादित करें',
        'website': 'वेबसाइट',
        'supportedCauses': 'समर्थित सेवा क्षेत्र',
        'translations': 'अनुवाद',
        'save': 'परिवर्तन सहेजें',
      },
      'mr': {
        'edit': 'संस्था संपादित करा',
        'website': 'वेबसाइट',
        'supportedCauses': 'समर्थित सेवा क्षेत्रे',
        'translations': 'भाषांतर',
        'save': 'बदल जतन करा',
      },
      'gu': {
        'edit': 'સંસ્થા સંપાદિત કરો',
        'website': 'વેબસાઇટ',
        'supportedCauses': 'સમર્થિત સેવા ક્ષેત્રો',
        'translations': 'અનુવાદ',
        'save': 'ફેરફારો સાચવો',
      },
    };

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final expected = expectations[locale.languageCode]!;

      expect(l10n.adminEditOrganisation, expected['edit']);
      expect(l10n.adminOrganisationWebsite, expected['website']);
      expect(l10n.adminSupportedCauses, expected['supportedCauses']);
      expect(l10n.adminTranslations, expected['translations']);
      expect(l10n.adminSaveChanges, expected['save']);
      expect(l10n.adminOrganisationEmail, isNotEmpty);
      expect(l10n.adminOrganisationAddress, isNotEmpty);
      expect(l10n.adminOrganisationCity, isNotEmpty);
      expect(l10n.adminOrganisationState, isNotEmpty);
      expect(l10n.adminOrganisationCountry, isNotEmpty);
      expect(l10n.adminOrganisationDisplayOrder, isNotEmpty);
      expect(l10n.adminOrganisationImages, isNotEmpty);
      expect(l10n.adminTranslationName, isNotEmpty);
      expect(l10n.adminTranslationDescription, isNotEmpty);
      expect(l10n.adminOrganisationSaving, isNotEmpty);
      expect(l10n.adminAddAtLeastOneTranslation, isNotEmpty);
      expect(l10n.adminOrganisationCreatedPartialFailure('error'), isNotEmpty);
      expect(l10n.adminOrganisationSaveFailed('error'), isNotEmpty);
      expect(l10n.adminOrganisationLoadCausesFailed, isNotEmpty);
    }
  });
}
