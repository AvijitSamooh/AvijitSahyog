import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  test('cause detail strings are translated for every supported locale', () async {
    final expected = <String, Map<String, String>>{
      'en': {
        'title': 'Cause Details',
        'support': 'Support this Cause',
        'reach': 'How your contribution reaches people',
      },
      'hi': {
        'title': 'सेवा क्षेत्र विवरण',
        'support': 'इस सेवा क्षेत्र का समर्थन करें',
        'reach': 'आपका योगदान लोगों तक कैसे पहुँचता है',
      },
      'mr': {
        'title': 'सेवा क्षेत्राचे तपशील',
        'support': 'या सेवा क्षेत्राला पाठिंबा द्या',
        'reach': 'तुमचे योगदान लोकांपर्यंत कसे पोहोचते',
      },
      'gu': {
        'title': 'સેવા ક્ષેત્રની વિગતો',
        'support': 'આ સેવા ક્ષેત્રને ટેકો આપો',
        'reach': 'તમારું યોગદાન લોકો સુધી કેવી રીતે પહોંચે છે',
      },
    };

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final values = expected[locale.languageCode]!;

      expect(l10n.causeDetailsTitle, values['title']);
      expect(l10n.supportThisCause, values['support']);
      expect(l10n.causeReachTitle, values['reach']);
      expect(l10n.causeReachDescription, isNotEmpty);
      expect(l10n.causeLoadError, isNotEmpty);
      expect(l10n.retry, isNotEmpty);
    }
  });
}
