import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  test('all supported locales contain translated navigation and admin labels', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final localizations = lookupAppLocalizations(locale);
      expect(localizations.navHome, isNotEmpty);
      expect(localizations.navCauses, isNotEmpty);
      expect(localizations.navImpact, isNotEmpty);
      expect(localizations.language, isNotEmpty);
      expect(localizations.adminPortal, isNotEmpty);
      expect(localizations.adminCreateCause, isNotEmpty);
      expect(localizations.adminNoBeneficiaries, isNotEmpty);
      expect(localizations.adminInteractionAnalyticsTitle, isNotEmpty);
      expect(localizations.adminPlatformHealthTitle, isNotEmpty);
    }
  });
}
