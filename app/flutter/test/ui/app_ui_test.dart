import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:avijit_sahyog/app.dart';
import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/causes/models/cause.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';
import 'package:avijit_sahyog/features/causes/presentation/causes_page.dart';
import 'package:avijit_sahyog/features/causes/presentation/cause_detail_page.dart';
import 'package:avijit_sahyog/features/causes/providers/causes_providers.dart';
import 'package:avijit_sahyog/features/donations/data/donations_repository.dart';
import 'package:avijit_sahyog/features/donations/models/create_donation.dart';
import 'package:avijit_sahyog/features/donations/presentation/donation_page.dart';
import 'package:avijit_sahyog/features/donations/providers/donation_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

const _organisation = Organisation(
  id: 'org-1',
  slug: 'seva-trust',
  name: 'Seva Trust',
  description: 'A sample organisation used by the UI tests.',
  city: 'Pune',
  state: 'Maharashtra',
);

const _organisationTwo = Organisation(
  id: 'org-2',
  slug: 'shiksha-trust',
  name: 'Shiksha Trust',
  description: 'A second sample organisation used by allocation tests.',
  city: 'Mumbai',
  state: 'Maharashtra',
);

const _organisations = [_organisation, _organisationTwo];

const _cause = Cause(
  id: 'cause-1',
  slug: 'education',
  name: 'Education',
  description: 'Support education initiatives.',
  organisations: _organisations,
);

class _FakeDonationsRepository extends DonationsRepository {
  _FakeDonationsRepository() : super(ApiClient());

  CreateDonation? lastDonation;

  @override
  Future<Map<String, dynamic>> createDonation(CreateDonation input) async {
    lastDonation = input;
    return {'id': 'donation-1', 'status': 'PENDING'};
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Widget? home,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: ThemeData(useMaterial3: true),
          home: home ?? const AvijitSahyogApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> pumpDonationPage(WidgetTester tester, {List<Override> overrides = const []}) async {
    await pumpApp(
      tester,
      home: const DonationPage(
        initialCauseId: 'cause-1',
        initialCauseName: 'Education',
      ),
      overrides: overrides,
    );

    expect(find.byType(DonationPage), findsOneWidget);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.scrollUntilVisible(
      amountField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(amountField, findsOneWidget);
  }


  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterVisibleText(
    WidgetTester tester,
    Finder finder,
    String value,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(finder, findsOneWidget);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }


  testWidgets('home page renders the cause-centric entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    expect(find.text('Welcome to Avijit Sahyog'), findsOneWidget);
    expect(find.text('Explore Causes'), findsWidgets);
    expect(find.text('See Our Impact'), findsOneWidget);
  });


  testWidgets('home hero loads Maharaj Ji image asset', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('impact navigation opens the real impact explorer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pumpAndSettle();
    final impactButton = find.text('See Our Impact');
    await tester.ensureVisible(impactButton);
    await tester.tap(impactButton);
    await tester.pumpAndSettle();
    expect(find.text('Our Impact'), findsOneWidget);
    expect(find.text('Search by name'), findsOneWidget);
  });

  testWidgets('language selector opens and shows all supported languages', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Marathi'), findsOneWidget);
    expect(find.text('Gujarati'), findsOneWidget);
  });

  testWidgets('language selector changes the app locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hindi'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('selected_locale'), 'hi');
  });

  testWidgets('causes page displays mocked causes', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    expect(find.text('Education'), findsWidgets);
    expect(find.text('Support education initiatives.'), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);
  });

  testWidgets('selecting a cause opens cause details', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    await tester.tap(find.text('Education').first);
    await tester.pumpAndSettle();

    expect(find.byType(CauseDetailPage), findsOneWidget);
    expect(find.text('Support education initiatives.'), findsWidgets);
    expect(find.text('Seva Trust'), findsOneWidget);
  });

  testWidgets('cause details display organisation and location', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
    expect(find.text('Support this Cause'), findsOneWidget);
  });

  testWidgets('support cause button opens donation page', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    await tapVisible(tester, find.text('Support this Cause'));

    expect(find.byType(DonationPage), findsOneWidget);
    expect(find.text(l10n(tester).chooseAmount), findsOneWidget);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.scrollUntilVisible(
      amountField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(amountField, findsOneWidget);
  });

  testWidgets('donation submit is disabled until an amount is selected', (tester) async {
    await pumpDonationPage(tester);

    final submitFinder = find.byKey(const ValueKey('donation_submit'));
    await tester.scrollUntilVisible(submitFinder, 400, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);
  });

  testWidgets('preset amount enables cause donation', (tester) async {
    await pumpDonationPage(tester);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_500')));
    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    expect(tester.widget<TextField>(amountField).controller?.text, '500');

    final submitFinder = find.byKey(const ValueKey('donation_submit'));
    await tester.scrollUntilVisible(submitFinder, 400, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);
  });

  testWidgets('custom donation amount enables cause donation', (tester) async {
    await pumpDonationPage(tester);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await enterVisibleText(tester, amountField, '1750');
    expect(tester.widget<TextField>(amountField).controller?.text, '1750');

    expect(find.text(l10n(tester).shareAcrossCauses), findsOneWidget);
  });

  testWidgets('invalid donation amount keeps submit disabled', (tester) async {
    await pumpDonationPage(tester);
    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await enterVisibleText(tester, amountField, '0');

    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('donation_submit')),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('valid cause donation is submitted without organisation allocations', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));

    final submit = find.byKey(const ValueKey('donation_submit'));
    await tester.scrollUntilVisible(
      submit,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.lastDonation, isNotNull);
    expect(repository.lastDonation!.amount, '1000.00');
    expect(repository.lastDonation!.allocations, hasLength(1));
    expect(repository.lastDonation!.allocations.single.causeId, 'cause-1');
    expect(repository.lastDonation!.allocations.single.amount, '1000.00');
    expect(find.text(l10n(tester).donationCreatedTitle), findsOneWidget);
  });
}
