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

const _cause = Cause(
  id: 'cause-1',
  slug: 'education',
  name: 'Education',
  description: 'Support education initiatives.',
  organisations: [_organisation],
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
      ),
      overrides: overrides,
    );

    expect(find.byType(DonationPage), findsOneWidget);
    expect(find.byKey(const ValueKey('donation_submit')), findsOneWidget);

    // DonationPage uses a ListView. Widgets below the viewport are lazily
    // built, so make the amount field visible before asserting on it.
    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.scrollUntilVisible(
      amountField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(amountField, findsOneWidget);
  }

  testWidgets('home page renders the main donation entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AvijitSahyogApp()));
    await tester.pump();

    expect(find.byType(AvijitSahyogApp), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Causes'), findsOneWidget);
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

    expect(find.text('अविजित सहयोग में आपका स्वागत है'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('cause_organisation_donate')), findsOneWidget);
  });

  testWidgets('organisation donate button opens donation page', (tester) async {
    await pumpApp(
      tester,
      home: const CauseDetailPage(slug: 'education'),
      overrides: [
        causeProvider((slug: 'education', languageCode: 'en'))
            .overrideWith((ref) async => _cause),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('cause_organisation_donate')));
    await tester.pumpAndSettle();

    expect(find.byType(DonationPage), findsOneWidget);
    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text(l10n(tester).chooseAmount), findsOneWidget);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.scrollUntilVisible(
      amountField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(amountField, findsOneWidget);
  });

  testWidgets('preset donation amount can be selected', (tester) async {
    await pumpDonationPage(tester);

    final preset = find.byKey(const ValueKey('donation_amount_500'));
    await tester.scrollUntilVisible(
      preset,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(preset, findsOneWidget);

    await tester.tap(preset);
    await tester.pump();

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.scrollUntilVisible(
      amountField,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextField>(amountField).controller?.text, '500');
  });

  testWidgets('custom donation amount can be entered', (tester) async {
    await pumpDonationPage(tester);

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.enterText(amountField, '1750');
    await tester.pump();

    expect(tester.widget<TextField>(amountField).controller?.text, '1750');
  });

  testWidgets('invalid donation amount is rejected', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.enterText(amountField, '0');
    await tester.tap(find.byKey(const ValueKey('donation_submit')));
    await tester.pump();

    expect(find.text(l10n(tester).donationInvalidAmount), findsOneWidget);
    expect(repository.lastDonation, isNull);
  });

  testWidgets('valid donation is submitted and confirmation is shown', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpDonationPage(
      tester,
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    final amountField = find.byKey(const ValueKey('donation_amount_input'));
    await tester.enterText(amountField, '1500');
    await tester.tap(find.byKey(const ValueKey('donation_submit')));
    await tester.pumpAndSettle();

    expect(repository.lastDonation, isNotNull);
    expect(repository.lastDonation!.amount, '1500');
    expect(repository.lastDonation!.causeId, 'cause-1');
    expect(repository.lastDonation!.organisationId, 'org-1');
    expect(find.text(l10n(tester).donationCreatedTitle), findsOneWidget);
  });
}
