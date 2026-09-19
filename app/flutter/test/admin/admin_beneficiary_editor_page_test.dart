import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avijit_sahyog/features/admin/models/admin_cause.dart';
import 'package:avijit_sahyog/features/admin/models/admin_organisation.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_beneficiary_editor_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_beneficiaries_providers.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_causes_providers.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_organisations_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

void main() {
  const hindiEducation = AdminCauseTranslation(
    languageCode: 'hi',
    name: 'शिक्षा सहायता',
  );
  const englishEducation = AdminCauseTranslation(
    languageCode: 'en',
    name: 'Education Assistance',
  );
  const hindiOrganisation = AdminOrganisationTranslation(
    languageCode: 'hi',
    name: 'डेमो शिक्षा सहयोग संस्था',
  );
  const englishOrganisation = AdminOrganisationTranslation(
    languageCode: 'en',
    name: 'Demo Education Support Organisation',
  );

  testWidgets('beneficiary editor localizes Hindi labels and option names', (tester) async {
    final education = AdminCause(
      id: 'cause-education',
      slug: 'education',
      isActive: true,
      displayOrder: 1,
      translations: const [englishEducation, hindiEducation],
    );
    final educationAssistance = AdminCause(
      id: 'cause-education-assistance',
      slug: 'education-assistance',
      isActive: true,
      displayOrder: 1,
      parentId: 'cause-education',
      translations: const [englishEducation, hindiEducation],
    );
    final duplicateRootChild = AdminCause(
      id: 'duplicate-root-child',
      slug: 'education-assistance',
      isActive: true,
      displayOrder: 2,
      translations: const [englishEducation, hindiEducation],
    );
    final organisation = AdminOrganisation(
      id: 'organisation-1',
      slug: 'demo-education-support',
      isActive: true,
      displayOrder: 1,
      translations: const [englishOrganisation, hindiOrganisation],
      causeIds: const ['cause-education-assistance'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCausesProvider.overrideWith((ref) async => [
                education,
                educationAssistance,
                duplicateRootChild,
              ]),
          adminOrganisationsProvider.overrideWith((ref) async => [organisation]),
          adminBeneficiariesRepositoryProvider.overrideWith((ref) {
            throw StateError('save should not be called');
          }),
        ],
        child: MaterialApp(
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminBeneficiaryEditorPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('लाभार्थी बनाएँ'), findsNWidgets(2));
    expect(find.text('नाम'), findsOneWidget);
    expect(find.text('प्रभाव की कहानी'), findsOneWidget);
    expect(find.text('समर्थित वर्ष'), findsOneWidget);
    expect(find.text('योगदान राशि'), findsOneWidget);
    expect(find.text('प्रदर्शन क्रम'), findsOneWidget);
    expect(find.text('कारण'), findsOneWidget);
    expect(find.text('लाभार्थी की तस्वीरें'), findsOneWidget);
    expect(find.text('संस्था (वैकल्पिक)'), findsOneWidget);
    expect(find.text('कोई संस्था नहीं'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin_beneficiary_cause')));
    await tester.pumpAndSettle();

    expect(find.text('शिक्षा सहायता'), findsNWidgets(2));
    expect(find.text('Education Assistance'), findsNothing);
  });
}
