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
          theme: ThemeData(useMaterial3: true),
          home: home ?? const AvijitSahyogApp(),
        ),
      ),
    );
    await tester.pump();
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
    expect(find.text('सेवा के क्षेत्र'), findsWidgets);
  });

  testWidgets('causes page displays mocked causes', (tester) async {
    await pumpApp(
      tester,
      home: const CausesPage(),
      overrides: [
        causesProvider('en').overrideWith((ref) async => const [_cause]),
      ],
    );

    await tester.pumpAndSettle();

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

    await tester.pumpAndSettle();
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

    await tester.pumpAndSettle();

    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text('Pune, Maharashtra'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Donate now'), findsOneWidget);
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

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Donate now'));
    await tester.pumpAndSettle();

    expect(find.byType(DonationPage), findsOneWidget);
    expect(find.text('Seva Trust'), findsOneWidget);
    expect(find.text('Choose amount'), findsOneWidget);
  });

  testWidgets('preset donation amount can be selected', (tester) async {
    await pumpApp(
      tester,
      home: const DonationPage(
        causeId: 'cause-1',
        causeName: 'Education',
        organisation: _organisation,
      ),
    );

    final preset = find.widgetWithText(OutlinedButton, '₹ 500');
    expect(preset, findsOneWidget);

    await tester.tap(preset);
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, '₹ 500'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('custom donation amount can be entered', (tester) async {
    await pumpApp(
      tester,
      home: const DonationPage(
        causeId: 'cause-1',
        causeName: 'Education',
        organisation: _organisation,
      ),
    );

    final amountField = find.byType(TextField);
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '1750');
    await tester.pump();

    expect(find.text('1750'), findsOneWidget);
  });

  testWidgets('invalid donation amount is rejected', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpApp(
      tester,
      home: const DonationPage(
        causeId: 'cause-1',
        causeName: 'Education',
        organisation: _organisation,
      ),
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Donate now'));
    await tester.pump();

    expect(find.text('Please enter a valid donation amount.'), findsOneWidget);
    expect(repository.lastDonation, isNull);
  });

  testWidgets('valid donation is submitted and confirmation is shown', (tester) async {
    final repository = _FakeDonationsRepository();
    await pumpApp(
      tester,
      home: const DonationPage(
        causeId: 'cause-1',
        causeName: 'Education',
        organisation: _organisation,
      ),
      overrides: [donationRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(find.byType(TextField), '1500');
    await tester.tap(find.widgetWithText(FilledButton, 'Donate now'));
    await tester.pumpAndSettle();

    expect(repository.lastDonation, isNotNull);
    expect(repository.lastDonation!.amount, '1500');
    expect(repository.lastDonation!.causeId, 'cause-1');
    expect(repository.lastDonation!.organisationId, 'org-1');
    expect(find.text('Donation created'), findsOneWidget);
  });
}
