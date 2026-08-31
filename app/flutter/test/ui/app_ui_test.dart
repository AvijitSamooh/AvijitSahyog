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

  Future<void> pumpDonationPage(
    WidgetTester tester, {
    List<Cause> causes = const [_cause],
    List<Override> overrides = const [],
  }) async {
    await pumpApp(
      tester,
      home: const DonationPage(initialCauseId: 'cause-1'),
      overrides: [
        causesProvider('en').overrideWith((ref) async => causes),
        ...overrides,
      ],
    );
    expect(find.byType(DonationPage), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> enterVisibleText(
    WidgetTester tester,
    Finder finder,
    String value,
  ) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.enterText(finder, value);
    await tester.pump();
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
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    await tapVisible(tester, find.text('Support this Cause'));
    await tester.pumpAndSettle();

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

  testWidgets('donation defaults a single selected cause to 100 percent', (tester) async {
    await pumpDonationPage(tester);
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('donation_percentage_cause-1')),
    );
    expect(field.initialValue, '100');
  });

  testWidgets('selecting a second cause defaults allocation equally', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('donation_cause_cause-2')),
    );

    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-1')),
      ).initialValue,
      '50',
    );
    expect(
      tester.widget<TextFormField>(
        find.byKey(const ValueKey('donation_percentage_cause-2')),
      ).initialValue,
      '50',
    );
    expect(find.text('Total allocation: 100%'), findsOneWidget);
  });

  testWidgets('three selected causes default to a complete 100 percent split', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
      Cause(id: 'cause-3', slug: 'medical', name: 'Medical'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-3')));

    expect(find.text('Total allocation: 100%'), findsOneWidget);
  });

  testWidgets('donor can override equal percentages and submit exact allocations', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      causes: causes,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-1')),
      '70',
    );
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-2')),
      '30',
    );

    expect(find.text('Total allocation: 100%'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('donation_submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.lastDonation, isNotNull);
    expect(repository.lastDonation!.amount, '1000.00');
    expect(repository.lastDonation!.allocations, hasLength(2));
    expect(repository.lastDonation!.allocations[0].amount, '700.00');
    expect(repository.lastDonation!.allocations[1].amount, '300.00');
  });

  testWidgets('donation submit is disabled when allocation does not total 100 percent', (tester) async {
    const causes = [
      _cause,
      Cause(id: 'cause-2', slug: 'jeev-daya', name: 'Jeev Daya'),
    ];
    await pumpDonationPage(tester, causes: causes);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));
    await tapVisible(tester, find.byKey(const ValueKey('donation_cause_cause-2')));
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-1')),
      '70',
    );
    await enterVisibleText(
      tester,
      find.byKey(const ValueKey('donation_percentage_cause-2')),
      '20',
    );

    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('donation_submit')),
    );
    expect(submit.onPressed, isNull);
    expect(find.text('Total allocation: 90%'), findsOneWidget);
  });

  testWidgets('preset amount updates donation amount field', (tester) async {
    await pumpDonationPage(tester);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_500')));

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('donation_amount_input')),
          )
          .controller
          ?.text,
      '500',
    );
  });


}
