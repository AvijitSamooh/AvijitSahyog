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
        causeId: 'cause-1',
        causeName: 'Education',
        organisation: _organisation,
        organisations: _organisations,
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

  testWidgets('language selector opens and shows all supported languages', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिंदी'), findsOneWidget);
    expect(find.text('मराठी'), findsOneWidget);
    expect(find.text('ગુજરાતી'), findsOneWidget);
  });

  testWidgets('language selector changes the app locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिंदी'));
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
    expect(find.byKey(const ValueKey('cause_organisation_donate_org-1')), findsOneWidget);
  });

  testWidgets('organisation pay button opens donation page', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    await tapVisible(tester, find.byKey(const ValueKey('cause_organisation_donate_org-1')));

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

  testWidgets('allocation is hidden until a total amount is selected', (tester) async {
    await pumpDonationPage(tester);

    expect(find.text('वितरण'), findsNothing);
    expect(find.byKey(const ValueKey('donation_submit')), findsNothing);
    expect(find.byKey(const ValueKey('donation_allocation_org-1')), findsNothing);
  });

  testWidgets('preset amount selects total and preselects originating organisation', (tester) async {
    await pumpDonationPage(tester);

    final preset = find.byKey(const ValueKey('donation_amount_500'));
    await tapVisible(tester, preset);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    expect(tester.widget<TextField>(amountField).controller?.text, '500');

    final firstAllocation = find.byKey(const ValueKey('donation_allocation_org-1'));
    await tester.scrollUntilVisible(
      firstAllocation,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(firstAllocation, findsOneWidget);
    expect(tester.widget<TextField>(firstAllocation).controller?.text, '500');

    final secondAllocation = find.byKey(const ValueKey('donation_allocation_org-2'));
    await tester.scrollUntilVisible(
      secondAllocation,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(secondAllocation, findsOneWidget);
    expect(tester.widget<TextField>(secondAllocation).controller?.text, '0');
  });

  testWidgets('custom donation amount can be entered and allocation appears', (tester) async {
    await pumpDonationPage(tester);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await enterVisibleText(tester, amountField, '1750');

    expect(tester.widget<TextField>(amountField).controller?.text, '1750');

    final firstAllocation = find.byKey(
      const ValueKey('donation_allocation_org-1'),
    );
    await tester.scrollUntilVisible(
      firstAllocation,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(firstAllocation, findsOneWidget);
    expect(
      tester.widget<TextField>(firstAllocation).controller?.text,
      '1750',
    );
  });

  testWidgets('allocation can be redistributed between organisations', (tester) async {
    await pumpDonationPage(tester);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));

    final first = find.byKey(const ValueKey('donation_allocation_org-1'));
    final second = find.byKey(const ValueKey('donation_allocation_org-2'));

    await enterVisibleText(tester, first, '700');
    await enterVisibleText(tester, second, '300');

    expect(tester.widget<TextField>(first).controller?.text, '700');
    expect(tester.widget<TextField>(second).controller?.text, '300');
    expect(find.byKey(const ValueKey('donation_submit')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('donation_submit'))).onPressed, isNotNull);
  });

  testWidgets('allocation cannot exceed selected total', (tester) async {
    await pumpDonationPage(tester);

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_500')));

    final first = find.byKey(const ValueKey('donation_allocation_org-1'));
    final second = find.byKey(const ValueKey('donation_allocation_org-2'));

    await enterVisibleText(tester, first, '400');
    await enterVisibleText(tester, second, '300');

    expect(tester.widget<TextField>(first).controller?.text, '400');
    expect(tester.widget<TextField>(second).controller?.text, '100');
  });

  testWidgets('invalid donation amount is rejected', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await enterVisibleText(tester, amountField, '0');

    expect(find.byKey(const ValueKey('donation_submit')), findsNothing);
    expect(repository.lastDonation, isNull);
  });

  testWidgets('valid distributed donation is submitted with all allocations', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    await tapVisible(tester, find.byKey(const ValueKey('donation_amount_1000')));

    final first = find.byKey(const ValueKey('donation_allocation_org-1'));
    final second = find.byKey(const ValueKey('donation_allocation_org-2'));
    await enterVisibleText(tester, first, '700');
    await enterVisibleText(tester, second, '300');

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
    expect(repository.lastDonation!.allocations, hasLength(2));
    expect(repository.lastDonation!.allocations[0].organisationId, 'org-1');
    expect(repository.lastDonation!.allocations[0].amount, '700.00');
    expect(repository.lastDonation!.allocations[1].organisationId, 'org-2');
    expect(repository.lastDonation!.allocations[1].amount, '300.00');
    expect(find.text(l10n(tester).donationCreatedTitle), findsOneWidget);
  });
}
