import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

describe('admin organisation localization', () {
  test('organisation management strings exist in every supported locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.adminCreateOrganisation, isNotEmpty);
      expect(l10n.adminOrganisationActions, isNotEmpty);
      expect(l10n.adminDeleteOrganisation, isNotEmpty);
      expect(l10n.adminDeleteOrganisationTitle, isNotEmpty);
      expect(l10n.adminDeleteOrganisationConfirmation('Test Organisation'), isNotEmpty);
      expect(l10n.adminDeleteOrganisationSuccess('Test Organisation'), isNotEmpty);
    }
  });
});
