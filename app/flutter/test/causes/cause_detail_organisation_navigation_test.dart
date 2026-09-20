import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/features/causes/models/cause.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/cause_detail_page.dart';
import 'package:avijit_sahyog/features/causes/presentation/organisation_detail_page.dart';
import 'package:avijit_sahyog/features/causes/providers/causes_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

const _organisationWithoutGallery = Organisation(
  id: 'org-1',
  slug: 'seva-trust',
  name: 'Seva Trust',
  description: 'Serving the community.',
  city: 'Pune',
  state: 'Maharashtra',
);

const _organisationWithGallery = Organisation(
  id: 'org-2',
  slug: 'shiksha-trust',
  name: 'Shiksha Trust',
  description: 'Supporting education.',
  city: 'Mumbai',
  state: 'Maharashtra',
  gallery: ['https://images.example.com/one.webp'],
  mobileNumber: '+919876543210',
);

const _cause = Cause(
  id: 'cause-1',
  slug: 'education',
  name: 'Education',
  description: 'Support education initiatives.',
  organisations: [
    _organisationWithoutGallery,
    _organisationWithGallery,
  ],
);

void main() {
  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          causeProvider((slug: 'education', languageCode: 'en'))
              .overrideWith((ref) async => _cause),
        ],
        child: AppShellScope(
          onLocaleChanged: (_) {},
          navigation: AppNavigationController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: ThemeData(useMaterial3: true),
            home: const CauseDetailPage(slug: 'education'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens an affiliated organisation without gallery', (tester) async {
    await pumpSubject(tester);

    final organisationName = find.text('Seva Trust');
    await tester.scrollUntilVisible(
      organisationName,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(organisationName);
    await tester.pumpAndSettle();

    expect(find.byType(OrganisationDetailPage), findsOneWidget);
    expect(find.text('Seva Trust'), findsNWidgets(2));
    expect(find.text('Serving the community.'), findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.byKey(const ValueKey('affiliate_call_org-1')), findsNothing);
    expect(find.byKey(const ValueKey('affiliate_whatsapp_org-1')), findsNothing);
  });

  testWidgets('opens an affiliated organisation with gallery', (tester) async {
    await pumpSubject(tester);

    final organisationName = find.text('Shiksha Trust');
    await tester.scrollUntilVisible(
      organisationName,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('affiliate_call_org-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('affiliate_whatsapp_org-2')), findsOneWidget);

    await tester.tap(organisationName);
    await tester.pumpAndSettle();

    expect(find.byType(OrganisationDetailPage), findsOneWidget);
    expect(find.text('Shiksha Trust'), findsNWidgets(2));
    expect(find.byType(GridView), findsOneWidget);
  });
}
